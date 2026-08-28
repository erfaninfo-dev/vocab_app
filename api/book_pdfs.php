<?php
/**
 * GET /book_pdfs.php
 *
 * Returns study PDFs attached to vocabulary books. A book may have multiple rows.
 *
 * Response:
 * [
 *   {
 *     "id": 1,
 *     "book_id": 1,
 *     "title": "Introduction",
 *     "pdf_url": "https://.../uploads/pdf/fin-intro.pdf",
 *     "sort_order": 1,
 *     "updated_at": "2026-01-15 12:00:00"
 *   },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

try {
    $db = getDb();

    $hasTitle = false;
    $hasSortOrder = false;
    $hasUpdatedAt = false;
    try {
        $colStmt = $db->query(
            "SELECT COLUMN_NAME
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
             AND TABLE_NAME = 'book_pdfs'
             AND COLUMN_NAME IN ('title', 'sort_order', 'updated_at')"
        );
        foreach ($colStmt->fetchAll(PDO::FETCH_ASSOC) as $colRow) {
            if ($colRow['COLUMN_NAME'] === 'title') {
                $hasTitle = true;
            }
            if ($colRow['COLUMN_NAME'] === 'sort_order') {
                $hasSortOrder = true;
            }
            if ($colRow['COLUMN_NAME'] === 'updated_at') {
                $hasUpdatedAt = true;
            }
        }
    } catch (Throwable $e) {
        $hasTitle = false;
        $hasSortOrder = false;
        $hasUpdatedAt = false;
    }

    $titleSelect = $hasTitle ? 'title' : "'' AS title";
    $sortSelect = $hasSortOrder ? 'sort_order' : '1 AS sort_order';
    $updatedAtSelect = $hasUpdatedAt ? 'updated_at' : 'NULL AS updated_at';
    $orderBy = $hasSortOrder
        ? 'book_id ASC, sort_order ASC, id ASC'
        : 'book_id ASC, id ASC';

    $stmt = $db->query(
        "SELECT id, book_id, $titleSelect, pdf_url, $sortSelect, $updatedAtSelect
         FROM   book_pdfs
         ORDER  BY $orderBy"
    );

    $out = [];
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $out[] = [
            'id'         => (int) ($row['id'] ?? 0),
            'book_id'    => (int) ($row['book_id'] ?? 0),
            'title'      => (string) ($row['title'] ?? ''),
            'pdf_url'    => (string) ($row['pdf_url'] ?? ''),
            'sort_order' => (int) ($row['sort_order'] ?? 1),
            'updated_at' => $row['updated_at'] ?? null,
        ];
    }

    sendJson($out);
} catch (PDOException $e) {
    sendError('Failed to load book PDFs: ' . $e->getMessage(), 500);
}
