<?php
/**
 * GET /api/sections.php?book_id={id}&unit={unit}
 *
 * Returns the distinct section numbers for a book+unit combination.
 * Rows where the `section` column is NULL are excluded — they represent
 * words that belong to a unit with no sections at all.
 *
 * If no sections exist the response is an empty array [].
 * The Flutter app uses an empty response to skip the Sections page and
 * navigate directly to the Words page for that unit.
 *
 * Response: JSON array
 * [
 *   { "section": 1 },
 *   { "section": 2 },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$bookId = isset($_GET['book_id']) ? (int) $_GET['book_id'] : 0;
$unit   = isset($_GET['unit'])    ? (int) $_GET['unit']    : 0;

if ($bookId <= 0) sendError('book_id is required and must be a positive integer.');
if ($unit   <= 0) sendError('unit is required and must be a positive integer.');

$db   = getDb();
$stmt = $db->prepare(
    'SELECT DISTINCT section
     FROM   words
     WHERE  book_id = ?
       AND  unit    = ?
       AND  section IS NOT NULL
     ORDER  BY section ASC'
);
$stmt->execute([$bookId, $unit]);

$sections = array_map(
    fn(array $row): array => ['section' => (int) $row['section']],
    $stmt->fetchAll()
);

sendJson(array_values($sections));
