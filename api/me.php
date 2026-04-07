<?php

/**
 * GET /me.php
 * Header: Authorization: Bearer <token>
 * Response: { "user": { "id", "email", "display_name", "avatar" } }
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

auth_options_exit();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'GET') {
    auth_send_json(['error' => 'Only GET is allowed'], 405);
}

$raw = auth_bearer_token();
if ($raw === null || $raw === '') {
    auth_send_json(['error' => 'Missing token'], 401);
}

$db = getDb();
$user = auth_user_from_token($db, $raw);
if ($user === null) {
    auth_send_json(['error' => 'Invalid or expired token'], 401);
}

$av = isset($user['avatar']) && $user['avatar'] !== null && $user['avatar'] !== ''
    ? $user['avatar']
    : 'm1';

auth_send_json([
    'user' => [
        'id'           => (int) $user['id'],
        'email'        => $user['email'],
        'display_name' => $user['display_name'],
        'avatar'       => $av,
    ],
], 200);
