-- =============================================================================
-- جدول لینک PDF آموزشی هر تاپیک گرامر
-- تاپیک‌های گرامر آی‌دی ندارن (فقط یک گروه‌بندی بر اساس ستون topic توی
-- grammar_questions هستن)، پس این جدول با نام دقیق تاپیک (topic) کار می‌کنه.
--
-- استفاده: بعد از آپلود PDF روی سرور (مثلاً از طریق File Manager توی یک پوشه
-- مثل pdfs/) فقط یک ردیف اینجا اضافه کن با آدرس کامل فایل:
--
--   INSERT INTO grammar_topic_pdfs (topic, pdf_url) VALUES
--   ('Present Simple', 'https://erfaninfo.com/wordsapi/pdfs/present-simple.pdf');
--
-- اسم topic باید دقیقاً همون‌طوری باشه که توی grammar_questions.topic ذخیره شده
-- (حساس به بزرگی/کوچکی حروف نیست چون در PHP هر دو trim/lower می‌شن، ولی برای
-- خوانایی بهتره دقیقاً یکی باشه).
-- =============================================================================

CREATE TABLE grammar_topic_pdfs (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  topic VARCHAR(255) NOT NULL,
  pdf_url VARCHAR(500) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grammar_topic_pdfs_topic (topic)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
