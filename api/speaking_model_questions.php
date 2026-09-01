<?php
/**
 * GET /speaking_model_questions.php?part=1
 *
 * Returns active model questions used in Part 1 with question counts.
 *
 * Response: JSON array
 * [
 *   {
 *     "id": 3,
 *     "model_number": 43,
 *     "title": "How do you feel when + sentence?",
 *     "formula": "...",
 *     "template": "...",
 *     "question_count": 5
 *   },
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
    'SELECT m.id,
            m.model_number,
            m.title,
            m.formula,
            m.template,
            COUNT(q.id) AS question_count
     FROM speaking_model_questions m
     INNER JOIN speaking_questions q ON q.model_id = m.id AND q.is_active = 1
     INNER JOIN speaking_topics t ON t.id = q.topic_id AND t.is_active = 1
     WHERE t.part = :part
     GROUP BY m.id, m.model_number, m.title, m.formula, m.template
     HAVING question_count > 0
     ORDER BY m.model_number ASC, m.id ASC'
);
$stmt->execute(['part' => $part]);

$rows = [];
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $rows[] = [
        'id' => (int) $row['id'],
        'model_number' => (int) $row['model_number'],
        'title' => (string) $row['title'],
        'formula' => (string) $row['formula'],
        'template' => (string) $row['template'],
        'question_count' => (int) $row['question_count'],
    ];
}

sendJson($rows);
