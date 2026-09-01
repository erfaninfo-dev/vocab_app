-- Add final sample answer per question (built from model formula + template).
-- Run once on databases that already have speaking_questions without `answer`.
-- If the column already exists, skip this statement.

ALTER TABLE speaking_questions
  ADD COLUMN answer TEXT NOT NULL AFTER question_text;
