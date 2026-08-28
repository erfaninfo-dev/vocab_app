-- Run once after teacher_student_terms_add_is_paid.sql (or alongside is_paid column).
-- Records when a term was marked paid for financial period filters.

ALTER TABLE teacher_student_terms
  ADD COLUMN paid_at DATETIME NULL DEFAULT NULL
    COMMENT 'When is_paid was set to 1'
  AFTER is_paid;
