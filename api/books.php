<?php
/**
 * GET /api/books.php
 *
 * Returns the list of all books ordered by `order` then title.
 * (DB column is named `order`; JSON still uses "sort_order" for the app.)
 */

require_once __DIR__ . '/config.php';

try {
    $db = getDb();
    $stmt = $db->query(
        'SELECT id, title, description, `order`
         FROM   books
         ORDER  BY `order` ASC, title ASC'
    );

    $books = array_map(function (array $row): array {
        return [
            'id'          => (int) $row['id'],
            'title'       => $row['title'],
            'description' => $row['description'],
            'sort_order'  => (int) $row['order'],
        ];
    }, $stmt->fetchAll());

    sendJson($books);
} catch (PDOException $e) {
    sendError('Failed to load books: ' . $e->getMessage(), 500);
}
