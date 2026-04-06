<?php
/**
 * GET /api/units.php?book_id={id}
 *
 * Returns the distinct unit numbers and their details for a book, sorted ascending.
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

$db   = getDb();
$stmt = $db->prepare(
    'SELECT unit, MAX(NULLIF(TRIM(unit_details), \'\')) AS unit_details
     FROM   words
     WHERE  book_id = ?
     GROUP  BY unit
     ORDER  BY unit ASC'
);
$stmt->execute([$bookId]);

$units = array_map(
    fn(array $row): array => [
        'unit'         => (int) $row['unit'],
        'unit_details' => $row['unit_details'] ?? null,
    ],
    $stmt->fetchAll()
);

sendJson(array_values($units));
