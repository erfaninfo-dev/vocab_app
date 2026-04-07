<?php
/**
 * GET /grammar_questions.php?topic={topic}
 *
 * topic: required — must match the value stored in column `content` (grammar topic name).
 *
 * Response: JSON array of questions ordered by order_num, id.
 */

require_once __DIR__ . '/config.php';

$topic = isset($_GET['topic']) ? trim((string) $_GET['topic']) : '';
if ($topic === '') {
    sendError('topic is required', 400);
}

$db = getDb();

// Table `questions`: same table as topics; filter by `content` = topic name.
$stmt = $db->prepare(
    'SELECT id,
            content AS topic,
            question_text,
            option1,
            option2,
            option3,
            option4,
            correct_answer,
            order_num,
            fa_explanation,
            kur_explanation,
            eng_explanation
     FROM   `questions`
     WHERE  content = :topic
     ORDER  BY order_num ASC, id ASC'
);
$stmt->execute([':topic' => $topic]);

$rows = $stmt->fetchAll();

$out = array_map(static function (array $row): array {
    return [
        'id'              => (int) $row['id'],
        'topic'           => $row['topic'],
        'question_text'   => $row['question_text'],
        'option1'         => $row['option1'],
        'option2'         => $row['option2'],
        'option3'         => $row['option3'],
        'option4'         => $row['option4'],
        'correct_answer'  => $row['correct_answer'],
        'order_num'       => $row['order_num'] !== null ? (int) $row['order_num'] : null,
        'fa_explanation'  => $row['fa_explanation'],
        'kur_explanation' => $row['kur_explanation'],
        'eng_explanation' => $row['eng_explanation'],
    ];
}, $rows);

sendJson($out);
