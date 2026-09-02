-- Release manifest for Erfan Academy 1.0.18+18.
-- Run after uploading APK and erfan_academy_windows.zip to downloads/.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'android'
  AND version_code < 18;

INSERT INTO app_updates (
  platform,
  version_code,
  version_name,
  apk_url,
  force_update,
  message_en,
  message_fa,
  message_ku,
  is_active
) VALUES (
  'android',
  18,
  '1.0.18',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy.apk',
  0,
  'What is new in this update:

PDF study materials
- Open PDFs in your preferred app (no built-in viewer)

Speaking Part 1
- Improved topics, questions, and local answer hints

Idioms
- Lighter WebP illustrations for faster loading

App size
- Smaller APK and Windows build (removed PDF engine)

Other improvements
- Stability and UI polish',
  'تغییرات این نسخه:

فایل‌های PDF آموزشی
- باز شدن PDF در اپ دلخواه شما (بدون viewer داخلی)

Speaking Part 1
- بهبود موضوعات، سؤال‌ها و راهنمای پاسخ محلی

Idioms
- تصاویر WebP سبک‌تر برای بارگذاری سریع‌تر

حجم اپ
- APK و ویندوز کوچک‌تر (حذف موتور PDF)

سایر بهبودها
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

PDF ی خوێندن
- کردنەوە لە ئەپی دڵخوازت (بێ viewer ی ناو ئەپ)

Speaking Part 1
- باشترکردنی بابەت، پرسیار و ڕێنمایی وەڵامی ناوخۆیی

Idioms
- وێنەی WebP سووکتر بۆ بارکردنی خێراتر

قەبارەی ئەپ
- APK و ویندۆز بچووکتر (لابردنی ئەنجینەی PDF)

باشترکردنەکانی تر
- جێگیری و ڕووکاری باشتر',
  1
);

UPDATE app_updates
SET is_active = 0
WHERE platform = 'windows'
  AND version_code < 18;

INSERT INTO app_updates (
  platform,
  version_code,
  version_name,
  apk_url,
  force_update,
  message_en,
  message_fa,
  message_ku,
  is_active
) VALUES (
  'windows',
  18,
  '1.0.18',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy_windows.zip',
  0,
  'What is new in this update:

PDF study materials
- Open PDFs in your preferred app (no built-in viewer)

Speaking Part 1
- Improved topics, questions, and local answer hints

Idioms
- Lighter WebP illustrations for faster loading

App size
- Smaller APK and Windows build (removed PDF engine)

Other improvements
- Stability and UI polish',
  'تغییرات این نسخه:

فایل‌های PDF آموزشی
- باز شدن PDF در اپ دلخواه شما (بدون viewer داخلی)

Speaking Part 1
- بهبود موضوعات، سؤال‌ها و راهنمای پاسخ محلی

Idioms
- تصاویر WebP سبک‌تر برای بارگذاری سریع‌تر

حجم اپ
- APK و ویندوز کوچک‌تر (حذف موتور PDF)

سایر بهبودها
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

PDF ی خوێندن
- کردنەوە لە ئەپی دڵخوازت (بێ viewer ی ناو ئەپ)

Speaking Part 1
- باشترکردنی بابەت، پرسیار و ڕێنمایی وەڵامی ناوخۆیی

Idioms
- وێنەی WebP سووکتر بۆ بارکردنی خێراتر

قەبارەی ئەپ
- APK و ویندۆز بچووکتر (لابردنی ئەنجینەی PDF)

باشترکردنەکانی تر
- جێگیری و ڕووکاری باشتر',
  1
);
