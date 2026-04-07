<?php
/**
 * GET /grammar_topics.php
 *
 * Returns distinct grammar topic names from column `content` (with question counts).
 *
 * Response: JSON array
 * [
 *   { "topic": "Present Simple", "question_count": 6 },
 *   ...
 * ]
 */

require_once __DIR__ . '/config.php';

$db = getDb();

// Table `questions`: grammar topics in `content`, one row per MCQ.
$stmt = $db->query(
    'SELECT content AS topic, COUNT(*) AS question_count
     FROM   `questions`
     WHERE  content IS NOT NULL
     AND    TRIM(content) <> \'\'
     GROUP  BY content
     ORDER  BY MIN(order_num) ASC, topic ASC'
);

$rows = $stmt->fetchAll();

$out = array_map(static function (array $row): array {
    return [
        'topic'          => $row['topic'],
        'question_count' => (int) $row['question_count'],
    ];
}, $rows);

sendJson($out);
