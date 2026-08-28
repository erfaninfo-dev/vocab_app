<?php

require_once __DIR__ . '/teacher_student_session_api_helpers.php';

function teacher_class_groups_table_exists(PDO $db)
{
    try {
        $db->query('SELECT 1 FROM teacher_class_groups LIMIT 1');

        return true;
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'teacher_class_groups') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            return false;
        }
        throw $e;
    }
}

function teacher_class_group_belongs(PDO $db, $groupId, $teacherId)
{
    $st = $db->prepare(
        'SELECT id FROM teacher_class_groups WHERE id = :id AND teacher_user_id = :t LIMIT 1'
    );
    $st->execute([':id' => $groupId, ':t' => $teacherId]);

    return $st->fetch() !== false;
}

/**
 * @return list<array<string,mixed>>
 */
function teacher_class_groups_list_json(PDO $db, $teacherId)
{
    $st = $db->prepare(
        'SELECT g.id, g.name, g.note, g.created_at, g.updated_at,
                (SELECT COUNT(*) FROM teacher_class_group_members m WHERE m.group_id = g.id) AS member_count
         FROM teacher_class_groups g
         WHERE g.teacher_user_id = :t
         ORDER BY g.name ASC, g.id ASC'
    );
    $st->execute([':t' => $teacherId]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $r) {
        $note = isset($r['note']) ? trim((string) $r['note']) : '';
        $out[] = [
            'id'           => (int) $r['id'],
            'name'         => (string) $r['name'],
            'note'         => $note === '' ? null : $note,
            'member_count' => (int) $r['member_count'],
            'created_at'   => $r['created_at'],
            'updated_at'   => $r['updated_at'],
        ];
    }

    return $out;
}

/**
 * @return array<string,mixed>|null
 */
function teacher_class_group_detail_json(PDO $db, $teacherId, $groupId)
{
    $st = $db->prepare(
        'SELECT id, name, note, created_at, updated_at
         FROM teacher_class_groups
         WHERE id = :id AND teacher_user_id = :t LIMIT 1'
    );
    $st->execute([':id' => $groupId, ':t' => $teacherId]);
    $g = $st->fetch(PDO::FETCH_ASSOC);
    if ($g === false) {
        return null;
    }
    $note = isset($g['note']) ? trim((string) $g['note']) : '';
    $members = teacher_class_group_members_json($db, $groupId);

    return [
        'id'           => (int) $g['id'],
        'name'         => (string) $g['name'],
        'note'         => $note === '' ? null : $note,
        'member_count' => count($members),
        'members'      => $members,
        'created_at'   => $g['created_at'],
        'updated_at'   => $g['updated_at'],
    ];
}

/**
 * @return list<array<string,mixed>>
 */
function teacher_class_group_members_json(PDO $db, $groupId)
{
    $st = $db->prepare(
        'SELECT m.student_user_id, m.added_at, u.email, u.display_name, u.avatar
         FROM teacher_class_group_members m
         JOIN users u ON u.id = m.student_user_id
         WHERE m.group_id = :g
         ORDER BY m.added_at ASC, m.id ASC'
    );
    $st->execute([':g' => $groupId]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $r) {
        $display = isset($r['display_name']) ? trim((string) $r['display_name']) : '';
        $email = isset($r['email']) ? (string) $r['email'] : '';
        $out[] = [
            'student_id'     => (int) $r['student_user_id'],
            'display_name'   => $display !== '' ? $display : $email,
            'email'          => $email,
            'avatar'         => isset($r['avatar']) && $r['avatar'] !== '' ? $r['avatar'] : 'm1',
            'added_at'       => $r['added_at'],
        ];
    }

    return $out;
}

function teacher_class_group_sync_student_count(PDO $db, $teacherId, $studentId)
{
    $existing = $db->prepare(
        'SELECT note FROM teacher_student_sessions WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
    );
    $existing->execute([':t' => $teacherId, ':s' => $studentId]);
    $er = $existing->fetch(PDO::FETCH_ASSOC);
    $noteVal = ($er !== false && isset($er['note'])) ? $er['note'] : null;

    $cntSt = $db->prepare(
        'SELECT COUNT(*) FROM teacher_class_session_entries
         WHERE teacher_user_id = :t AND student_user_id = :s'
    );
    $cntSt->execute([':t' => $teacherId, ':s' => $studentId]);
    $cnt = (int) $cntSt->fetchColumn();

    $ins = $db->prepare(
        'INSERT INTO teacher_student_sessions (teacher_user_id, student_user_id, session_count, note)
         VALUES (:t, :s, :c, :n)
         ON DUPLICATE KEY UPDATE session_count = VALUES(session_count), updated_at = CURRENT_TIMESTAMP'
    );
    $ins->execute([
        ':t' => $teacherId,
        ':s' => $studentId,
        ':c' => $cnt,
        ':n' => $noteVal,
    ]);
}

/**
 * @return array{added_count: int, results: list<array<string,mixed>>}
 */
function teacher_class_group_add_sessions_for_members(
    PDO $db,
    $teacherId,
    $groupId,
    array $actorUser,
    $recordedAtMysql
) {
    $mst = $db->prepare(
        'SELECT student_user_id FROM teacher_class_group_members WHERE group_id = :g ORDER BY id ASC'
    );
    $mst->execute([':g' => $groupId]);
    $memberIds = $mst->fetchAll(PDO::FETCH_COLUMN);
    $results = [];
    $addedCount = 0;

    foreach ($memberIds as $sidRaw) {
        $sid = (int) $sidRaw;
        if ($sid < 1) {
            continue;
        }
        if (!teacher_student_belongs($db, $teacherId, $sid, $actorUser)) {
            $results[] = [
                'student_id' => $sid,
                'ok'         => false,
                'error'      => 'Forbidden',
            ];
            continue;
        }
        try {
            $sessionId = teacher_add_class_session_current_or_next_term(
                $db,
                $teacherId,
                $sid,
                $recordedAtMysql,
                $groupId
            );
            teacher_class_group_sync_student_count($db, $teacherId, $sid);
            $results[] = [
                'student_id'  => $sid,
                'ok'          => true,
                'session_id'  => $sessionId,
            ];
            ++$addedCount;
        } catch (PDOException $e) {
            $results[] = [
                'student_id' => $sid,
                'ok'         => false,
                'error'      => $e->getMessage(),
            ];
        }
    }

    return ['added_count' => $addedCount, 'results' => $results];
}

/**
 * @param array<int, array<string,mixed>> $sessions
 *
 * @return array<int, array<string,mixed>>
 */
function teacher_sessions_filter_by_group(array $sessions, $groupId)
{
    $out = [];
    foreach ($sessions as $s) {
        $gid = array_key_exists('group_id', $s) ? $s['group_id'] : null;
        if ($groupId === null) {
            if ($gid === null) {
                $out[] = $s;
            }
            continue;
        }
        if ($gid !== null && (int) $gid === (int) $groupId) {
            $out[] = $s;
        }
    }

    return $out;
}

/**
 * @param array<int, array<string,mixed>> $allSessions
 *
 * @return array<string,mixed>
 */
function my_class_sessions_build_view_payload(
    PDO $db,
    $tid,
    $sid,
    array $allSessions,
    $groupIdFilter,
    $enrichFinancial = false
) {
    $sessions = teacher_sessions_filter_by_group($allSessions, $groupIdFilter);
    $out = [
        'session_count' => count($sessions),
        'sessions'      => $sessions,
    ];
    if (teacher_student_terms_table_exists($db)) {
        $terms = teacher_terms_list_json($db, $tid, $sid);
        for ($i = 0; $i < count($terms); ++$i) {
            $termId = (int) $terms[$i]['id'];
            $cnt = 0;
            foreach ($sessions as $s) {
                if (isset($s['term_id']) && (int) $s['term_id'] === $termId) {
                    ++$cnt;
                }
            }
            $terms[$i]['session_count'] = $cnt;
        }
        $out['terms'] = $terms;
    }
    if ($enrichFinancial && function_exists('teacher_append_financial_to_sessions_payload')) {
        teacher_append_financial_to_sessions_payload($db, $tid, $sid, $out);
    }

    return $out;
}

/**
 * @return list<array<string,mixed>>
 */
function my_class_sessions_student_groups_meta(PDO $db, $tid, $sid)
{
    if (!teacher_class_groups_table_exists($db)) {
        return [];
    }
    $st = $db->prepare(
        'SELECT g.id, g.name, g.note
         FROM teacher_class_groups g
         INNER JOIN teacher_class_group_members m ON m.group_id = g.id
         WHERE g.teacher_user_id = :t AND m.student_user_id = :s
         ORDER BY g.name ASC, g.id ASC'
    );
    $st->execute([':t' => $tid, ':s' => $sid]);
    $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    $out = [];
    foreach ($rows as $r) {
        $note = isset($r['note']) ? trim((string) $r['note']) : '';
        $out[] = [
            'id'   => (int) $r['id'],
            'name' => (string) $r['name'],
            'note' => $note === '' ? null : $note,
        ];
    }

    return $out;
}
