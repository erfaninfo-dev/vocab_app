-- If you already created `reported_questions` with the old schema (only question_id, report_type, detail),
-- run this once to add snapshot columns. Safe to run if columns already exist only if you remove duplicates manually.

ALTER TABLE reported_questions
  ADD COLUMN content MEDIUMTEXT NULL COMMENT 'Grammar topic name' AFTER created_at,
  ADD COLUMN question_text MEDIUMTEXT NULL AFTER content,
  ADD COLUMN option1 VARCHAR(255) NULL AFTER question_text,
  ADD COLUMN option2 VARCHAR(255) NULL AFTER option1,
  ADD COLUMN option3 VARCHAR(255) NULL AFTER option2,
  ADD COLUMN option4 VARCHAR(255) NULL AFTER option3,
  ADD COLUMN correct_answer VARCHAR(10) NULL COMMENT 'option1 .. option4' AFTER option4,
  ADD COLUMN order_num INT NULL AFTER correct_answer,
  ADD COLUMN fa_explanation TEXT NULL AFTER order_num,
  ADD COLUMN kur_explanation TEXT NULL AFTER fa_explanation,
  ADD COLUMN eng_explanation TEXT NULL AFTER kur_explanation;
