<?php

/**
 * POST /login.php
 * JSON: { "email": string, "password": string }
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

if ($email === '' || $password === '') {
    auth_send_json(['error' => 'Email and password are required'], 400);
}

try {
    $db = getDb();

    $stmt = $db->prepare(
        'SELECT id, email, password_hash, display_name, avatar FROM users WHERE email = :e LIMIT 1'
    );
    $stmt->execute([':e' => $email]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row === false || !password_verify($password, $row['password_hash'])) {
        auth_send_json(['error' => 'Invalid email or password'], 401);
    }

    $userId = (int) $row['id'];
    $token = auth_create_token($db, $userId);

    $av = isset($row['avatar']) && $row['avatar'] !== null && $row['avatar'] !== ''
        ? $row['avatar']
        : 'm1';

    auth_send_json([
        'token' => $token,
        'user'  => [
            'id'           => $userId,
            'email'        => $row['email'],
            'display_name' => $row['display_name'],
            'avatar'       => $av,
        ],
    ], 200);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Login failed: ' . $e->getMessage()], 500);
}
