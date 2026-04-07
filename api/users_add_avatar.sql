-- Run once if `users` exists without `avatar` (existing installs).

ALTER TABLE users
  ADD COLUMN avatar VARCHAR(32) NULL DEFAULT 'm1' COMMENT 'preset id: m1-m4, f1-f4' AFTER display_name;

UPDATE users SET avatar = 'm1' WHERE avatar IS NULL OR avatar = '';
