-- Optional: create from scratch. If you already use a `questions` table with the same columns, skip this.
-- Column `content` = grammar topic name (e.g. "Present Simple"). Compatible with MySQL 8+.

CREATE TABLE IF NOT EXISTS questions (
  id              INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  content         MEDIUMTEXT NULL COMMENT 'Grammar topic name',
  question_text   MEDIUMTEXT NULL,
  option1         VARCHAR(255) NULL,
  option2         VARCHAR(255) NULL,
  option3         VARCHAR(255) NULL,
  option4         VARCHAR(255) NULL,
  correct_answer  VARCHAR(10) NULL COMMENT 'option1 .. option4',
  order_num       INT NULL,
  fa_explanation  TEXT NULL,
  kur_explanation TEXT NULL,
  eng_explanation TEXT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
