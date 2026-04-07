<?php

declare(strict_types=1);

/**
 * POST /logout.php
 * Header: Authorization: Bearer <token>
 * Revokes the current token.
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

if (strlen($raw) !== 64 || !ctype_xdigit($raw)) {
    auth_send_json(['error' => 'Invalid token'], 401);
}

$db = getDb();
$del = $db->prepare('DELETE FROM user_tokens WHERE token = :tok');
$del->execute([':tok' => $raw]);

auth_send_json(['ok' => true], 200);
