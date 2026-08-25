<?php
/**
 * GET /grammar_result_reactions.php?result_ids=1,2,3
 *   Public. Optional Bearer adds `my_emoji` per result for the signed-in user.
 *
 * POST /grammar_result_reactions.php  (Bearer required)
 *   JSON: { "result_id": 123, "emoji": "🔥" }
 *   Empty emoji removes the user's reaction. Same emoji toggles off.
 *
 * Allowed emoji (5): 👍 ❤️ 🔥 👏 🎯
 *
 * Deploy with auth_helpers.php (auth_bearer_token + auth_user_from_token).
 * Run grammar_result_reactions_schema.sql once on MySQL.
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$allowedEmojis = ['👍', '❤️', '🔥', '👏', '🎯'];

/**
 * @return array<string,string> canonical key => stored emoji
 */
function grammar_reactions_allowed_map(array $allowedEmojis)
{
    $map = [];
    foreach ($allowedEmojis as $emoji) {
        $map[grammar_reactions_canonical_emoji($emoji)] = $emoji;
    }

    return $map;
}

function grammar_reactions_canonical_emoji($emoji)
{
    $emoji = trim((string) $emoji);
    if ($emoji === '') {
        return '';
    }
    if (function_exists('normalizer_normalize')) {
        $normalized = normalizer_normalize($emoji, Normalizer::FORM_C);
        if (is_string($normalized) && $normalized !== '') {
            $emoji = $normalized;
        }
    }

    return preg_replace('/\x{FE0F}/u', '', $emoji);
}

/**
 * @return array<string,mixed>|null
 */
function grammar_reactions_optional_user(PDO $db)
{
    if (!function_exists('auth_bearer_token') || !function_exists('auth_user_from_token')) {
        return null;
    }
    $raw = auth_bearer_token();
    if ($raw === null || $raw === '') {
        return null;
    }

    return auth_user_from_token($db, $raw);
}

/**
 * @return array<string,mixed>
 */
function grammar_reactions_require_user(PDO $db)
{
    if (function_exists('auth_require_user')) {
        return auth_require_user($db);
    }
    if (!function_exists('auth_bearer_token') || !function_exists('auth_user_from_token')) {
        sendError('Server auth helpers are missing', 500);
    }
    $raw = auth_bearer_token();
    if ($raw === null || $raw === '') {
        sendError('Missing token', 401);
    }
    $user = auth_user_from_token($db, $raw);
    if ($user === null) {
        sendError('Invalid or expired token', 401);
    }

    return $user;
}

function grammar_reactions_normalize_incoming_emoji($emoji, array $allowedMap)
{
    $emoji = trim((string) $emoji);
    if ($emoji === '') {
        return '';
    }
    $canonical = grammar_reactions_canonical_emoji($emoji);
    if (!isset($allowedMap[$canonical])) {
        sendError('Emoji not allowed', 400);
    }

    return $allowedMap[$canonical];
}

function grammar_reactions_assert_table(PDO $db)
{
    static $checked = false;
    if ($checked) {
        return;
    }
    $stmt = $db->query("SHOW TABLES LIKE 'grammar_result_reactions'");
    if ($stmt === false || $stmt->fetch() === false) {
        sendError(
            'grammar_result_reactions table is missing. Run grammar_result_reactions_schema.sql on MySQL.',
            500
        );
    }
    $checked = true;
}

try {
    $db = getDb();
    grammar_reactions_assert_table($db);
    $allowedMap = grammar_reactions_allowed_map($allowedEmojis);
    $method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

    if ($method === 'GET') {
        $rawIds = isset($_GET['result_ids']) ? trim((string) $_GET['result_ids']) : '';
        $ids = [];
        if ($rawIds !== '') {
            foreach (explode(',', $rawIds) as $part) {
                $id = (int) trim($part);
                if ($id > 0) {
                    $ids[$id] = $id;
                }
            }
        }
        $ids = array_values($ids);
        if ($ids === []) {
            sendJson(['reactions' => new stdClass()]);
        }

        $user = grammar_reactions_optional_user($db);
        $uid = $user === null ? 0 : (int) $user['id'];

        $placeholders = implode(',', array_fill(0, count($ids), '?'));
        $stmt = $db->prepare(
            "SELECT result_id, emoji, COUNT(*) AS reaction_count
             FROM grammar_result_reactions
             WHERE result_id IN ($placeholders)
             GROUP BY result_id, emoji"
        );
        $stmt->execute($ids);
        $countsByResult = [];
        foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $rid = (int) ($row['result_id'] ?? 0);
            $emoji = (string) ($row['emoji'] ?? '');
            if ($rid < 1 || $emoji === '') {
                continue;
            }
            if (!isset($countsByResult[$rid])) {
                $countsByResult[$rid] = [];
            }
            $countsByResult[$rid][$emoji] = (int) ($row['reaction_count'] ?? 0);
        }

        $myByResult = [];
        if ($uid > 0) {
            $stmtMine = $db->prepare(
                "SELECT result_id, emoji
                 FROM grammar_result_reactions
                 WHERE user_id = ?
                 AND result_id IN ($placeholders)"
            );
            $stmtMine->execute(array_merge([$uid], $ids));
            foreach ($stmtMine->fetchAll(PDO::FETCH_ASSOC) as $row) {
                $rid = (int) ($row['result_id'] ?? 0);
                if ($rid > 0) {
                    $myByResult[$rid] = (string) ($row['emoji'] ?? '');
                }
            }
        }

        $out = [];
        foreach ($ids as $rid) {
            $out[(string) $rid] = [
                'counts'   => (object) ($countsByResult[$rid] ?? []),
                'my_emoji' => $myByResult[$rid] ?? null,
            ];
        }

        sendJson(['reactions' => (object) $out]);
    }

    if ($method === 'POST') {
        $user = grammar_reactions_require_user($db);
        $uid = (int) $user['id'];
        $body = json_decode(file_get_contents('php://input'), true);
        if (!is_array($body)) {
            sendError('Invalid JSON body', 400);
        }
        $resultId = (int) ($body['result_id'] ?? 0);
        $emojiRaw = trim((string) ($body['emoji'] ?? ''));
        if ($resultId < 1) {
            sendError('result_id is required', 400);
        }

        try {
            $stmtExists = $db->prepare('SELECT id FROM results WHERE id = :id LIMIT 1');
            $stmtExists->execute([':id' => $resultId]);
            if ($stmtExists->fetch() === false) {
                sendError('Grammar result not found', 404);
            }
        } catch (PDOException $e) {
            // Some deployments may not expose `results` to this script; allow reaction anyway.
        }

        $stmtMine = $db->prepare(
            'SELECT id, emoji FROM grammar_result_reactions
             WHERE result_id = :rid AND user_id = :uid LIMIT 1'
        );
        $stmtMine->execute([':rid' => $resultId, ':uid' => $uid]);
        $existing = $stmtMine->fetch(PDO::FETCH_ASSOC);

        if ($emojiRaw === '') {
            if ($existing !== false) {
                $db->prepare(
                    'DELETE FROM grammar_result_reactions WHERE id = :id'
                )->execute([':id' => (int) $existing['id']]);
            }
            $storedEmoji = '';
        } else {
            $emoji = grammar_reactions_normalize_incoming_emoji($emojiRaw, $allowedMap);
            if ($existing !== false
                && grammar_reactions_canonical_emoji((string) $existing['emoji'])
                    === grammar_reactions_canonical_emoji($emoji)
            ) {
                $db->prepare(
                    'DELETE FROM grammar_result_reactions WHERE id = :id'
                )->execute([':id' => (int) $existing['id']]);
                $storedEmoji = '';
            } elseif ($existing !== false) {
                $db->prepare(
                    'UPDATE grammar_result_reactions SET emoji = :emoji WHERE id = :id'
                )->execute([
                    ':emoji' => $emoji,
                    ':id'    => (int) $existing['id'],
                ]);
                $storedEmoji = $emoji;
            } else {
                $db->prepare(
                    'INSERT INTO grammar_result_reactions (result_id, user_id, emoji)
                     VALUES (:rid, :uid, :emoji)'
                )->execute([
                    ':rid'   => $resultId,
                    ':uid'   => $uid,
                    ':emoji' => $emoji,
                ]);
                $storedEmoji = $emoji;
            }
        }

        $stmtCounts = $db->prepare(
            'SELECT emoji, COUNT(*) AS reaction_count
             FROM grammar_result_reactions
             WHERE result_id = :rid
             GROUP BY emoji'
        );
        $stmtCounts->execute([':rid' => $resultId]);
        $counts = [];
        foreach ($stmtCounts->fetchAll(PDO::FETCH_ASSOC) as $row) {
            $counts[(string) $row['emoji']] = (int) ($row['reaction_count'] ?? 0);
        }

        sendJson([
            'ok'        => true,
            'result_id' => $resultId,
            'my_emoji'  => $storedEmoji === '' ? null : $storedEmoji,
            'counts'    => (object) $counts,
        ]);
    }

    sendError('Method not allowed', 405);
} catch (Throwable $e) {
    sendError('Grammar result reactions failed: ' . $e->getMessage(), 500);
}
