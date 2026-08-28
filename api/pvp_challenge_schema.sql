-- Word Builder PvP Challenge (MVP) — run once on MySQL.
-- Requires: users, game_word_categories, game_category_words tables.

CREATE TABLE IF NOT EXISTS pvp_matches (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  challenger_id     INT UNSIGNED NOT NULL,
  opponent_id       INT UNSIGNED NOT NULL,
  category_id       INT UNSIGNED NOT NULL,
  letter_seed       INT NOT NULL,
  anchor_words_json JSON NOT NULL,
  letters_json      JSON NOT NULL,
  duration_sec      SMALLINT UNSIGNED NOT NULL DEFAULT 60,
  status            ENUM('pending','accepted','completed','declined','expired','cancelled') NOT NULL DEFAULT 'pending',
  winner_id         INT UNSIGNED NULL,
  is_draw           TINYINT(1) NOT NULL DEFAULT 0,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  accepted_at       DATETIME NULL,
  expires_at        DATETIME NOT NULL,
  completed_at      DATETIME NULL,
  INDEX idx_opponent_status (opponent_id, status),
  INDEX idx_challenger_status (challenger_id, status),
  INDEX idx_status_expires (status, expires_at),
  CONSTRAINT fk_pvp_challenger FOREIGN KEY (challenger_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_pvp_opponent   FOREIGN KEY (opponent_id)   REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT fk_pvp_category   FOREIGN KEY (category_id)   REFERENCES game_word_categories(id),
  CONSTRAINT fk_pvp_winner     FOREIGN KEY (winner_id)     REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pvp_match_players (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  match_id      INT UNSIGNED NOT NULL,
  user_id       INT UNSIGNED NOT NULL,
  turn_order    TINYINT UNSIGNED NOT NULL,
  player_status ENUM('waiting','playing','submitted','forfeited') NOT NULL DEFAULT 'waiting',
  score         INT UNSIGNED NOT NULL DEFAULT 0,
  words_json    JSON NULL,
  started_at    DATETIME NULL,
  completed_at  DATETIME NULL,
  UNIQUE KEY uq_match_user (match_id, user_id),
  INDEX idx_user_match (user_id, match_id),
  CONSTRAINT fk_pvp_mp_match FOREIGN KEY (match_id) REFERENCES pvp_matches(id) ON DELETE CASCADE,
  CONSTRAINT fk_pvp_mp_user  FOREIGN KEY (user_id)  REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
