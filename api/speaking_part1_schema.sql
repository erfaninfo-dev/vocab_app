-- IELTS Speaking Part 1 — topics, model questions, questions.
-- Run once before deploying speaking_topics.php / speaking_questions.php.

CREATE TABLE IF NOT EXISTS speaking_topics (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  part TINYINT UNSIGNED NOT NULL DEFAULT 1,
  title VARCHAR(180) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_speaking_topic_part_title (part, title),
  INDEX idx_speaking_topics_part_sort (part, is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS speaking_model_questions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  model_number INT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  formula TEXT NOT NULL,
  template MEDIUMTEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_speaking_model_number (model_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS speaking_questions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  topic_id INT UNSIGNED NOT NULL,
  model_id INT UNSIGNED NOT NULL,
  question_text TEXT NOT NULL,
  answer TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_speaking_questions_topic_sort (topic_id, is_active, sort_order),
  INDEX idx_speaking_questions_model (model_id),
  CONSTRAINT fk_speaking_q_topic
    FOREIGN KEY (topic_id) REFERENCES speaking_topics(id)
    ON DELETE RESTRICT,
  CONSTRAINT fk_speaking_q_model
    FOREIGN KEY (model_id) REFERENCES speaking_model_questions(id)
    ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
