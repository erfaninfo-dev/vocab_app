<?php

/**
 * POST /register.php
 * JSON: { "email": string, "password": string, "display_name"?: string }
 * Response: { "token": string, "user": { "id", "email", "display_name" } }
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

$data = auth_json_body();
$email = isset($data['email']) ? strtolower(trim((string) $data['email'])) : '';
$password = isset($data['password']) ? (string) $data['password'] : '';
$displayName = isset($data['display_name']) ? trim((string) $data['display_name']) : '';

if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    auth_send_json(['error' => 'Invalid email'], 400);
}

if (strlen($password) < 8) {
    auth_send_json(['error' => 'Password must be at least 8 characters'], 400);
}

if (strlen($password) > 72) {
    auth_send_json(['error' => 'Password is too long'], 400);
}

if ($displayName !== '' && strlen($displayName) > 100) {
    auth_send_json(['error' => 'Display name is too long'], 400);
}

$displayName = $displayName === '' ? null : $displayName;

try {
    $db = getDb();

    $check = $db->prepare('SELECT id FROM users WHERE email = :e LIMIT 1');
    $check->execute([':e' => $email]);
    if ($check->fetchColumn() !== false) {
        auth_send_json(['error' => 'Email already registered'], 409);
    }

    $hash = password_hash($password, PASSWORD_DEFAULT);

    $ins = $db->prepare(
        'INSERT INTO users (email, password_hash, display_name, avatar) VALUES (:e, :p, :d, :a)'
    );
    $ins->execute([
        ':e' => $email,
        ':p' => $hash,
        ':d' => $displayName,
        ':a' => 'm1',
    ]);

    $userId = (int) $db->lastInsertId();
    $token = auth_create_token($db, $userId);

    auth_send_json([
        'token' => $token,
        'user'  => [
            'id'           => $userId,
            'email'        => $email,
            'display_name' => $displayName,
            'avatar'       => 'm1',
        ],
    ], 201);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Registration failed: ' . $e->getMessage()], 500);
}
