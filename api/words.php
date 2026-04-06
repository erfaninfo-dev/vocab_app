<?php
/**
 * GET /api/words.php
 *
 * Three usage modes:
 *
 *   1. /words.php?book_id={id}&unit={unit}&section={section}
 *      Words for a specific unit + section.
 *
 *   2. /words.php?book_id={id}&unit={unit}
 *      Words for a unit that has NO sections (section column is NULL).
 *
 *   3. /words.php?book_id={id}
 *      All words for a book (used by the Favorites screen to match
 *      locally-stored favourite IDs against live data).
 *
 * Response: JSON array of word objects whose keys match the DB columns:
 * [
 *   {
 *     "id": 1,
 *     "book_id": 1,
 *     "unit": 1,
 *     "section": null,
 *     "word": "accumulate",
 *     "type": "v",
 *     "meaning_en":  "to gather or collect",
 *     "meaning_fa":  "انباشتن",
 *     "meaning_kur": "کۆکردنەوە",
 *     "example_en":  "People accumulate wealth over time.",
 *     "example_fa":  "مردم با گذشت زمان ثروت جمع می‌کنند.",
 *     "example_kur": "مرۆڤەکان بە تێپەڕینی کات دەوڵەمەند دەبن."
 *   },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$bookId = isset($_GET['book_id']) ? (int) $_GET['book_id'] : 0;
if ($bookId <= 0) {
    sendError('book_id is required and must be a positive integer.');
}

$db = getDb();

$columns = 'id, book_id, unit, section, word, type,
            meaning_en, meaning_fa, meaning_kur,
            example_en, example_fa, example_kur';

if (isset($_GET['unit'])) {
    $unit = (int) $_GET['unit'];
    if ($unit <= 0) sendError('unit must be a positive integer.');

    if (isset($_GET['section'])) {
        // Mode 1: specific unit + section
        $section = (int) $_GET['section'];
        $stmt    = $db->prepare(
            "SELECT $columns
             FROM   words
             WHERE  book_id = ? AND unit = ? AND section = ?
             ORDER  BY id ASC"
        );
        $stmt->execute([$bookId, $unit, $section]);
    } else {
        // Mode 2: unit with no sections (section IS NULL)
        $stmt = $db->prepare(
            "SELECT $columns
             FROM   words
             WHERE  book_id = ? AND unit = ?
             ORDER  BY id ASC"
        );
        $stmt->execute([$bookId, $unit]);
    }
} else {
    // Mode 3: all words for the book
    $stmt = $db->prepare(
        "SELECT $columns
         FROM   words
         WHERE  book_id = ?
         ORDER  BY unit ASC, section ASC, id ASC"
    );
    $stmt->execute([$bookId]);
}

$rows = $stmt->fetchAll();

$result = array_map(function (array $r): array {
    return [
        'id'          => (int) $r['id'],
        'book_id'     => (int) $r['book_id'],
        'unit'        => (int) $r['unit'],
        'section'     => $r['section'] !== null ? (int) $r['section'] : null,
        'word'        => $r['word']         ?? '',
        'type'        => $r['type']         ?? '',
        'meaning_en'  => $r['meaning_en']   ?? '',
        'meaning_fa'  => $r['meaning_fa']   ?? '',
        'meaning_kur' => $r['meaning_kur']  ?? '',
        'example_en'  => $r['example_en']   ?? '',
        'example_fa'  => $r['example_fa']   ?? '',
        'example_kur' => $r['example_kur']  ?? '',
    ];
}, $rows);

sendJson(array_values($result));
