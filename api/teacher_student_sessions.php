<?php

/**
 * GET /teacher_student_sessions.php?student_id=
 *   Returns session_count, updated_at, note, terms (when migrated), sessions.
 *
 * POST /teacher_student_sessions.php  JSON:
 *   { "student_id", "add_term": true, "session_cap": int } — new term (max sessions for that term).
 *   { "student_id", "update_term": true, "term_id": int, "session_cap": int }
 *   { "student_id", "delete_term_id": int } — deletes term and its session rows (CASCADE).
 *   { "student_id", "set_term_payment": true, "term_id": int, "is_paid": bool|0|1 } — tuition paid flag for that term.
 *   { "student_id", "add_session": true, "term_id": int, "recorded_at"?: ISO8601 }
 *   { "student_id", "delete_session_id": int }
 *   { "student_id", "update_session": true, "session_id": int, "recorded_at": ISO8601 }
 *   { "student_id", "note": "...", "note_only": true }
 *   Legacy: { "student_id", "session_count", "note?" } — if no per-session rows yet.
 *
 * Authorization: Bearer (teacher only).
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';
require_once __DIR__ . '/teacher_helpers.php';
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

function teacher_class_sessions_sync_count(PDO $db, $tid, $sid, $noteVal)
{
    $cntSt = $db->prepare(
        'SELECT COUNT(*) FROM teacher_class_session_entries
         WHERE teacher_user_id = :t AND student_user_id = :s'
    );
    $cntSt->execute([':t' => $tid, ':s' => $sid]);
    $cnt = (int) $cntSt->fetchColumn();

    $ins = $db->prepare(
        'INSERT INTO teacher_student_sessions (teacher_user_id, student_user_id, session_count, note)
         VALUES (:t, :s, :c, :n)
         ON DUPLICATE KEY UPDATE session_count = VALUES(session_count), note = VALUES(note), updated_at = CURRENT_TIMESTAMP'
    );
    $ins->execute([
        ':t' => $tid,
        ':s' => $sid,
        ':c' => $cnt,
        ':n' => $noteVal,
    ]);
}

function teacher_sessions_send_state_json(PDO $db, $tid, $studentId, $financialNotice = null)
{
    $existing = $db->prepare(
        'SELECT note FROM teacher_student_sessions WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
    );
    $existing->execute([':t' => $tid, ':s' => $studentId]);
    $er = $existing->fetch(PDO::FETCH_ASSOC);
    $noteVal = ($er !== false && isset($er['note'])) ? $er['note'] : null;

    teacher_class_sessions_sync_count($db, $tid, $studentId, $noteVal);

    $payload = teacher_sessions_build_split_payload($db, $tid, $studentId, $financialNotice);
    $payload['ok'] = true;

    auth_send_json($payload, 200);
}

/**
 * @return array<string,mixed>
 */
function teacher_sessions_build_split_payload(PDO $db, $tid, $sid, $financialNotice = null)
{
    [$allSessions, $tableOk] = teacher_class_sessions_list($db, $tid, $sid);

    $st = $db->prepare(
        'SELECT session_count, updated_at, note FROM teacher_student_sessions
         WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
    );
    $st->execute([':t' => $tid, ':s' => $sid]);
    $row = $st->fetch(PDO::FETCH_ASSOC);

    $noteOut = null;
    $updatedAt = null;
    if ($row !== false) {
        $n = $row['note'];
        $noteOut = ($n !== null && trim((string) $n) !== '') ? (string) $n : null;
        $updatedAt = $row['updated_at'];
    }

    $personal = my_class_sessions_build_view_payload($db, $tid, $sid, $allSessions, null, true);
    $personal['updated_at'] = $updatedAt;
    $personal['note'] = $noteOut;
    if ($financialNotice !== null && $financialNotice !== '') {
        $personal['financial_notice'] = $financialNotice;
    }

    $classGroups = [];
    if (teacher_class_groups_table_exists($db)) {
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
    } elseif (!$tableOk || count($allSessions) === 0) {
        $personal['session_count'] = $row !== false ? (int) $row['session_count'] : 0;
        $personal['sessions'] = [];
    } else {
        $personal['session_count'] = count($allSessions);
        $personal['sessions'] = $allSessions;
    }

    return [
        'personal'     => $personal,
        'class_groups' => $classGroups,
    ];
}

try {
    $db = getDb();
    $user = auth_user_from_token($db, $raw);
    if ($user === null) {
        auth_send_json(['error' => 'Invalid or expired token'], 401);
    }
    $tid = teacher_require_user($db, $user);

    if ($method === 'GET') {
        $studentId = isset($_GET['student_id']) ? (int) $_GET['student_id'] : 0;
        if ($studentId < 1) {
            auth_send_json(['error' => 'student_id is required'], 400);
        }
        if (!teacher_student_belongs($db, $tid, $studentId, $user)) {
            auth_send_json(['error' => 'Forbidden'], 403);
        }

        $payload = teacher_sessions_build_split_payload($db, $tid, $studentId);
        auth_send_json($payload, 200);
    } elseif ($method === 'POST') {
        $data = auth_json_body();
        $studentId = isset($data['student_id']) ? (int) $data['student_id'] : 0;
        if ($studentId < 1) {
            auth_send_json(['error' => 'student_id is required'], 400);
        }
        if (!teacher_student_belongs($db, $tid, $studentId, $user)) {
            auth_send_json(['error' => 'Forbidden'], 403);
        }

        $termsMigrated = teacher_student_terms_table_exists($db);

        if ($termsMigrated && !empty($data['add_term'])) {
            $cap = isset($data['session_cap']) ? (int) $data['session_cap'] : 0;
            if ($cap < 1 || $cap > 500) {
                auth_send_json(['error' => 'session_cap must be between 1 and 500'], 400);
            }
            $termFee = null;
            if (array_key_exists('term_fee', $data)) {
                $termFee = $data['term_fee'];
            } elseif (array_key_exists('session_price', $data)) {
                $termFee = $data['session_price'];
            }
            if ($termFee === null) {
                $termFee = teacher_default_term_fee_for_student($db, $tid, $studentId);
            } elseif (!teacher_validate_money_amount($termFee)) {
                auth_send_json(['error' => 'term_fee must be between 0 and 999999999.99'], 400);
            } else {
                $termFee = round((float) $termFee, 2);
            }
            $mx = $db->prepare(
                'SELECT COALESCE(MAX(sort_order), 0) + 1 FROM teacher_student_terms
                 WHERE teacher_user_id = :t AND student_user_id = :s'
            );
            $mx->execute([':t' => $tid, ':s' => $studentId]);
            $nextOrder = (int) $mx->fetchColumn();
            if (teacher_student_terms_has_term_fee($db)) {
                $ins = $db->prepare(
                    'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap, term_fee)
                     VALUES (:t, :s, :o, :c, :f)'
                );
                $ins->execute([
                    ':t' => $tid,
                    ':s' => $studentId,
                    ':o' => $nextOrder,
                    ':c' => $cap,
                    ':f' => $termFee,
                ]);
            } else {
                $ins = $db->prepare(
                    'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap)
                     VALUES (:t, :s, :o, :c)'
                );
                $ins->execute([
                    ':t' => $tid,
                    ':s' => $studentId,
                    ':o' => $nextOrder,
                    ':c' => $cap,
                ]);
            }
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        if ($termsMigrated && !empty($data['update_term_fee'])) {
            $termIdFee = isset($data['term_id']) ? (int) $data['term_id'] : 0;
            if ($termIdFee < 1) {
                auth_send_json(['error' => 'term_id is required'], 400);
            }
            if (!array_key_exists('term_fee', $data) && !array_key_exists('session_price', $data)) {
                auth_send_json(['error' => 'term_fee is required'], 400);
            }
            $feeVal = array_key_exists('term_fee', $data) ? $data['term_fee'] : $data['session_price'];
            try {
                if (!teacher_update_term_fee($db, $termIdFee, $tid, $studentId, $feeVal)) {
                    auth_send_json(['error' => 'Term not found'], 404);
                }
            } catch (InvalidArgumentException $e) {
                auth_send_json(['error' => $e->getMessage()], 400);
            } catch (RuntimeException $e) {
                auth_send_json(['error' => $e->getMessage()], 500);
            }
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        if ($termsMigrated && !empty($data['update_term'])) {
            $termId = isset($data['term_id']) ? (int) $data['term_id'] : 0;
            if ($termId < 1) {
                auth_send_json(['error' => 'term_id is required'], 400);
            }
            $cap = isset($data['session_cap']) ? (int) $data['session_cap'] : 0;
            if ($cap < 1 || $cap > 500) {
                auth_send_json(['error' => 'session_cap must be between 1 and 500'], 400);
            }
            $own = $db->prepare(
                'SELECT id FROM teacher_student_terms
                 WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s LIMIT 1'
            );
            $own->execute([':id' => $termId, ':t' => $tid, ':s' => $studentId]);
            if ($own->fetch() === false) {
                auth_send_json(['error' => 'Term not found'], 404);
            }
            $cntSt = $db->prepare(
                'SELECT COUNT(*) FROM teacher_class_session_entries WHERE term_id = :id'
            );
            $cntSt->execute([':id' => $termId]);
            $have = (int) $cntSt->fetchColumn();
            if ($have > $cap) {
                auth_send_json([
                    'error' => 'session_cap cannot be less than the number of sessions already recorded in this term',
                ], 400);
            }
            $up = $db->prepare(
                'UPDATE teacher_student_terms SET session_cap = :c
                 WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s'
            );
            $up->execute([
                ':c'  => $cap,
                ':id' => $termId,
                ':t'  => $tid,
                ':s'  => $studentId,
            ]);
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        $delTermId = isset($data['delete_term_id']) ? (int) $data['delete_term_id'] : 0;
        if ($termsMigrated && $delTermId > 0) {
            $del = $db->prepare(
                'DELETE FROM teacher_student_terms
                 WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s'
            );
            $del->execute([
                ':id' => $delTermId,
                ':t'  => $tid,
                ':s'  => $studentId,
            ]);
            if ($del->rowCount() < 1) {
                auth_send_json(['error' => 'Term not found'], 404);
            }
            teacher_terms_renumber($db, $tid, $studentId);
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        if ($termsMigrated && !empty($data['set_term_payment'])) {
            $termIdPay = isset($data['term_id']) ? (int) $data['term_id'] : 0;
            if ($termIdPay < 1) {
                auth_send_json(['error' => 'term_id is required'], 400);
            }
            if (!array_key_exists('is_paid', $data)) {
                auth_send_json(['error' => 'is_paid is required'], 400);
            }
            $isPaidVal = ($data['is_paid'] === true || $data['is_paid'] === 1 || $data['is_paid'] === '1') ? 1 : 0;
            $ownPay = $db->prepare(
                'SELECT id FROM teacher_student_terms
                 WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s LIMIT 1'
            );
            $ownPay->execute([':id' => $termIdPay, ':t' => $tid, ':s' => $studentId]);
            if ($ownPay->fetch() === false) {
                auth_send_json(['error' => 'Term not found'], 404);
            }
            try {
                if (!teacher_update_term_payment($db, $termIdPay, $tid, $studentId, $isPaidVal === 1)) {
                    auth_send_json(['error' => 'Term not found'], 404);
                }
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'Unknown column') !== false
                    && strpos($e->getMessage(), 'is_paid') !== false) {
                    auth_send_json(['error' => 'Server not migrated: run teacher_student_terms_add_is_paid.sql'], 500);
                }
                throw $e;
            }
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        $deleteSessionId = isset($data['delete_session_id']) ? (int) $data['delete_session_id'] : 0;
        if ($deleteSessionId > 0) {
            try {
                $del = $db->prepare(
                    'DELETE FROM teacher_class_session_entries
                     WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s'
                );
                $del->execute([
                    ':id' => $deleteSessionId,
                    ':t'  => $tid,
                    ':s'  => $studentId,
                ]);
                if ($del->rowCount() < 1) {
                    auth_send_json(['error' => 'Session not found'], 404);
                }
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
                    || strpos($e->getMessage(), "doesn't exist") !== false) {
                    auth_send_json(['error' => 'Server not migrated: run teacher_class_session_entries.sql'], 500);
                }
                throw $e;
            }
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        $updateSession = !empty($data['update_session']);
        if ($updateSession) {
            $sessionRowId = isset($data['session_id']) ? (int) $data['session_id'] : 0;
            if ($sessionRowId < 1) {
                auth_send_json(['error' => 'session_id is required'], 400);
            }
            $rawAt = isset($data['recorded_at']) ? trim((string) $data['recorded_at']) : '';
            if ($rawAt === '') {
                auth_send_json(['error' => 'recorded_at is required'], 400);
            }
            try {
                $mysqlDt = session_recorded_at_iso_to_mysql_utc($rawAt);
            } catch (Throwable $e) {
                auth_send_json(['error' => 'Invalid recorded_at'], 400);
            }
            try {
                $up = $db->prepare(
                    'UPDATE teacher_class_session_entries
                     SET recorded_at = :at
                     WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s'
                );
                $up->execute([
                    ':at' => $mysqlDt,
                    ':id' => $sessionRowId,
                    ':t'  => $tid,
                    ':s'  => $studentId,
                ]);
                if ($up->rowCount() < 1) {
                    auth_send_json(['error' => 'Session not found'], 404);
                }
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
                    || strpos($e->getMessage(), "doesn't exist") !== false) {
                    auth_send_json(['error' => 'Server not migrated: run teacher_class_session_entries.sql'], 500);
                }
                throw $e;
            }
            teacher_sessions_send_state_json($db, $tid, $studentId);
            exit;
        }

        $addSession = !empty($data['add_session']);
        $noteOnly = !empty($data['note_only']);

        if ($addSession) {
            $financialNotice = null;
            try {
                $rawAddAt = isset($data['recorded_at']) ? trim((string) $data['recorded_at']) : '';
                $mysqlAddAt = null;
                if ($rawAddAt !== '') {
                    try {
                        $mysqlAddAt = session_recorded_at_iso_to_mysql_utc($rawAddAt);
                    } catch (Throwable $e) {
                        auth_send_json(['error' => 'Invalid recorded_at'], 400);
                    }
                }

                if ($termsMigrated) {
                    $termId = isset($data['term_id']) ? (int) $data['term_id'] : 0;
                    if ($termId < 1) {
                        auth_send_json(['error' => 'term_id is required'], 400);
                    }
                    $tchk = $db->prepare(
                        'SELECT session_cap FROM teacher_student_terms
                         WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s LIMIT 1'
                    );
                    $tchk->execute([':id' => $termId, ':t' => $tid, ':s' => $studentId]);
                    $tr = $tchk->fetch(PDO::FETCH_ASSOC);
                    if ($tr === false) {
                        auth_send_json(['error' => 'Term not found'], 404);
                    }
                    $cap = (int) $tr['session_cap'];
                    $cst = $db->prepare(
                        'SELECT COUNT(*) FROM teacher_class_session_entries WHERE term_id = :id'
                    );
                    $cst->execute([':id' => $termId]);
                    if ((int) $cst->fetchColumn() >= $cap) {
                        auth_send_json(['error' => 'This term already has the maximum number of sessions'], 400);
                    }
                    if ($mysqlAddAt !== null) {
                        $ins = $db->prepare(
                            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, term_id, recorded_at)
                             VALUES (:t, :s, :term, :at)'
                        );
                        $ins->execute([
                            ':t'    => $tid,
                            ':s'    => $studentId,
                            ':term' => $termId,
                            ':at'   => $mysqlAddAt,
                        ]);
                    } else {
                        $ins = $db->prepare(
                            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, term_id, recorded_at)
                             VALUES (:t, :s, :term, UTC_TIMESTAMP())'
                        );
                        $ins->execute([
                            ':t'    => $tid,
                            ':s'    => $studentId,
                            ':term' => $termId,
                        ]);
                    }
                    if (teacher_mark_term_unpaid_if_paid($db, $termId, $tid, $studentId)) {
                        $financialNotice = 'term_marked_unpaid';
                    }
                } else {
                    if ($mysqlAddAt !== null) {
                        $ins = $db->prepare(
                            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, recorded_at)
                             VALUES (:t, :s, :at)'
                        );
                        $ins->execute([':t' => $tid, ':s' => $studentId, ':at' => $mysqlAddAt]);
                    } else {
                        $ins = $db->prepare(
                            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, recorded_at)
                             VALUES (:t, :s, UTC_TIMESTAMP())'
                        );
                        $ins->execute([':t' => $tid, ':s' => $studentId]);
                    }
                }
            } catch (PDOException $e) {
                if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
                    || strpos($e->getMessage(), "doesn't exist") !== false) {
                    auth_send_json(['error' => 'Server not migrated: run teacher_class_session_entries.sql'], 500);
                }
                throw $e;
            }

            teacher_sessions_send_state_json($db, $tid, $studentId, $financialNotice);
            exit;
        }

        $noteOut = null;
        if (array_key_exists('note', $data)) {
            $rawNote = $data['note'];
            if ($rawNote === null) {
                $noteOut = null;
            } else {
                $noteOut = trim((string) $rawNote);
                if (strlen($noteOut) > 8000) {
                    auth_send_json(['error' => 'note is too long (max 8000 characters)'], 400);
                }
                if ($noteOut === '') {
                    $noteOut = null;
                }
            }
        } else {
            $existing = $db->prepare(
                'SELECT note FROM teacher_student_sessions WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
            );
            $existing->execute([':t' => $tid, ':s' => $studentId]);
            $er = $existing->fetch(PDO::FETCH_ASSOC);
            $noteOut = ($er !== false && isset($er['note']) && $er['note'] !== null && trim((string) $er['note']) !== '')
                ? (string) $er['note']
                : null;
        }

        if ($noteOnly || (array_key_exists('note', $data) && !array_key_exists('session_count', $data))) {
            $cntKeep = 0;
            $stc = $db->prepare(
                'SELECT session_count FROM teacher_student_sessions WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
            );
            $stc->execute([':t' => $tid, ':s' => $studentId]);
            $rc = $stc->fetch(PDO::FETCH_ASSOC);
            if ($rc !== false) {
                $cntKeep = (int) $rc['session_count'];
            }
            [$sessTmp, $tblOk] = teacher_class_sessions_list($db, $tid, $studentId);
            if ($tblOk && count($sessTmp) > 0) {
                $cntKeep = count($sessTmp);
            }

            $ins = $db->prepare(
                'INSERT INTO teacher_student_sessions (teacher_user_id, student_user_id, session_count, note)
                 VALUES (:t, :s, :c, :n)
                 ON DUPLICATE KEY UPDATE note = VALUES(note), updated_at = CURRENT_TIMESTAMP'
            );
            $ins->execute([
                ':t' => $tid,
                ':s' => $studentId,
                ':c' => $cntKeep,
                ':n' => $noteOut,
            ]);

            [$sessions, ] = teacher_class_sessions_list($db, $tid, $studentId);
            $st = $db->prepare(
                'SELECT session_count, updated_at, note FROM teacher_student_sessions
                 WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
            );
            $st->execute([':t' => $tid, ':s' => $studentId]);
            $row = $st->fetch(PDO::FETCH_ASSOC);

            $njson = null;
            if ($row !== false && isset($row['note']) && $row['note'] !== null && trim((string) $row['note']) !== '') {
                $njson = (string) $row['note'];
            }

            $payload = [
                'ok'            => true,
                'session_count' => $row !== false ? (int) $row['session_count'] : $cntKeep,
                'updated_at'    => $row !== false ? $row['updated_at'] : null,
                'note'          => $njson,
                'sessions'      => $sessions,
            ];
            if (teacher_student_terms_table_exists($db)) {
                $payload['terms'] = teacher_terms_list_json($db, $tid, $studentId);
            }
            teacher_append_financial_to_sessions_payload($db, $tid, $studentId, $payload);

            auth_send_json($payload, 200);
            exit;
        }

        $cnt = isset($data['session_count']) ? (int) $data['session_count'] : -1;
        if ($cnt < 0 || $cnt > 100000) {
            auth_send_json(['error' => 'session_count must be between 0 and 100000'], 400);
        }

        [$existingSessions, $tableOk] = teacher_class_sessions_list($db, $tid, $studentId);
        if ($tableOk && count($existingSessions) > 0) {
            auth_send_json(['error' => 'Use add_session to append sessions; legacy count is disabled once sessions exist.'], 400);
        }

        $ins = $db->prepare(
            'INSERT INTO teacher_student_sessions (teacher_user_id, student_user_id, session_count, note)
             VALUES (:t, :s, :c, :n)
             ON DUPLICATE KEY UPDATE session_count = VALUES(session_count), note = VALUES(note), updated_at = CURRENT_TIMESTAMP'
        );
        $ins->execute([
            ':t' => $tid,
            ':s' => $studentId,
            ':c' => $cnt,
            ':n' => $noteOut,
        ]);

        $st = $db->prepare(
            'SELECT session_count, updated_at, note FROM teacher_student_sessions
             WHERE teacher_user_id = :t AND student_user_id = :s LIMIT 1'
        );
        $st->execute([':t' => $tid, ':s' => $studentId]);
        $row = $st->fetch(PDO::FETCH_ASSOC);

        $noteJson = null;
        if ($row !== false && isset($row['note']) && $row['note'] !== null && trim((string) $row['note']) !== '') {
            $noteJson = (string) $row['note'];
        }

        $payload = [
            'ok'            => true,
            'session_count' => $row !== false ? (int) $row['session_count'] : $cnt,
            'updated_at'    => $row !== false ? $row['updated_at'] : null,
            'note'          => $noteJson,
            'sessions'      => [],
        ];
        if (teacher_student_terms_table_exists($db)) {
            $payload['terms'] = teacher_terms_list_json($db, $tid, $studentId);
        }

        auth_send_json($payload, 200);
    } else {
        auth_send_json(['error' => 'Method not allowed'], 405);
    }
} catch (PDOException $e) {
    if (strpos($e->getMessage(), 'teacher_student_sessions') !== false
        || strpos($e->getMessage(), 'Unknown column') !== false) {
        auth_send_json(['error' => 'Server not migrated: run teacher_panel_migration.sql or teacher_student_terms_migration.sql'], 500);
    }
    auth_send_json(['error' => 'Request failed'], 500);
} catch (Throwable $e) {
    auth_send_json(['error' => 'Request failed: ' . $e->getMessage()], 500);
}
