-- Snapshot of a grammar question at report time (same columns as `questions` plus report meta).
-- Run after `questions` exists (see grammar_questions_schema.sql).

CREATE TABLE IF NOT EXISTS reported_questions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  question_id INT UNSIGNED NOT NULL COMMENT 'Original questions.id at report time',
  report_type VARCHAR(32) NOT NULL,
  detail TEXT NULL COMMENT 'User note about the report',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

  -- Snapshot: mirrors `questions` row when the report was filed
  content MEDIUMTEXT NULL COMMENT 'Grammar topic name',
  question_text MEDIUMTEXT NULL,
  option1 VARCHAR(255) NULL,
  option2 VARCHAR(255) NULL,
  option3 VARCHAR(255) NULL,
  option4 VARCHAR(255) NULL,
  correct_answer VARCHAR(10) NULL COMMENT 'option1 .. option4',
  order_num INT NULL,
  fa_explanation TEXT NULL,
  kur_explanation TEXT NULL,
  eng_explanation TEXT NULL,

  KEY idx_reported_questions_question (question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Optional FK:
-- ALTER TABLE reported_questions
--   ADD CONSTRAINT fk_reported_questions_question
--   FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE SET NULL;
-- (Use ON DELETE SET NULL only if question_id is nullable; keep NOT NULL + CASCADE if preferred.)
