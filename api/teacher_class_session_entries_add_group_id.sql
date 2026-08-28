-- Links a session row to a teacher group class when logged via add_group_session.
-- NULL group_id = personal / one-on-one class session.

ALTER TABLE teacher_class_session_entries
  ADD COLUMN group_id INT UNSIGNED NULL DEFAULT NULL AFTER term_id,
  ADD KEY idx_group_id (group_id);

-- Optional FK when teacher_class_groups exists (ignore error if groups table missing).
-- ALTER TABLE teacher_class_session_entries
--   ADD CONSTRAINT fk_session_group FOREIGN KEY (group_id)
--     REFERENCES teacher_class_groups (id) ON DELETE SET NULL;
