<?php
/**
 * GET /speaking_topics.php?part=1
 *
 * Returns active speaking topics with question counts.
 *
 * Response: JSON array
 * [
 *   { "id": 1, "title": "Work", "question_count": 4, "sort_order": 1 },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$part = isset($_GET['part']) ? (int) $_GET['part'] : 1;
if ($part < 1) {
    $part = 1;
}

$db = getDb();

$stmt = $db->prepare(
    'SELECT t.id,
            t.title,
            t.sort_order,
            COUNT(q.id) AS question_count
     FROM speaking_topics t
     LEFT JOIN speaking_questions q
       ON q.topic_id = t.id
      AND q.is_active = 1
     WHERE t.is_active = 1
       AND t.part = :part
     GROUP BY t.id, t.title, t.sort_order
     HAVING question_count > 0
     ORDER BY t.sort_order ASC, t.id ASC'
);
$stmt->execute(['part' => $part]);

$rows = [];
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $rows[] = [
        'id' => (int) $row['id'],
        'title' => (string) $row['title'],
        'question_count' => (int) $row['question_count'],
        'sort_order' => (int) $row['sort_order'],
    ];
}

sendJson($rows);
