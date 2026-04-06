<?php
/**
 * GET /api/books.php
 *
 * Returns the list of all books ordered by sort_order then title.
 *
 * Response: JSON array
 * [
 *   { "id": 1, "title": "IELTS Essential Words", "description": null, "sort_order": 1 },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$db   = getDb();
$stmt = $db->query(
    'SELECT id, title, description, sort_order
     FROM   books
     ORDER  BY sort_order ASC, title ASC'
);

$books = array_map(function (array $row): array {
    return [
        'id'          => (int) $row['id'],
        'title'       => $row['title'],
        'description' => $row['description'],
        'sort_order'  => (int) $row['sort_order'],
    ];
}, $stmt->fetchAll());

sendJson($books);
