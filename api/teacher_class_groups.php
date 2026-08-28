<?php

/**
 * Teacher panel — multi-student group classes.
 *
 * GET /teacher_class_groups.php
 *   Returns { "groups": [ { id, name, note?, member_count, created_at, updated_at } ] }
 *
 * GET /teacher_class_groups.php?group_id=
 *   Returns one group with members[].
 *
 * POST JSON:
 *   { "create_group": true, "name": string, "note"?: string }
 *   { "update_group": true, "group_id": int, "name"?: string, "note"?: string|null }
 *   { "delete_group_id": int }
 *   { "group_id": int, "add_member": true, "student_id": int }
 *   { "group_id": int, "remove_member": true, "student_id": int }
 *   { "group_id": int, "add_group_session": true, "recorded_at"?: ISO8601 }
 *
 * Authorization: Bearer (teacher or admin).
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';
require_once __DIR__ . '/teacher_helpers.php';
require_once __DIR__ . '/session_recorded_at.php';
require_once __DIR__ . '/teacher_class_groups_api_helpers.php';

auth_options_exit();

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

$method = $_SERVER['REQUEST_METHOD'] ?? '';
if ($method === 'OPTIONS') {
    http_response_code(204);
    exit;
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
    $tid = teacher_require_user($db, $user);

    if (!teacher_class_groups_table_exists($db)) {
        auth_send_json(['error' => 'Server not migrated: run teacher_class_groups_schema.sql'], 500);
    }

    if ($method === 'GET') {
        $groupId = isset($_GET['group_id']) ? (int) $_GET['group_id'] : 0;
        if ($groupId > 0) {
            $detail = teacher_class_group_detail_json($db, $tid, $groupId);
            if ($detail === null) {
                auth_send_json(['error' => 'Group not found'], 404);
            }
            auth_send_json(['ok' => true, 'group' => $detail], 200);
        }
        auth_send_json(['ok' => true, 'groups' => teacher_class_groups_list_json($db, $tid)], 200);
    }

    if ($method !== 'POST') {
        auth_send_json(['error' => 'Method not allowed'], 405);
    }

    $data = auth_json_body();

    $deleteGroupId = isset($data['delete_group_id']) ? (int) $data['delete_group_id'] : 0;
    if ($deleteGroupId > 0) {
        if (!teacher_class_group_belongs($db, $deleteGroupId, $tid)) {
            auth_send_json(['error' => 'Group not found'], 404);
        }
        $del = $db->prepare('DELETE FROM teacher_class_groups WHERE id = :id AND teacher_user_id = :t');
        $del->execute([':id' => $deleteGroupId, ':t' => $tid]);
        auth_send_json(['ok' => true, 'groups' => teacher_class_groups_list_json($db, $tid)], 200);
    }

    if (!empty($data['create_group'])) {
        $name = isset($data['name']) ? trim((string) $data['name']) : '';
        if ($name === '') {
            auth_send_json(['error' => 'name is required'], 400);
        }
        if (strlen($name) > 120) {
            auth_send_json(['error' => 'name is too long (max 120 characters)'], 400);
        }
        $note = null;
        if (array_key_exists('note', $data)) {
            $rawNote = $data['note'];
            if ($rawNote !== null) {
                $note = trim((string) $rawNote);
                if (strlen($note) > 8000) {
                    auth_send_json(['error' => 'note is too long (max 8000 characters)'], 400);
                }
                if ($note === '') {
                    $note = null;
                }
            }
        }
        $ins = $db->prepare(
            'INSERT INTO teacher_class_groups (teacher_user_id, name, note) VALUES (:t, :n, :note)'
        );
        $ins->execute([':t' => $tid, ':n' => $name, ':note' => $note]);
        $newId = (int) $db->lastInsertId();
        $detail = teacher_class_group_detail_json($db, $tid, $newId);
        auth_send_json(['ok' => true, 'group' => $detail], 200);
    }

    $groupId = isset($data['group_id']) ? (int) $data['group_id'] : 0;

    if (!empty($data['update_group'])) {
        if ($groupId < 1) {
            auth_send_json(['error' => 'group_id is required'], 400);
        }
        if (!teacher_class_group_belongs($db, $groupId, $tid)) {
            auth_send_json(['error' => 'Group not found'], 404);
        }
        $fields = [];
        $params = [':id' => $groupId, ':t' => $tid];
        if (array_key_exists('name', $data)) {
            $name = trim((string) $data['name']);
            if ($name === '') {
                auth_send_json(['error' => 'name cannot be empty'], 400);
            }
            if (strlen($name) > 120) {
                auth_send_json(['error' => 'name is too long (max 120 characters)'], 400);
            }
            $fields[] = 'name = :n';
            $params[':n'] = $name;
        }
        if (array_key_exists('note', $data)) {
            $rawNote = $data['note'];
            $noteVal = null;
            if ($rawNote !== null) {
                $noteVal = trim((string) $rawNote);
                if (strlen($noteVal) > 8000) {
                    auth_send_json(['error' => 'note is too long (max 8000 characters)'], 400);
                }
                if ($noteVal === '') {
                    $noteVal = null;
                }
            }
            $fields[] = 'note = :note';
            $params[':note'] = $noteVal;
        }
        if (count($fields) === 0) {
            auth_send_json(['error' => 'Nothing to update'], 400);
        }
        $sql = 'UPDATE teacher_class_groups SET ' . implode(', ', $fields)
            . ' WHERE id = :id AND teacher_user_id = :t';
        $up = $db->prepare($sql);
        $up->execute($params);
        $detail = teacher_class_group_detail_json($db, $tid, $groupId);
        auth_send_json(['ok' => true, 'group' => $detail], 200);
    }

    if ($groupId < 1) {
        auth_send_json(['error' => 'group_id is required'], 400);
    }
    if (!teacher_class_group_belongs($db, $groupId, $tid)) {
        auth_send_json(['error' => 'Group not found'], 404);
    }

    if (!empty($data['add_member'])) {
        $studentId = isset($data['student_id']) ? (int) $data['student_id'] : 0;
        if ($studentId < 1) {
            auth_send_json(['error' => 'student_id is required'], 400);
        }
        if (!teacher_student_belongs($db, $tid, $studentId, $user)) {
            auth_send_json(['error' => 'Forbidden'], 403);
        }
        try {
            $ins = $db->prepare(
                'INSERT INTO teacher_class_group_members (group_id, student_user_id)
                 VALUES (:g, :s)'
            );
            $ins->execute([':g' => $groupId, ':s' => $studentId]);
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate') !== false
                || strpos($e->getMessage(), '1062') !== false) {
                auth_send_json(['error' => 'Student is already in this group'], 400);
            }
            throw $e;
        }
        $detail = teacher_class_group_detail_json($db, $tid, $groupId);
        auth_send_json(['ok' => true, 'group' => $detail], 200);
    }

    if (!empty($data['remove_member'])) {
        $studentId = isset($data['student_id']) ? (int) $data['student_id'] : 0;
        if ($studentId < 1) {
            auth_send_json(['error' => 'student_id is required'], 400);
        }
        $del = $db->prepare(
            'DELETE FROM teacher_class_group_members
             WHERE group_id = :g AND student_user_id = :s'
        );
        $del->execute([':g' => $groupId, ':s' => $studentId]);
        if ($del->rowCount() < 1) {
            auth_send_json(['error' => 'Member not found'], 404);
        }
        $detail = teacher_class_group_detail_json($db, $tid, $groupId);
        auth_send_json(['ok' => true, 'group' => $detail], 200);
    }

    if (!empty($data['add_group_session'])) {
        $rawAt = isset($data['recorded_at']) ? trim((string) $data['recorded_at']) : '';
        if ($rawAt !== '') {
            try {
                $mysqlAt = session_recorded_at_iso_to_mysql_utc($rawAt);
            } catch (Throwable $e) {
                auth_send_json(['error' => 'Invalid recorded_at'], 400);
            }
        } else {
            $mysqlAt = (new DateTimeImmutable('now', new DateTimeZone('UTC')))->format('Y-m-d H:i:s');
        }
        $bulk = teacher_class_group_add_sessions_for_members($db, $tid, $groupId, $user, $mysqlAt);
        $detail = teacher_class_group_detail_json($db, $tid, $groupId);
        auth_send_json([
            'ok'          => true,
            'group'       => $detail,
            'added_count' => $bulk['added_count'],
            'results'     => $bulk['results'],
        ], 200);
    }

    auth_send_json(['error' => 'Unknown action'], 400);
} catch (PDOException $e) {
    auth_send_json(['error' => 'Database error'], 500);
} catch (Throwable $e) {
    auth_send_json(['error' => 'Server error'], 500);
}
