-- =============================================================================
-- یک PDF آموزشی placeholder برای همهٔ topicهای legacy گرامر
-- (به‌جز Present Simple که قبلاً اضافه شده)
--
-- ترتیب: همان grammar_topics.php → MIN(order_num) ASC, topic ASC
-- title: حرف اول بزرگ (topic همان نام دقیق questions.content می‌ماند)
--
-- قبل از اجرا: migration چندفایلی (grammar_topic_pdfs_multiple.sql)
-- اگر قبلاً با ترتیب اشتباه insert کردید، اول DELETE کنید یا NOT EXISTS
-- خودش از duplicate جلوگیری می‌کند.
-- =============================================================================

SET @pdf_url = 'https://erfaninfo.com/wordsapi/uploads/pdf/present_simple_do_does_wh_questions3.pdf';

INSERT INTO grammar_topic_pdfs (topic, title, pdf_url, sort_order)
SELECT
  t.topic,
  CONCAT(UPPER(LEFT(t.topic, 1)), SUBSTRING(t.topic, 2)) AS title,
  @pdf_url,
  1
FROM (
  SELECT
    TRIM(content) AS topic,
    MIN(order_num) AS topic_order
  FROM questions
  WHERE content IS NOT NULL
    AND TRIM(content) <> ''
    AND (grammar_book_id IS NULL OR grammar_book_id = 0)
    AND (grammar_unit_id IS NULL OR grammar_unit_id = 0)
  GROUP BY TRIM(content)
) AS t
WHERE LOWER(t.topic) COLLATE utf8mb4_unicode_ci <>
      LOWER('present simple') COLLATE utf8mb4_unicode_ci
  AND NOT EXISTS (
    SELECT 1
    FROM grammar_topic_pdfs g
    WHERE LOWER(TRIM(g.topic)) COLLATE utf8mb4_unicode_ci =
          LOWER(TRIM(t.topic)) COLLATE utf8mb4_unicode_ci
  )
ORDER BY t.topic_order ASC, t.topic ASC;

-- ── اگر قبلاً insert شده و فقط title/ترتیب نمایش در phpMyAdmin مهم است ──
-- UPDATE grammar_topic_pdfs g
-- INNER JOIN (
--   SELECT
--     TRIM(content) AS topic,
--     MIN(order_num) AS topic_order
--   FROM questions
--   WHERE content IS NOT NULL
--     AND TRIM(content) <> ''
--     AND (grammar_book_id IS NULL OR grammar_book_id = 0)
--     AND (grammar_unit_id IS NULL OR grammar_unit_id = 0)
--   GROUP BY TRIM(content)
-- ) AS t
--   ON LOWER(TRIM(g.topic)) COLLATE utf8mb4_unicode_ci =
--      LOWER(TRIM(t.topic)) COLLATE utf8mb4_unicode_ci
-- SET g.title = CONCAT(UPPER(LEFT(g.topic, 1)), SUBSTRING(g.topic, 2));

-- ── نسخهٔ DB بدون grammar_book_id / grammar_unit_id ──
--
-- INSERT INTO grammar_topic_pdfs (topic, title, pdf_url, sort_order)
-- SELECT
--   t.topic,
--   CONCAT(UPPER(LEFT(t.topic, 1)), SUBSTRING(t.topic, 2)) AS title,
--   'https://erfaninfo.com/wordsapi/uploads/pdf/present_simple_do_does_wh_questions3.pdf',
--   1
-- FROM (
--   SELECT TRIM(content) AS topic, MIN(order_num) AS topic_order
--   FROM questions
--   WHERE content IS NOT NULL AND TRIM(content) <> ''
--   GROUP BY TRIM(content)
-- ) AS t
-- WHERE LOWER(t.topic) COLLATE utf8mb4_unicode_ci <>
--       LOWER('present simple') COLLATE utf8mb4_unicode_ci
--   AND NOT EXISTS (
--     SELECT 1 FROM grammar_topic_pdfs g
--     WHERE LOWER(TRIM(g.topic)) COLLATE utf8mb4_unicode_ci =
--           LOWER(TRIM(t.topic)) COLLATE utf8mb4_unicode_ci
--   )
-- ORDER BY t.topic_order ASC, t.topic ASC;

-- ── چک ترتیب نهایی (باید مثل اپ باشد) ──
-- SELECT g.topic, g.title, MIN(q.order_num) AS topic_order
-- FROM grammar_topic_pdfs g
-- INNER JOIN questions q
--   ON LOWER(TRIM(q.content)) COLLATE utf8mb4_unicode_ci =
--      LOWER(TRIM(g.topic)) COLLATE utf8mb4_unicode_ci
-- GROUP BY g.id, g.topic, g.title
-- ORDER BY topic_order ASC, g.topic ASC;
