-- Adds updated_at so the app can detect PDF file changes even when pdf_url stays the same.
-- After replacing a PDF on the server, either:
--   UPDATE grammar_topic_pdfs SET updated_at = NOW() WHERE id = ...;
-- or any UPDATE on the row (ON UPDATE CURRENT_TIMESTAMP handles it automatically).

ALTER TABLE grammar_topic_pdfs
  ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    ON UPDATE CURRENT_TIMESTAMP
    AFTER created_at;
