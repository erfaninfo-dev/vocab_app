<?php
/**
 * POST /pvp_challenge_submit.php
 *
 * Authorization: Bearer (required)
 *
 * JSON body:
 * {
 *   "match_id": 152,
 *   "started_at": "2026-08-28T14:00:00Z",
 *   "completed_at": "2026-08-28T14:01:00Z",
 *   "words": ["cat", "tiger", "rate"]
 * }
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

if (!is_file(__DIR__ . '/pvp_challenge_helpers.php')) {
    http_response_code(503);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'error' => 'pvp_challenge_helpers.php missing on server — upload all PvP PHP files',
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
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    auth_send_json(['error' => 'Only POST is allowed'], 405);
}

$token = auth_bearer_token();
if ($token === null || $token === '') {
    auth_send_json(['error' => 'Missing token'], 401);
}

$data = auth_json_body();
$matchId = isset($data['match_id']) ? (int) $data['match_id'] : 0;
$rawWords = isset($data['words']) && is_array($data['words']) ? $data['words'] : [];
$startedAt = pvp_parse_iso_datetime(isset($data['started_at']) ? $data['started_at'] : '');
$completedAt = pvp_parse_iso_datetime(isset($data['completed_at']) ? $data['completed_at'] : '');

if ($matchId <= 0) {
    auth_send_json(['error' => 'match_id is required'], 400);
}
if ($startedAt === null || $completedAt === null) {
    auth_send_json(['error' => 'started_at and completed_at are required'], 400);
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

    $stmt = $db->prepare('SELECT * FROM pvp_matches WHERE id = :id LIMIT 1');
    $stmt->execute([':id' => $matchId]);
    $match = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($match === false) {
        auth_send_json(['error' => 'match_not_found'], 404);
    }

    pvp_assert_participant($match, $uid);

    if ($match['status'] === 'expired') {
        auth_send_json(['error' => 'match_expired'], 410);
    }
    if ($match['status'] !== 'accepted' && $match['status'] !== 'completed') {
        auth_send_json(['error' => 'match_not_playable'], 409);
    }

    $players = pvp_fetch_match_players($db, $matchId);
    $me = pvp_player_row_by_user($players, $uid);
    if ($me === null) {
        auth_send_json(['error' => 'forbidden'], 403);
    }

    if ($me['player_status'] === 'submitted') {
        $validation = [
            'valid_words' => pvp_parse_words_json($me['words_json']) ?? [],
            'invalid_words' => [],
            'duplicate_words' => [],
            'score' => (int) $me['score'],
        ];
        auth_send_json([
            'player' => [
                'user_id' => $uid,
                'score' => (int) $me['score'],
                'words' => $validation['valid_words'],
                'player_status' => 'submitted',
            ],
            'match' => pvp_match_to_json($db, $match, $uid),
            'validation' => $validation,
        ]);
    }

    $viewer = pvp_viewer_state($match, $players, $uid);
    if (empty($viewer['can_play'])) {
        $reason = isset($viewer['reason_if_blocked']) ? $viewer['reason_if_blocked'] : 'not_your_turn';
        auth_send_json(['error' => $reason], 409);
    }

    $durationSec = pvp_duration_seconds($startedAt, $completedAt);
    $maxDuration = (int) $match['duration_sec'] + PVP_CHALLENGE_DURATION_GRACE_SEC;
    if ($durationSec === null || $durationSec > $maxDuration) {
        auth_send_json(['error' => 'duration_exceeded'], 400);
    }

    $letters = json_decode($match['letters_json'], true);
    if (!is_array($letters)) {
        $letters = [];
    }

    $validation = pvp_validate_submitted_words(
        $db,
        (int) $match['category_id'],
        $letters,
        $rawWords
    );

    $wordsJson = json_encode($validation['valid_words'], JSON_UNESCAPED_UNICODE);

    $db->prepare(
        "UPDATE pvp_match_players
         SET player_status = 'submitted', score = :score, words_json = :words,
             started_at = :started, completed_at = :completed
         WHERE match_id = :mid AND user_id = :uid"
    )->execute([
        ':score' => (int) $validation['score'],
        ':words' => $wordsJson,
        ':started' => $startedAt,
        ':completed' => $completedAt,
        ':mid' => $matchId,
        ':uid' => $uid,
    ]);

    pvp_resolve_winner($db, $matchId);

    $stmt->execute([':id' => $matchId]);
    $match = $stmt->fetch(PDO::FETCH_ASSOC);
    $me = pvp_player_row_by_user(pvp_fetch_match_players($db, $matchId), $uid);

    auth_send_json([
        'player' => [
            'user_id' => $uid,
            'score' => (int) $me['score'],
            'words' => $validation['valid_words'],
            'player_status' => 'submitted',
        ],
        'match' => pvp_match_to_json($db, $match, $uid),
        'validation' => $validation,
    ]);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Database error: ' . $e->getMessage()], 500);
} catch (Throwable $e) {
    auth_send_json(['error' => 'Server error: ' . $e->getMessage()], 500);
}
