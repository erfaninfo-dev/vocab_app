-- Fixed tuition per term (not per session). Run once after teacher_student_terms exists.

ALTER TABLE teacher_student_terms
  ADD COLUMN term_fee DECIMAL(12, 2) NOT NULL DEFAULT 0
    COMMENT 'Fixed fee for this term (tuition)'
  AFTER session_cap;
