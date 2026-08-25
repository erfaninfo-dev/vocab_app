-- =============================================================================
-- جدول لینک PDF آموزشی هر تاپیک گرامر
-- تاپیک‌های گرامر آی‌دی ندارن (فقط یک گروه‌بندی بر اساس ستون topic توی
-- grammar_questions هستن)، پس این جدول با نام دقیق تاپیک (topic) کار می‌کنه.
-- هر topic می‌تونه چند PDF داشته باشه؛ ترتیب با sort_order.
--
-- استفاده: بعد از آپلود PDF روی سرور (مثلاً از طریق File Manager توی یک پوشه
-- مثل pdfs/) ردیف(ها) اینجا اضافه کن:
--
--   INSERT INTO grammar_topic_pdfs (topic, title, pdf_url, sort_order) VALUES
--   ('Present Simple', 'Introduction', 'https://erfaninfo.com/wordsapi/pdfs/present-simple-1.pdf', 1),
--   ('Present Simple', 'Advanced rules', 'https://erfaninfo.com/wordsapi/pdfs/present-simple-2.pdf', 2);
--
-- اسم topic باید دقیقاً همون‌طوری باشه که توی grammar_questions.topic ذخیره شده.
-- =============================================================================

CREATE TABLE grammar_topic_pdfs (
  id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  topic VARCHAR(255) NOT NULL,
  title VARCHAR(255) NOT NULL DEFAULT '',
  pdf_url VARCHAR(500) NOT NULL,
  sort_order INT UNSIGNED NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  KEY idx_grammar_topic_pdfs_topic_sort (topic, sort_order, id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
