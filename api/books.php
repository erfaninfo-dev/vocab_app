<?php
/**
 * GET /api/books.php[?search=][&scope=public|student]
 *
 * scope=public (default): books visible in the main catalog (is_public on book or series).
 * scope=student: requires Authorization; user must have student_access OR be a teacher; returns student-only books.
 *
 * Falls back to legacy shape if DB not migrated.
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/auth_helpers.php';

/**
 * @param PDO    $db
 * @param string $table
 * @param string $column
 */
function api_table_has_column($db, $table, $column)
{
    static $cache = [];
    $key = $table . '.' . $column;
    if (isset($cache[$key])) {
        return $cache[$key];
    }
    $stmt = $db->prepare(
        'SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = :t AND COLUMN_NAME = :c'
    );
    $stmt->execute([':t' => $table, ':c' => $column]);
    $cache[$key] = ((int) $stmt->fetchColumn()) > 0;

    return $cache[$key];
}

function books_map_row(array $row, bool $extended, bool $withVisibility): array
{
    $out = [
        'id'          => (int) $row['id'],
        'title'       => $row['title'],
        'description' => $row['description'],
        'sort_order'  => (int) $row['order'],
    ];
    if ($withVisibility) {
        $out['is_public'] = isset($row['is_public']) ? ((int) $row['is_public'] === 1) : true;
        $out['is_student'] = isset($row['is_student']) ? ((int) $row['is_student'] === 1) : false;
    }
    if ($extended) {
        $out['track'] = isset($row['track']) ? (string) $row['track'] : 'ielts';
        $out['series_id'] = isset($row['series_id']) && $row['series_id'] !== null
            ? (int) $row['series_id'] : null;
        $out['volume_order'] = isset($row['volume_order']) ? (int) $row['volume_order'] : 0;
        $out['series_title'] = isset($row['series_title']) ? $row['series_title'] : null;
        $out['series_sort_order'] = isset($row['series_sort_order'])
            ? (int) $row['series_sort_order'] : 999999;
    } else {
        $out['track'] = 'ielts';
        $out['series_id'] = null;
        $out['volume_order'] = 0;
        $out['series_title'] = null;
        $out['series_sort_order'] = 999999;
        if ($withVisibility) {
            $out['is_public'] = true;
            $out['is_student'] = false;
        }
    }

    return $out;
}

try {
    $db = getDb();
    $search = isset($_GET['search']) ? trim((string) $_GET['search']) : '';
    $scope = isset($_GET['scope']) ? strtolower(trim((string) $_GET['scope'])) : 'public';
    if ($scope !== 'public' && $scope !== 'student') {
        $scope = 'public';
    }

    $hasBookFlags = api_table_has_column($db, 'books', 'is_public')
        && api_table_has_column($db, 'books', 'is_student');
    $hasSeriesFlags = api_table_has_column($db, 'book_series', 'is_public')
        && api_table_has_column($db, 'book_series', 'is_student');

    if ($scope === 'student') {
        $rawTok = auth_bearer_token();
        if ($rawTok === null || $rawTok === '') {
            sendError('Authorization required', 401);
        }
        $u = auth_user_from_token($db, $rawTok);
        if ($u === null) {
            sendError('Invalid or expired token', 401);
        }
        $isTeacher = isset($u['is_teacher']) && (int) $u['is_teacher'] === 1;
        $isAdmin = isset($u['is_admin']) && (int) $u['is_admin'] === 1;
        $hasStudentAccess = !empty($u['student_access'])
            && (int) $u['student_access'] === 1;
        if (!$hasStudentAccess && !$isTeacher && !$isAdmin) {
            sendError('Student, teacher, or admin access required', 403);
        }
    }

    $visibilitySql = '';
    if ($hasBookFlags && $hasSeriesFlags) {
        if ($scope === 'public') {
            $visibilitySql = ' AND (b.is_public = 1 OR (b.series_id IS NOT NULL AND s.is_public = 1))';
        } else {
            $visibilitySql = ' AND (b.is_student = 1 OR (b.series_id IS NOT NULL AND s.is_student = 1))';
        }
    } elseif ($hasBookFlags) {
        if ($scope === 'public') {
            $visibilitySql = ' AND b.is_public = 1';
        } else {
            $visibilitySql = ' AND b.is_student = 1';
        }
    }

    $extendedSql = 'SELECT b.id, b.title, b.description, b.`order`';
    if ($hasBookFlags) {
        $extendedSql .= ', b.is_public, b.is_student';
    }
    $extendedSql .= ',
        b.track, b.series_id, b.volume_order,
        s.title AS series_title,
        IFNULL(s.sort_order, 999999) AS series_sort_order
        FROM books b
        LEFT JOIN book_series s ON s.id = b.series_id';

    $basicSql = 'SELECT id, title, description, `order`';
    if ($hasBookFlags) {
        $basicSql .= ', is_public, is_student';
    }
    $basicSql .= ' FROM books';

    if ($search !== '') {
        $extendedSql .= ' WHERE (b.title LIKE :q OR b.description LIKE :q)' . $visibilitySql;
        $basicSql .= ' WHERE (title LIKE :q OR description LIKE :q)' . ($hasBookFlags && $scope === 'public' ? ' AND is_public = 1' : ($hasBookFlags && $scope === 'student' ? ' AND is_student = 1' : ''));
    } else {
        $extendedSql .= ' WHERE 1=1' . $visibilitySql;
        $basicSql .= ' WHERE 1=1' . ($hasBookFlags && $scope === 'public' ? ' AND is_public = 1' : ($hasBookFlags && $scope === 'student' ? ' AND is_student = 1' : ''));
    }

    $extendedSql .= ' ORDER BY b.track ASC, series_sort_order ASC, b.volume_order ASC, b.`order` ASC, b.title ASC';
    $basicSql .= ' ORDER BY `order` ASC, title ASC';

    $extended = true;
    $withVisibility = $hasBookFlags;
    try {
        if ($search !== '') {
            $stmt = $db->prepare($extendedSql);
            $stmt->execute([':q' => '%' . $search . '%']);
        } else {
            $stmt = $db->query($extendedSql);
        }
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        $extended = false;
        $withVisibility = false;
        if ($search !== '') {
            $stmt = $db->prepare($basicSql);
            $stmt->execute([':q' => '%' . $search . '%']);
        } else {
            $stmt = $db->query($basicSql);
        }
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    $books = array_map(static function (array $row) use ($extended, $withVisibility): array {
        return books_map_row($row, $extended, $withVisibility);
    }, $rows);

    sendJson($books);
} catch (PDOException $e) {
    sendError('Failed to load books: ' . $e->getMessage(), 500);
}
