-- =============================================================================
-- Study PDF attachments for vocabulary books (Home book cards).
-- Each book may have multiple PDF rows; order with sort_order.
--
-- After uploading PDFs to the server (e.g. uploads/pdf/):
--
--   INSERT INTO book_pdfs (book_id, title, pdf_url, sort_order) VALUES
--   (1, 'Introduction', 'https://erfaninfo.com/wordsapi/uploads/pdf/fin-intro.pdf', 1),
--   (1, 'Unit guide', 'https://erfaninfo.com/wordsapi/uploads/pdf/fin-guide.pdf', 2);
--
-- book_id must match books.id (integer).
-- =============================================================================

CREATE TABLE IF NOT EXISTS book_pdfs (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  book_id INT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL DEFAULT '',
  pdf_url VARCHAR(500) NOT NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_book_pdfs_book_sort (book_id, sort_order, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
