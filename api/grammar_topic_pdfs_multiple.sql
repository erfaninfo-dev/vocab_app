-- One-time migration: allow multiple study PDFs per grammar topic.
-- Run after create_grammar_topic_pdfs_table.sql on databases that already
-- have the old UNIQUE(topic) constraint.

ALTER TABLE grammar_topic_pdfs
  DROP INDEX uq_grammar_topic_pdfs_topic;

ALTER TABLE grammar_topic_pdfs
  ADD COLUMN title VARCHAR(255) NOT NULL DEFAULT '' AFTER topic,
  ADD COLUMN sort_order INT UNSIGNED NOT NULL DEFAULT 1 AFTER pdf_url;

UPDATE grammar_topic_pdfs
SET title = topic
WHERE TRIM(title) = '';

CREATE INDEX idx_grammar_topic_pdfs_topic_sort
  ON grammar_topic_pdfs (topic, sort_order, id);

-- Example: two PDFs for the same topic
-- INSERT INTO grammar_topic_pdfs (topic, title, pdf_url, sort_order) VALUES
-- ('Present Simple', 'Introduction', 'https://example.com/pdfs/present-simple-1.pdf', 1),
-- ('Present Simple', 'Advanced rules', 'https://example.com/pdfs/present-simple-2.pdf', 2);
