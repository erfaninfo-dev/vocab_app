<?php

/**
 * Auth helpers — compatible with PHP 7.4+ (no mixed/never).
 */

/**
 * Reads Bearer token from Authorization header (Apache may pass REDIRECT_HTTP_AUTHORIZATION).
 *
 * @return string|null
 */
function auth_bearer_token()
{
    $h = isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : '';
    if ($h === '' && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $h = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }
    if ($h === '' || !preg_match('/Bearer\s+(\S+)/i', $h, $m)) {
        return null;
    }

    return $m[1];
}

/**
 * Creates a new random token row; returns the raw 64-char hex token.
 *
 * @param PDO $db
 * @param int $userId
 * @return string
 */
function auth_create_token($db, $userId)
{
    $token = bin2hex(random_bytes(32));
    $expires = (new DateTimeImmutable('+90 days'))->format('Y-m-d H:i:s');
    $stmt = $db->prepare(
        'INSERT INTO user_tokens (user_id, token, expires_at) VALUES (:uid, :tok, :exp)'
    );
    $stmt->execute([
        ':uid' => $userId,
        ':tok' => $token,
        ':exp' => $expires,
    ]);

    return $token;
}

/**
 * Returns user row [id, email, display_name] or null if invalid/expired token.
 *
 * @param PDO $db
 * @param string $token
 * @return array|null
 */
function auth_user_from_token($db, $token)
{
    if (strlen($token) !== 64 || !ctype_xdigit($token)) {
        return null;
    }
    $stmt = $db->prepare(
        'SELECT u.id, u.email, u.display_name, u.avatar
         FROM   users u
         INNER JOIN user_tokens t ON t.user_id = u.id
         WHERE  t.token = :tok
         AND    t.expires_at > NOW()
         LIMIT  1'
    );
    $stmt->execute([':tok' => $token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return $row === false ? null : $row;
}

function auth_json_body()
{
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);

    return is_array($data) ? $data : [];
}

/**
 * @param mixed $data
 * @param int   $code HTTP status
 */
function auth_send_json($data, $code = 200)
{
    http_response_code($code);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function auth_options_exit()
{
    if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
        http_response_code(204);
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');
        exit;
    }
}
