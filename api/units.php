<?php
/**
 * GET /api/units.php?book_id={id}
 *
 * Returns distinct unit numbers for a book (from words and/or active unit_samples),
 * with unit_details from unit_samples first, then words, sorted ascending.
 *
 * Response: JSON array
 * [
 *   { "unit": 1, "unit_details": "Environment & Nature" },
 *   { "unit": 2, "unit_details": "Health & Medicine" },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$bookId = isset($_GET['book_id']) ? (int) $_GET['book_id'] : 0;
if ($bookId <= 0) {
    sendError('book_id is required and must be a positive integer.');
}

$db = getDb();

try {
    $stmt = $db->prepare(
        'SELECT u.unit,
                COALESCE(MAX(u.sample_unit_details), MAX(u.words_unit_details)) AS unit_details
         FROM (
             SELECT unit,
                    NULL AS sample_unit_details,
                    MAX(NULLIF(TRIM(unit_details), \'\')) AS words_unit_details
             FROM   words
             WHERE  book_id = ?
             GROUP  BY unit
             UNION ALL
             SELECT unit,
                    MAX(NULLIF(TRIM(unit_details), \'\')) AS sample_unit_details,
                    NULL AS words_unit_details
             FROM   unit_samples
             WHERE  book_id = ? AND is_active = 1
             GROUP  BY unit
         ) AS u
         GROUP BY u.unit
         ORDER BY u.unit ASC'
    );
    $stmt->execute([$bookId, $bookId]);
} catch (Exception $e) {
    try {
        $stmt = $db->prepare(
            'SELECT u.unit, MAX(u.unit_details) AS unit_details
             FROM (
                 SELECT unit,
                        MAX(NULLIF(TRIM(unit_details), \'\')) AS unit_details
                 FROM   words
                 WHERE  book_id = ?
                 GROUP  BY unit
                 UNION ALL
                 SELECT unit, NULL AS unit_details
                 FROM   unit_samples
                 WHERE  book_id = ? AND is_active = 1
                 GROUP  BY unit
             ) AS u
             GROUP BY u.unit
             ORDER BY u.unit ASC'
        );
        $stmt->execute([$bookId, $bookId]);
    } catch (Exception $e2) {
        $stmt = $db->prepare(
            'SELECT unit, MAX(NULLIF(TRIM(unit_details), \'\')) AS unit_details
             FROM   words
             WHERE  book_id = ?
             GROUP  BY unit
             ORDER  BY unit ASC'
        );
        $stmt->execute([$bookId]);
    }
}

$units = array_map(
    fn(array $row): array => [
        'unit'         => (int) $row['unit'],
        'unit_details' => $row['unit_details'] ?? null,
    ],
    $stmt->fetchAll()
);

sendJson(array_values($units));
