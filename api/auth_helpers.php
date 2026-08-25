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
        'SELECT u.id, u.email, u.display_name, u.bio, u.avatar, IFNULL(u.student_access, 0) AS student_access,
                IFNULL(u.is_teacher, 0) AS is_teacher, IFNULL(u.is_admin, 0) AS is_admin, u.teacher_user_id
         FROM   users u
         INNER JOIN user_tokens t ON t.user_id = u.id
         WHERE  t.token = :tok
         AND    t.expires_at > NOW()
         LIMIT  1'
    );
    $stmt->execute([':tok' => $token]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        return null;
    }
    auth_ensure_teacher_for_admin($db, $row);

    return $row;
}

/**
 * App admins get teacher panel access by default (is_teacher = 1).
 * Teachers are not promoted to admin automatically.
 *
 * @param array<string,mixed> $row users row (mutated when updated)
 */
function auth_ensure_teacher_for_admin(PDO $db, array &$row)
{
    if (!isset($row['id'])) {
        return;
    }
    $ia = isset($row['is_admin']) ? (int) $row['is_admin'] : 0;
    $it = isset($row['is_teacher']) ? (int) $row['is_teacher'] : 0;
    if ($ia !== 1 || $it === 1) {
        return;
    }
    $uid = (int) $row['id'];
    try {
        $db->prepare(
            'UPDATE users SET is_teacher = 1 WHERE id = :id LIMIT 1'
        )->execute([':id' => $uid]);
    } catch (PDOException $e) {
        return;
    }
    $row['is_teacher'] = 1;
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

/**
 * JSON shape for `user` in login/register/me/profile responses.
 *
 * @param array $row From `users` with keys id, email, display_name, bio, avatar, student_access (optional).
 *
 * @return array<string, mixed>
 */
function auth_user_to_json(array $row)
{
    $av = isset($row['avatar']) && $row['avatar'] !== null && $row['avatar'] !== ''
        ? $row['avatar']
        : 'm1';
    $sa = isset($row['student_access']) ? (int) $row['student_access'] : 0;
    $it = isset($row['is_teacher']) ? (int) $row['is_teacher'] : 0;
    $ia = isset($row['is_admin']) ? (int) $row['is_admin'] : 0;
    $tuid = isset($row['teacher_user_id']) && $row['teacher_user_id'] !== null && $row['teacher_user_id'] !== ''
        ? (int) $row['teacher_user_id']
        : null;

    return [
        'id'               => (int) $row['id'],
        'email'            => $row['email'],
        'display_name'     => $row['display_name'],
        'bio'              => isset($row['bio']) ? $row['bio'] : null,
        'avatar'           => $av,
        'student_access'   => $sa === 1,
        'is_teacher'       => $it === 1,
        'is_admin'         => $ia === 1,
        'teacher_user_id'  => $tuid,
    ];
}
