<?php
/**
 * GET /api/grammar_topic_pdfs.php
 *
 * Returns the educational PDF link attached to each Grammar topic, if any.
 * Grammar topics have no numeric id (they're a derived grouping of
 * `grammar_questions.topic`), so this is keyed by the topic name itself and
 * intentionally lives in its own small table/endpoint — it does not touch or
 * require changes to the existing grammar_topics.php.
 *
 * Response:
 * [
 *   { "topic": "Present Simple", "pdf_url": "https://.../pdfs/present-simple.pdf" },
 *   ...
 * ]
 *
 * A topic with no row in `grammar_topic_pdfs` simply won't appear in the
 * response — the Flutter client treats "missing" the same as "no PDF".
 */

require_once __DIR__ . '/config.php';

try {
    $db = getDb();

    $stmt = $db->query(
        'SELECT topic, pdf_url
         FROM   grammar_topic_pdfs
         ORDER  BY topic ASC'
    );

    sendJson($stmt->fetchAll());
} catch (PDOException $e) {
    sendError('Failed to load grammar topic PDFs: ' . $e->getMessage(), 500);
}
