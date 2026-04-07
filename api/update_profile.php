<?php

/**
 * POST /update_profile.php
 * Header: Authorization: Bearer <token>
 * JSON: { "display_name"?: string, "avatar"?: string }
 * At least one field required. Allowed avatar: m1, m2, m3, m4, f1, f2, f3, f4
 * Response: { "user": { "id", "email", "display_name", "avatar" } }
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

auth_options_exit();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    auth_send_json(['error' => 'Only POST is allowed'], 405);
}

$raw = auth_bearer_token();
if ($raw === null || $raw === '') {
    auth_send_json(['error' => 'Missing token'], 401);
}

$allowedAvatar = ['m1', 'm2', 'm3', 'm4', 'f1', 'f2', 'f3', 'f4'];

$data = auth_json_body();
$hasDisplay = array_key_exists('display_name', $data);
$hasAvatar = array_key_exists('avatar', $data);

if (!$hasDisplay && !$hasAvatar) {
    auth_send_json(['error' => 'Nothing to update'], 400);
}

try {
    $db = getDb();
    $user = auth_user_from_token($db, $raw);
    if ($user === null) {
        auth_send_json(['error' => 'Invalid or expired token'], 401);
    }

    $uid = (int) $user['id'];

    $fields = [];
    $params = [':id' => $uid];

    if ($hasDisplay) {
        $dn = trim((string) $data['display_name']);
        if (strlen($dn) > 100) {
            auth_send_json(['error' => 'Display name is too long'], 400);
        }
        $fields[] = 'display_name = :dn';
        $params[':dn'] = $dn === '' ? null : $dn;
    }

    if ($hasAvatar) {
        $av = trim((string) $data['avatar']);
        if ($av === '') {
            $av = 'm1';
        }
        if (!in_array($av, $allowedAvatar, true)) {
            auth_send_json(['error' => 'Invalid avatar'], 400);
        }
        $fields[] = 'avatar = :av';
        $params[':av'] = $av;
    }

    $sql = 'UPDATE users SET ' . implode(', ', $fields) . ' WHERE id = :id LIMIT 1';
    $stmt = $db->prepare($sql);
    $stmt->execute($params);

    $sel = $db->prepare(
        'SELECT id, email, display_name, avatar FROM users WHERE id = :id LIMIT 1'
    );
    $sel->execute([':id' => $uid]);
    $row = $sel->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        auth_send_json(['error' => 'User not found'], 404);
    }

    $avOut = isset($row['avatar']) && $row['avatar'] !== null && $row['avatar'] !== ''
        ? $row['avatar']
        : 'm1';

    auth_send_json([
        'user' => [
            'id'           => (int) $row['id'],
            'email'        => $row['email'],
            'display_name' => $row['display_name'],
            'avatar'       => $avOut,
        ],
    ], 200);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Update failed: ' . $e->getMessage()], 500);
}
