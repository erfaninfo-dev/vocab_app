-- MySQL 8+: named group classes (multi-student) for teacher panel.
-- Run once on the server, then deploy teacher_class_groups.php.

CREATE TABLE IF NOT EXISTS teacher_class_groups (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  teacher_user_id INT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  note VARCHAR(8000) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_teacher (teacher_user_id),
  KEY idx_teacher_name (teacher_user_id, name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS teacher_class_group_members (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  group_id INT UNSIGNED NOT NULL,
  student_user_id INT UNSIGNED NOT NULL,
  added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_group_student (group_id, student_user_id),
  KEY idx_student (student_user_id),
  CONSTRAINT fk_tcgm_group FOREIGN KEY (group_id)
    REFERENCES teacher_class_groups (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
