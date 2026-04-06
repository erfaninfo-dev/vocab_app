-- =============================================================================
-- کتاب جدید: Financial - Business
-- 4 یونیت × 30 لغت = 120 ردیف در جدول words
-- سازگار با API فعلی: section = NULL (بدون صفحهٔ سکشن)، unit_details برای لیست یونیت‌ها
--
-- اجرا روی MySQL 8+ (برای WITH RECURSIVE). قبل از اجرا از بک‌آپ بگیرید.
-- =============================================================================

-- اگر نمی‌خواهید عنوان تکراری شود، یک بار چک کنید:
-- SELECT id, title FROM books WHERE title = 'Financial - Business';

-- زیرکوئری اسکالر حتی برای جدول خالی یک مقدار برمی‌گرداند (sort_order = 1).
INSERT INTO books (title, description, sort_order)
VALUES (
  'Financial - Business',
  'Business and finance vocabulary',
  (SELECT IFNULL(MAX(sort_order), 0) + 1 FROM books AS b)
);

SET @book_id = LAST_INSERT_ID();

-- ---------------------------------------------------------------------------
-- 120 لغت نمونه (انگلیسی) — معنی/مثال‌ها خالی؛ بعداً در دیتابیس یا اسکریپت پر کنید.
-- نام لغات: financial_term_001 … financial_term_120
-- یونیت 1: n = 1..30   |  یونیت 2: 31..60  |  یونیت 3: 61..90  |  یونیت 4: 91..120
-- ---------------------------------------------------------------------------

-- ترتیب ستون‌ها مطابق جدول words در دیتابیس: book_id → unit → unit_details → section → … → page
INSERT INTO words (
  book_id,
  unit,
  unit_details,
  section,
  word,
  type,
  meaning_en,
  meaning_fa,
  meaning_kur,
  example_en,
  example_fa,
  example_kur,
  page
)
WITH RECURSIVE nums AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM nums WHERE n < 120
)
SELECT
  @book_id AS book_id,
  CEILING(n / 30) AS unit,
  CASE CEILING(n / 30)
    WHEN 1 THEN 'Unit 1 — Money & Banking'
    WHEN 2 THEN 'Unit 2 — Corporate & Strategy'
    WHEN 3 THEN 'Unit 3 — Markets & Investment'
    WHEN 4 THEN 'Unit 4 — Accounting & Reporting'
  END AS unit_details,
  NULL AS section,
  CONCAT('financial_term_', LPAD(n, 3, '0')) AS word,
  'n' AS type,
  '' AS meaning_en,
  '' AS meaning_fa,
  '' AS meaning_kur,
  '' AS example_en,
  '' AS example_fa,
  '' AS example_kur,
  NULL AS page
FROM nums;

-- بررسی سریع:
-- SELECT COUNT(*) FROM words WHERE book_id = @book_id;   -- باید 120 باشد
-- SELECT unit, COUNT(*) FROM words WHERE book_id = @book_id GROUP BY unit;
