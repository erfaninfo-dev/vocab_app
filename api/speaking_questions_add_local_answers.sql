-- Add Persian and Kurdish translations for sample answers.
-- Run once on databases that already have speaking_questions.
-- If a column already exists, skip that specific statement.

ALTER TABLE speaking_questions
  ADD COLUMN fa_answer TEXT NOT NULL DEFAULT '' AFTER answer;

ALTER TABLE speaking_questions
  ADD COLUMN kur_answer TEXT NOT NULL DEFAULT '' AFTER fa_answer;
