<?php
/**
 * GET /api/sections.php?book_id={id}&unit={unit}
 *
 * Returns sections that have words or active unit_samples (section > 0), with
 * section_details from unit_samples first, then words.
 *
 * Response: JSON array
 * [
 *   { "section": 1, "section_details": "Reading skills" },
 *   ...
 * ]
 */
require_once __DIR__ . '/config.php';

$bookId = isset($_GET['book_id']) ? (int) $_GET['book_id'] : 0;
$unit = isset($_GET['unit']) ? (int) $_GET['unit'] : 0;

if ($bookId <= 0) {
    sendError('book_id is required and must be a positive integer.');
}
if ($unit <= 0) {
    sendError('unit is required and must be a positive integer.');
}

$db = getDb();

try {
    $stmt = $db->prepare(
        'SELECT s.section,
                COALESCE(MAX(s.sample_section_details), MAX(s.words_section_details)) AS section_details
         FROM (
             SELECT section,
                    NULL AS sample_section_details,
                    MAX(NULLIF(TRIM(section_details), \'\')) AS words_section_details
             FROM words
             WHERE book_id = ?
               AND unit = ?
               AND section IS NOT NULL
               AND section > 0
             GROUP BY section
             UNION ALL
             SELECT section,
                    MAX(NULLIF(TRIM(section_details), \'\')) AS sample_section_details,
                    NULL AS words_section_details
             FROM unit_samples
             WHERE book_id = ?
               AND unit = ?
               AND is_active = 1
               AND section IS NOT NULL
               AND section > 0
             GROUP BY section
         ) AS s
         GROUP BY s.section
         ORDER BY s.section ASC'
    );
    $stmt->execute([$bookId, $unit, $bookId, $unit]);
} catch (Exception $e) {
    try {
        $stmt = $db->prepare(
            'SELECT s.section, MAX(s.section_details) AS section_details
             FROM (
                 SELECT section,
                        MAX(NULLIF(TRIM(section_details), \'\')) AS section_details
                 FROM words
                 WHERE book_id = ?
                   AND unit = ?
                   AND section IS NOT NULL
                   AND section > 0
                 GROUP BY section
                 UNION ALL
                 SELECT section, NULL AS section_details
                 FROM unit_samples
                 WHERE book_id = ?
                   AND unit = ?
                   AND is_active = 1
                   AND section IS NOT NULL
                   AND section > 0
                 GROUP BY section
             ) AS s
             GROUP BY s.section
             ORDER BY s.section ASC'
        );
        $stmt->execute([$bookId, $unit, $bookId, $unit]);
    } catch (Exception $e2) {
        $stmt = $db->prepare(
            'SELECT section,
                    MAX(NULLIF(TRIM(section_details), \'\')) AS section_details
             FROM words
             WHERE book_id = ?
               AND unit = ?
               AND section IS NOT NULL
               AND section > 0
             GROUP BY section
             ORDER BY section ASC'
        );
        $stmt->execute([$bookId, $unit]);
    }
}

$out = [];
foreach ($stmt->fetchAll() as $row) {
    $details = $row['section_details'] ?? null;
    $out[] = [
        'section' => (int) $row['section'],
        'section_details' => $details !== null && $details !== ''
            ? $details
            : null,
    ];
}

sendJson($out);
