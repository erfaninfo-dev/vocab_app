-- Telegram-style reactions on public grammar result cards.
-- Run once before deploying grammar_result_reactions.php

CREATE TABLE IF NOT EXISTS grammar_result_reactions (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  result_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  emoji VARCHAR(16) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grammar_result_reactions_user (result_id, user_id),
  KEY idx_grammar_result_reactions_result (result_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
