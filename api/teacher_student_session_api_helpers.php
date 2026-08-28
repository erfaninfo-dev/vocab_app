<?php

require_once __DIR__ . '/session_recorded_at.php';

function teacher_student_terms_table_exists(PDO $db)
{
    try {
        $db->query('SELECT 1 FROM teacher_student_terms LIMIT 1');

        return true;
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'teacher_student_terms') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            return false;
        }
        throw $e;
    }
}

function teacher_terms_renumber(PDO $db, $tid, $sid)
{
    $st = $db->prepare(
        'SELECT id FROM teacher_student_terms
         WHERE teacher_user_id = :t AND student_user_id = :s
         ORDER BY sort_order ASC, id ASC'
    );
    $st->execute([':t' => $tid, ':s' => $sid]);
    $ids = $st->fetchAll(PDO::FETCH_COLUMN);
    $ord = 1;
    $upd = $db->prepare(
        'UPDATE teacher_student_terms SET sort_order = :o
         WHERE id = :id AND teacher_user_id = :t AND student_user_id = :s'
    );
    foreach ($ids as $id) {
        $upd->execute([
            ':o'  => $ord,
            ':id' => (int) $id,
            ':t'  => $tid,
            ':s'  => $sid,
        ]);
        ++$ord;
    }
}

/**
 * @return list<array<string,mixed>>
 */
function teacher_terms_list_json(PDO $db, $tid, $sid, $sessionPrice = null, $enrichFinancial = true)
{
    $hasTermFee = function_exists('teacher_student_terms_has_term_fee')
        && teacher_student_terms_has_term_fee($db);
    $feeCol = $hasTermFee ? ', t.term_fee' : '';
    $sqlWithPaid = 'SELECT t.id, t.sort_order, t.session_cap, t.is_paid' . $feeCol . ',
         (SELECT COUNT(*) FROM teacher_class_session_entries e WHERE e.term_id = t.id) AS session_count
         FROM teacher_student_terms t
         WHERE t.teacher_user_id = :t AND t.student_user_id = :s
         ORDER BY t.sort_order DESC, t.id DESC';
    $sqlNoPaid = 'SELECT t.id, t.sort_order, t.session_cap' . $feeCol . ',
         (SELECT COUNT(*) FROM teacher_class_session_entries e WHERE e.term_id = t.id) AS session_count
         FROM teacher_student_terms t
         WHERE t.teacher_user_id = :t AND t.student_user_id = :s
         ORDER BY t.sort_order DESC, t.id DESC';

    try {
        $st = $db->prepare($sqlWithPaid);
        $st->execute([':t' => $tid, ':s' => $sid]);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Unknown column') !== false
            && strpos($e->getMessage(), 'is_paid') !== false) {
            $st = $db->prepare($sqlNoPaid);
            $st->execute([':t' => $tid, ':s' => $sid]);
            $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        } else {
            throw $e;
        }
    }

    $out = [];
    foreach ($rows as $r) {
        $paid = isset($r['is_paid']) ? ((int) $r['is_paid'] === 1) : false;
        $item = [
            'id'            => (int) $r['id'],
            'sort_order'    => (int) $r['sort_order'],
            'session_cap'   => (int) $r['session_cap'],
            'session_count' => (int) $r['session_count'],
            'is_paid'       => $paid,
        ];
        if ($hasTermFee) {
            $item['term_fee'] = round((float) ($r['term_fee'] ?? 0), 2);
        }
        $out[] = $item;
    }

    if ($enrichFinancial && function_exists('teacher_enrich_term_financial')) {
        for ($i = 0; $i < count($out); ++$i) {
            $out[$i] = teacher_enrich_term_financial($out[$i]);
        }
    }

    return $out;
}

function teacher_current_or_next_term_id_for_session(PDO $db, $tid, $sid)
{
    $latest = $db->prepare(
        'SELECT id, sort_order, session_cap
         FROM teacher_student_terms
         WHERE teacher_user_id = :t AND student_user_id = :s
         ORDER BY sort_order DESC, id DESC
         LIMIT 1'
    );
    $latest->execute([':t' => $tid, ':s' => $sid]);
    $row = $latest->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        $defaultFee = function_exists('teacher_default_term_fee_for_student')
            ? teacher_default_term_fee_for_student($db, $tid, $sid)
            : 0.0;
        if (teacher_student_terms_has_term_fee($db)) {
            $ins = $db->prepare(
                'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap, term_fee)
                 VALUES (:t, :s, 1, 12, :f)'
            );
            $ins->execute([':t' => $tid, ':s' => $sid, ':f' => $defaultFee]);
        } else {
            $ins = $db->prepare(
                'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap)
                 VALUES (:t, :s, 1, 12)'
            );
            $ins->execute([':t' => $tid, ':s' => $sid]);
        }

        return (int) $db->lastInsertId();
    }

    $termId = (int) $row['id'];
    $cap = max(1, (int) $row['session_cap']);
    $cnt = $db->prepare(
        'SELECT COUNT(*) FROM teacher_class_session_entries WHERE term_id = :id'
    );
    $cnt->execute([':id' => $termId]);
    if ((int) $cnt->fetchColumn() < $cap) {
        return $termId;
    }

    $nextOrder = ((int) $row['sort_order']) + 1;
    $defaultFee = teacher_default_term_fee_for_student($db, $tid, $sid);
    if (teacher_student_terms_has_term_fee($db)) {
        $ins = $db->prepare(
            'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap, term_fee)
             VALUES (:t, :s, :o, :c, :f)'
        );
        $ins->execute([
            ':t' => $tid,
            ':s' => $sid,
            ':o' => $nextOrder,
            ':c' => $cap,
            ':f' => $defaultFee,
        ]);
    } else {
        $ins = $db->prepare(
            'INSERT INTO teacher_student_terms (teacher_user_id, student_user_id, sort_order, session_cap)
             VALUES (:t, :s, :o, :c)'
        );
        $ins->execute([
            ':t' => $tid,
            ':s' => $sid,
            ':o' => $nextOrder,
            ':c' => $cap,
        ]);
    }

    return (int) $db->lastInsertId();
}

function teacher_class_session_entries_has_group_id(PDO $db)
{
    try {
        $db->query('SELECT group_id FROM teacher_class_session_entries LIMIT 1');

        return true;
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'Unknown column') !== false
            && strpos($e->getMessage(), 'group_id') !== false) {
            return false;
        }
        if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            return false;
        }
        throw $e;
    }
}

function teacher_add_class_session_current_or_next_term(
    PDO $db,
    $tid,
    $sid,
    $recordedAtMysql,
    $groupId = null
) {
    $hasGroupCol = teacher_class_session_entries_has_group_id($db);
    $groupVal = ($hasGroupCol && $groupId !== null && (int) $groupId > 0) ? (int) $groupId : null;

    if (teacher_student_terms_table_exists($db)) {
        $termId = teacher_current_or_next_term_id_for_session($db, $tid, $sid);
        if ($hasGroupCol) {
            $ins = $db->prepare(
                'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, term_id, group_id, recorded_at)
                 VALUES (:t, :s, :term, :g, :at)'
            );
            $ins->execute([
                ':t'    => $tid,
                ':s'    => $sid,
                ':term' => $termId,
                ':g'    => $groupVal,
                ':at'   => $recordedAtMysql,
            ]);
        } else {
            $ins = $db->prepare(
                'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, term_id, recorded_at)
                 VALUES (:t, :s, :term, :at)'
            );
            $ins->execute([
                ':t'    => $tid,
                ':s'    => $sid,
                ':term' => $termId,
                ':at'   => $recordedAtMysql,
            ]);
        }
        $sessionId = (int) $db->lastInsertId();
        if (function_exists('teacher_mark_term_unpaid_if_paid')) {
            teacher_mark_term_unpaid_if_paid($db, $termId, $tid, $sid);
        }

        return $sessionId;
    }

    if ($hasGroupCol) {
        $ins = $db->prepare(
            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, group_id, recorded_at)
             VALUES (:t, :s, :g, :at)'
        );
        $ins->execute([
            ':t' => $tid,
            ':s' => $sid,
            ':g' => $groupVal,
            ':at' => $recordedAtMysql,
        ]);
    } else {
        $ins = $db->prepare(
            'INSERT INTO teacher_class_session_entries (teacher_user_id, student_user_id, recorded_at)
             VALUES (:t, :s, :at)'
        );
        $ins->execute([':t' => $tid, ':s' => $sid, ':at' => $recordedAtMysql]);
    }

    return (int) $db->lastInsertId();
}

/**
 * @return array{0: array<int, array<string,mixed>>, 1: bool} [sessions, table_ok]
 */
function teacher_class_sessions_list(PDO $db, $tid, $sid)
{
    try {
        $useTerms = teacher_student_terms_table_exists($db);
        $hasGroupCol = teacher_class_session_entries_has_group_id($db);
        $groupCol = $hasGroupCol ? ', e.group_id' : '';
        if ($useTerms) {
            $st = $db->prepare(
                'SELECT e.id, e.recorded_at, e.term_id' . $groupCol . '
                 FROM teacher_class_session_entries e
                 INNER JOIN teacher_student_terms t ON t.id = e.term_id
                   AND t.teacher_user_id = e.teacher_user_id AND t.student_user_id = e.student_user_id
                 WHERE e.teacher_user_id = :t AND e.student_user_id = :s
                 ORDER BY t.sort_order DESC, t.id DESC, e.recorded_at ASC, e.id ASC'
            );
        } else {
            $st = $db->prepare(
                'SELECT id, recorded_at' . ($hasGroupCol ? ', group_id' : '') . '
                 FROM teacher_class_session_entries
                 WHERE teacher_user_id = :t AND student_user_id = :s
                 ORDER BY id ASC'
            );
        }
        $st->execute([':t' => $tid, ':s' => $sid]);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        $out = [];
        $idx = 1;
        $curTerm = null;
        $idxInTerm = 0;
        foreach ($rows as $r) {
            $iso = session_recorded_at_mysql_utc_to_api_iso($r['recorded_at'] ?? null);
            if ($useTerms) {
                $termRowId = (int) $r['term_id'];
                if ($curTerm !== $termRowId) {
                    $curTerm = $termRowId;
                    $idxInTerm = 1;
                } else {
                    ++$idxInTerm;
                }
                $out[] = [
                    'id'           => (int) $r['id'],
                    'term_id'      => $termRowId,
                    'index'        => $idxInTerm,
                    'recorded_at'  => $iso,
                ];
                if ($hasGroupCol) {
                    $out[count($out) - 1]['group_id'] = isset($r['group_id']) && $r['group_id'] !== null
                        ? (int) $r['group_id']
                        : null;
                }
            } else {
                $row = [
                    'id'           => (int) $r['id'],
                    'index'        => $idx,
                    'recorded_at'  => $iso,
                ];
                if ($hasGroupCol) {
                    $row['group_id'] = isset($r['group_id']) && $r['group_id'] !== null
                        ? (int) $r['group_id']
                        : null;
                }
                $out[] = $row;
                ++$idx;
            }
        }

        return [$out, true];
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            return [[], false];
        }
        if (strpos($e->getMessage(), 'Unknown column') !== false
            && strpos($e->getMessage(), 'term_id') !== false) {
            return teacher_class_sessions_list_legacy_no_term_id($db, $tid, $sid);
        }
        throw $e;
    }
}

/**
 * @return array{0: array<int, array<string,mixed>>, 1: bool}
 */
function teacher_class_sessions_list_legacy_no_term_id(PDO $db, $tid, $sid)
{
    try {
        $st = $db->prepare(
            'SELECT id, recorded_at FROM teacher_class_session_entries
             WHERE teacher_user_id = :t AND student_user_id = :s
             ORDER BY id ASC'
        );
        $st->execute([':t' => $tid, ':s' => $sid]);
        $rows = $st->fetchAll(PDO::FETCH_ASSOC);
        $out = [];
        $idx = 1;
        foreach ($rows as $r) {
            $out[] = [
                'id'           => (int) $r['id'],
                'index'        => $idx,
                'recorded_at'  => session_recorded_at_mysql_utc_to_api_iso($r['recorded_at'] ?? null),
            ];
            ++$idx;
        }

        return [$out, true];
    } catch (PDOException $e) {
        if (strpos($e->getMessage(), 'teacher_class_session_entries') !== false
            || strpos($e->getMessage(), "doesn't exist") !== false) {
            return [[], false];
        }
        throw $e;
    }
}
