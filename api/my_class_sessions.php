<?php

/**
 * GET /my_class_sessions.php
 * Logged-in student (not teacher): class sessions recorded by their assigned teacher.
 * Response:
 *   personal — sessions with no group_id (one-on-one class)
 *   class_groups — each group the student belongs to, with filtered sessions
 *
 * Authorization: Bearer.
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';
require_once __DIR__ . '/teacher_student_session_api_helpers.php';
require_once __DIR__ . '/teacher_financial_api_helpers.php';
require_once __DIR__ . '/teacher_class_groups_api_helpers.php';

if (!function_exists('my_class_sessions_build_view_payload')) {
    auth_send_json(
        ['error' => 'Server not migrated: upload teacher_class_groups_api_helpers.php from api/ folder'],
        500
    );
}

auth_options_exit();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$method = $_SERVER['REQUEST_METHOD'] ?? '';
if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($method !== 'GET') {
    auth_send_json(['error' => 'Method not allowed'], 405);
}

$raw = auth_bearer_token();
if ($raw === null || $raw === '') {
    auth_send_json(['error' => 'Missing token'], 401);
}

try {
    $db = getDb();
    $user = auth_user_from_token($db, $raw);
    if ($user === null) {
        auth_send_json(['error' => 'Invalid or expired token'], 401);
    }
    if ((int) ($user['is_teacher'] ?? 0) === 1) {
        auth_send_json(['error' => 'Forbidden'], 403);
    }

    $teacherId = isset($user['teacher_user_id']) ? $user['teacher_user_id'] : null;
    if ($teacherId === null || (int) $teacherId < 1) {
        auth_send_json([
            'personal'      => [
                'session_count' => 0,
                'sessions'      => [],
            ],
            'class_groups'  => [],
        ], 200);
        exit;
    }

    $tid = (int) $teacherId;
    $sid = (int) $user['id'];

    try {
        [$allSessions, $tableOk] = teacher_class_sessions_list($db, $tid, $sid);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            auth_send_json([
                'personal'     => [
                    'session_count' => 0,
                    'sessions'      => [],
                ],
                'class_groups' => [],
            ], 200);
            exit;
        }
        throw $e;
    }

    if (!$tableOk) {
        auth_send_json([
            'personal'     => [
                'session_count' => 0,
                'sessions'      => [],
            ],
            'class_groups' => [],
        ], 200);
        exit;
    }

    $personal = my_class_sessions_build_view_payload($db, $tid, $sid, $allSessions, null, true);

    $classGroups = [];
    foreach (my_class_sessions_student_groups_meta($db, $tid, $sid) as $meta) {
        $view = my_class_sessions_build_view_payload(
            $db,
            $tid,
            $sid,
            $allSessions,
            (int) $meta['id'],
            false
        );
        $classGroups[] = array_merge($meta, $view);
    }

    auth_send_json([
        'personal'     => $personal,
        'class_groups' => $classGroups,
    ], 200);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Request failed'], 500);
} catch (Throwable $e) {
    auth_send_json(['error' => 'Request failed: ' . $e->getMessage()], 500);
}
