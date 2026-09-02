<?php
/**
 * GET /speaking_questions.php?topic_id={id}
 * GET /speaking_questions.php?model_id={id}
 *
 * Returns questions for one topic OR one model question (with metadata).
 */

require_once __DIR__ . '/config.php';

$topicId = isset($_GET['topic_id']) ? (int) $_GET['topic_id'] : 0;
$modelId = isset($_GET['model_id']) ? (int) $_GET['model_id'] : 0;

if ($topicId <= 0 && $modelId <= 0) {
    sendError('topic_id or model_id is required', 400);
}
if ($topicId > 0 && $modelId > 0) {
    sendError('Provide only one of topic_id or model_id', 400);
}

$db = getDb();

function speakingQuestionRow(array $row): array
{
    return [
        'id' => (int) $row['id'],
        'question_text' => (string) $row['question_text'],
        'answer' => (string) $row['answer'],
        'fa_answer' => (string) ($row['fa_answer'] ?? ''),
        'kur_answer' => (string) ($row['kur_answer'] ?? ''),
        'sort_order' => (int) $row['sort_order'],
        'topic' => [
            'id' => (int) $row['topic_id'],
            'title' => (string) $row['topic_title'],
        ],
        'model' => [
            'id' => (int) $row['model_id'],
            'model_number' => (int) $row['model_number'],
            'title' => (string) $row['model_title'],
            'formula' => (string) $row['model_formula'],
            'template' => (string) $row['model_template'],
        ],
    ];
}

if ($topicId > 0) {
    $topicStmt = $db->prepare(
        'SELECT id, title
         FROM speaking_topics
         WHERE id = :id
           AND is_active = 1
         LIMIT 1'
    );
    $topicStmt->execute(['id' => $topicId]);
    $topicRow = $topicStmt->fetch(PDO::FETCH_ASSOC);
    if (!$topicRow) {
        sendError('Topic not found', 404);
    }

    $qStmt = $db->prepare(
        'SELECT q.id,
                q.question_text,
                q.answer,
                q.fa_answer,
                q.kur_answer,
                q.sort_order,
                t.id AS topic_id,
                t.title AS topic_title,
                m.id AS model_id,
                m.model_number,
                m.title AS model_title,
                m.formula AS model_formula,
                m.template AS model_template
         FROM speaking_questions q
         INNER JOIN speaking_topics t ON t.id = q.topic_id
         INNER JOIN speaking_model_questions m ON m.id = q.model_id
         WHERE q.topic_id = :topic_id
           AND q.is_active = 1
           AND t.is_active = 1
         ORDER BY q.sort_order ASC, q.id ASC'
    );
    $qStmt->execute(['topic_id' => $topicId]);

    $questions = [];
    foreach ($qStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
        $questions[] = speakingQuestionRow($row);
    }

    sendJson([
        'topic' => [
            'id' => (int) $topicRow['id'],
            'title' => (string) $topicRow['title'],
        ],
        'questions' => $questions,
    ]);
}

$modelStmt = $db->prepare(
    'SELECT id, model_number, title, formula, template
     FROM speaking_model_questions
     WHERE id = :id
     LIMIT 1'
);
$modelStmt->execute(['id' => $modelId]);
$modelRow = $modelStmt->fetch(PDO::FETCH_ASSOC);
if (!$modelRow) {
    sendError('Model question not found', 404);
}

$qStmt = $db->prepare(
    'SELECT q.id,
            q.question_text,
            q.answer,
            q.fa_answer,
            q.kur_answer,
            q.sort_order,
            t.id AS topic_id,
            t.title AS topic_title,
            m.id AS model_id,
            m.model_number,
            m.title AS model_title,
            m.formula AS model_formula,
            m.template AS model_template
     FROM speaking_questions q
     INNER JOIN speaking_topics t ON t.id = q.topic_id
     INNER JOIN speaking_model_questions m ON m.id = q.model_id
     WHERE q.model_id = :model_id
       AND q.is_active = 1
       AND t.is_active = 1
     ORDER BY t.sort_order ASC, t.id ASC, q.sort_order ASC, q.id ASC'
);
$qStmt->execute(['model_id' => $modelId]);

$questions = [];
foreach ($qStmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $questions[] = speakingQuestionRow($row);
}

sendJson([
    'model' => [
        'id' => (int) $modelRow['id'],
        'model_number' => (int) $modelRow['model_number'],
        'title' => (string) $modelRow['title'],
        'formula' => (string) $modelRow['formula'],
        'template' => (string) $modelRow['template'],
    ],
    'questions' => $questions,
]);
