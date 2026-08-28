<?php
/**
 * Word Builder PvP Challenge API.
 *
 * GET  ?status=active|all|pending|completed
 * GET  ?match_id=123
 * POST { "opponent_id": 42 }                         — create
 * POST { "action": "accept", "match_id": 123 }
 * POST { "action": "decline", "match_id": 123 }
 *
 * Authorization: Bearer (required)
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

if (!is_file(__DIR__ . '/pvp_challenge_helpers.php')) {
    http_response_code(503);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'error' => 'pvp_challenge_helpers.php missing on server — upload all PvP PHP files',
        'expected_path' => __DIR__ . '/pvp_challenge_helpers.php',
        'hint' => 'helpers must sit beside pvp_challenges.php (same folder as register.php)',
    ], JSON_UNESCAPED_UNICODE);
    exit;
}
require_once __DIR__ . '/pvp_challenge_helpers.php';

if (!function_exists('pvp_tables_ready')) {
    function pvp_tables_ready(PDO $db)
    {
        return pvp_table_exists($db, 'pvp_matches')
            && pvp_table_exists($db, 'pvp_match_players');
    }
}

auth_options_exit();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
if ($method !== 'GET' && $method !== 'POST') {
    auth_send_json(['error' => 'Method not allowed'], 405);
}

$token = auth_bearer_token();
if ($token === null || $token === '') {
    auth_send_json(['error' => 'Missing token'], 401);
}

try {
    $db = getDb();
    $user = auth_user_from_token($db, $token);
    if ($user === null) {
        auth_send_json(['error' => 'Invalid or expired token'], 401);
    }
    $uid = (int) $user['id'];

    if (!pvp_tables_ready($db)) {
        auth_send_json(['error' => 'pvp_matches tables missing — run pvp_challenge_schema.sql on MySQL'], 503);
    }

    pvp_expire_stale_matches($db);

    if ($method === 'GET') {
        $matchId = isset($_GET['match_id']) ? (int) $_GET['match_id'] : 0;
        if ($matchId > 0) {
            $stmt = $db->prepare('SELECT * FROM pvp_matches WHERE id = :id LIMIT 1');
            $stmt->execute([':id' => $matchId]);
            $match = $stmt->fetch(PDO::FETCH_ASSOC);
            if ($match === false) {
                auth_send_json(['error' => 'match_not_found'], 404);
            }
            pvp_assert_participant($match, $uid);
            auth_send_json(['match' => pvp_match_to_json($db, $match, $uid)]);
        }

        $status = isset($_GET['status']) ? trim((string) $_GET['status']) : 'active';
        $stmt = $db->prepare(
            "SELECT * FROM pvp_matches
             WHERE challenger_id = :uid OR opponent_id = :uid2
             ORDER BY created_at DESC
             LIMIT 100"
        );
        $stmt->execute([':uid' => $uid, ':uid2' => $uid]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

        $incomingPending = [];
        $myTurn = [];
        $waitingOpponent = [];
        $completedRecent = [];

        foreach ($rows as $row) {
            $card = pvp_match_summary_card($db, $row, $uid);
            $st = $row['status'];
            if ($st === 'pending' && (int) $row['opponent_id'] === $uid) {
                $incomingPending[] = $card;
                continue;
            }
            if ($st === 'accepted' && !empty($card['is_my_turn'])) {
                $myTurn[] = $card;
                continue;
            }
            if ($st === 'accepted' && empty($card['is_my_turn'])) {
                $waitingOpponent[] = $card;
                continue;
            }
            if ($st === 'completed' || $st === 'declined' || $st === 'expired') {
                if ($status === 'all' || $status === 'completed' || ($status === 'active' && $st === 'completed')) {
                    if ($st === 'completed') {
                        $completedRecent[] = $card;
                    }
                }
            }
            if ($status === 'pending' && $st === 'pending' && (int) $row['challenger_id'] === $uid) {
                $waitingOpponent[] = $card;
            }
        }

        auth_send_json([
            'incoming_pending' => $incomingPending,
            'my_turn' => $myTurn,
            'waiting_opponent' => $waitingOpponent,
            'completed_recent' => array_slice($completedRecent, 0, 20),
        ]);
    }

    $data = auth_json_body();

    if (isset($data['action'])) {
        $action = strtolower(trim((string) $data['action']));
        $matchId = isset($data['match_id']) ? (int) $data['match_id'] : 0;
        if ($matchId <= 0) {
            auth_send_json(['error' => 'match_id is required'], 400);
        }

        $stmt = $db->prepare('SELECT * FROM pvp_matches WHERE id = :id LIMIT 1');
        $stmt->execute([':id' => $matchId]);
        $match = $stmt->fetch(PDO::FETCH_ASSOC);
        if ($match === false) {
            auth_send_json(['error' => 'match_not_found'], 404);
        }

        if ($action === 'accept') {
            if ((int) $match['opponent_id'] !== $uid) {
                auth_send_json(['error' => 'forbidden'], 403);
            }
            if ($match['status'] !== 'pending') {
                auth_send_json(['error' => 'match_not_pending'], 409);
            }
            if (strtotime($match['expires_at']) !== false && strtotime($match['expires_at']) < time()) {
                $db->prepare("UPDATE pvp_matches SET status = 'expired' WHERE id = :id")
                    ->execute([':id' => $matchId]);
                auth_send_json(['error' => 'match_expired'], 410);
            }
            $exp = (new DateTimeImmutable('+' . PVP_CHALLENGE_PLAY_DAYS . ' days'))->format('Y-m-d H:i:s');
            $db->prepare(
                "UPDATE pvp_matches
                 SET status = 'accepted', accepted_at = NOW(), expires_at = :exp
                 WHERE id = :id AND status = 'pending'"
            )->execute([':exp' => $exp, ':id' => $matchId]);
            $stmt->execute([':id' => $matchId]);
            $match = $stmt->fetch(PDO::FETCH_ASSOC);
            auth_send_json(['match' => pvp_match_to_json($db, $match, $uid)]);
        }

        if ($action === 'decline') {
            if ((int) $match['opponent_id'] !== $uid) {
                auth_send_json(['error' => 'forbidden'], 403);
            }
            if ($match['status'] !== 'pending') {
                auth_send_json(['error' => 'match_not_pending'], 409);
            }
            $db->prepare("UPDATE pvp_matches SET status = 'declined' WHERE id = :id AND status = 'pending'")
                ->execute([':id' => $matchId]);
            $stmt->execute([':id' => $matchId]);
            $match = $stmt->fetch(PDO::FETCH_ASSOC);
            auth_send_json(['match' => pvp_match_to_json($db, $match, $uid)]);
        }

        auth_send_json(['error' => 'unknown action'], 400);
    }

    $opponentId = isset($data['opponent_id']) ? (int) $data['opponent_id'] : 0;
    if ($opponentId <= 0) {
        auth_send_json(['error' => 'invalid opponent_id'], 400);
    }
    if ($opponentId === $uid) {
        auth_send_json(['error' => 'cannot_challenge_self'], 400);
    }

    $stmt = $db->prepare('SELECT id FROM users WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $opponentId]);
    if ($stmt->fetch() === false) {
        auth_send_json(['error' => 'user_not_found'], 404);
    }

    $existing = pvp_has_active_match_between($db, $uid, $opponentId);
    if ($existing !== null) {
        auth_send_json(['error' => 'active_match_exists', 'match_id' => $existing], 409);
    }

    $expires = (new DateTimeImmutable('+' . PVP_CHALLENGE_PENDING_HOURS . ' hours'))->format('Y-m-d H:i:s');
    $categories = pvp_fetch_active_categories($db);
    if (count($categories) === 0) {
        auth_send_json(['error' => 'failed_to_generate_letters'], 500);
    }
    $placeholderCat = (int) $categories[0]['id'];

    $db->beginTransaction();
    try {
        $ins = $db->prepare(
            "INSERT INTO pvp_matches
             (challenger_id, opponent_id, category_id, letter_seed, anchor_words_json, letters_json,
              duration_sec, status, expires_at)
             VALUES (:cid, :opp, :cat, 0, '[]', '[]', 60, 'pending', :exp)"
        );
        $ins->execute([
            ':cid' => $uid,
            ':opp' => $opponentId,
            ':cat' => $placeholderCat,
            ':exp' => $expires,
        ]);
        $matchId = (int) $db->lastInsertId();

        $gen = pvp_generate_match_letters($db, $matchId);
        if ($gen === null) {
            $db->rollBack();
            auth_send_json(['error' => 'failed_to_generate_letters'], 500);
        }

        $lettersJson = json_encode($gen['letters'], JSON_UNESCAPED_UNICODE);
        $anchorJson = json_encode($gen['anchor_words'], JSON_UNESCAPED_UNICODE);

        $db->prepare(
            "UPDATE pvp_matches
             SET category_id = :cat, letter_seed = :seed,
                 anchor_words_json = :anchor, letters_json = :letters
             WHERE id = :id"
        )->execute([
            ':cat' => (int) $gen['category_id'],
            ':seed' => (int) $gen['letter_seed'],
            ':anchor' => $anchorJson,
            ':letters' => $lettersJson,
            ':id' => $matchId,
        ]);

        $pIns = $db->prepare(
            "INSERT INTO pvp_match_players (match_id, user_id, turn_order, player_status)
             VALUES (:mid, :uid, :ord, 'waiting')"
        );
        $pIns->execute([':mid' => $matchId, ':uid' => $uid, ':ord' => 1]);
        $pIns->execute([':mid' => $matchId, ':uid' => $opponentId, ':ord' => 2]);

        $db->commit();
    } catch (Exception $e) {
        $db->rollBack();
        throw $e;
    }

    $stmt = $db->prepare('SELECT * FROM pvp_matches WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $matchId]);
    $match = $stmt->fetch(PDO::FETCH_ASSOC);
    http_response_code(201);
    auth_send_json(['match' => pvp_match_to_json($db, $match, $uid)]);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Database error: ' . $e->getMessage()], 500);
} catch (Throwable $e) {
    auth_send_json(['error' => 'Server error: ' . $e->getMessage()], 500);
}
