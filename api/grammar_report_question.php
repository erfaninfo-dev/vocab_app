<?php
/**
 * POST /grammar_report_question.php
 *
 * JSON body:
 *   { "question_id": int, "report_type": string, "detail": string? }
 *
 * Loads the current row from `questions`, inserts into `reported_questions` with a full
 * snapshot (all question fields + fa/kur/eng explanations) plus report_type and user detail.
 */

require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Only POST is allowed', 405);
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);
if (!is_array($data)) {
    sendError('Invalid JSON body', 400);
}

$questionId = isset($data['question_id']) ? (int) $data['question_id'] : 0;
$reportType = isset($data['report_type']) ? trim((string) $data['report_type']) : '';
$detail = isset($data['detail']) ? trim((string) $data['detail']) : '';
if ($detail === '') {
    $detail = null;
} elseif (strlen($detail) > 2000) {
    sendError('detail is too long', 400);
}

if ($questionId <= 0) {
    sendError('question_id is required', 400);
}

$allowed = [
    'wrong_correct_answer',
    'typo_question',
    'typo_options',
    'bad_explanation',
    'unclear_question',
    'other',
];

if ($reportType === '' || !in_array($reportType, $allowed, true)) {
    sendError('invalid report_type', 400);
}

$db = getDb();

$sel = $db->prepare(
    'SELECT id,
            content,
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
     FROM   questions
     WHERE  id = :id
     LIMIT  1'
);
$sel->execute([':id' => $questionId]);
$row = $sel->fetch(PDO::FETCH_ASSOC);
if ($row === false) {
    sendError('question not found', 404);
}

$ins = $db->prepare(
    'INSERT INTO reported_questions (
        question_id,
        report_type,
        detail,
        content,
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
    ) VALUES (
        :qid,
        :rtype,
        :detail,
        :content,
        :qtext,
        :o1,
        :o2,
        :o3,
        :o4,
        :correct,
        :ord,
        :fa_ex,
        :kur_ex,
        :eng_ex
    )'
);

$ord = $row['order_num'];
$ins->execute([
    ':qid'      => $questionId,
    ':rtype'    => $reportType,
    ':detail'   => $detail,
    ':content'  => $row['content'],
    ':qtext'    => $row['question_text'],
    ':o1'       => $row['option1'],
    ':o2'       => $row['option2'],
    ':o3'       => $row['option3'],
    ':o4'       => $row['option4'],
    ':correct'  => $row['correct_answer'],
    ':ord'      => $ord !== null ? (int) $ord : null,
    ':fa_ex'    => $row['fa_explanation'],
    ':kur_ex'   => $row['kur_explanation'],
    ':eng_ex'   => $row['eng_explanation'],
]);

$newId = (int) $db->lastInsertId();

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
echo json_encode(['ok' => true, 'id' => $newId], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
exit;
