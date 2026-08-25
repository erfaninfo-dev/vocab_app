-- Release manifest for Erfan Academy 1.0.12+15.
-- Run after uploading the new APK to the URL below.
-- If your APK path is different, edit apk_url before running.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'android'
  AND version_code < 15;

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
  15,
  '1.0.12',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy.apk',
  0,
  'What is new in this update:

Grammar study PDFs
- Study button on each grammar topic card opens the lesson PDF in-app
- Multiple PDFs per topic show a picker with titles and order numbers
- PDFs download once and open faster from local storage on your phone
- Updated PDF files on the server are detected automatically (same URL)

Other improvements
- Disabled study button when a topic has no PDF yet
- General stability and UI polish',
  'تغییرات این نسخه:

PDF آموزشی گرامر
- دکمهٔ مطالعه روی هر کارت topic، PDF درس را داخل اپ باز می‌کند
- چند PDF برای یک topic → لیست انتخاب با عنوان و شمارهٔ ترتیب
- PDF یک‌بار دانلود می‌شود و دفعات بعد سریع‌تر از حافظهٔ گوشی باز می‌شود
- اگر فایل روی سرور عوض شود (با همان لینk)، نسخهٔ جدید خودکار گرفته می‌شود

سایر بهبودها
- دکمهٔ مطالعه غیرفعال وقتی PDF برای topic آماده نیست
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

PDFی فێرکاری گرامەر
- دوگمەی خوێندن لەسەر هەر کارتی topic، PDFی وانە لە ناو ئەپ دەکاتەوە
- چەند PDF بۆ topic → لیستی هەڵبژاردن لەگەڵ ناو و ژمارەی ڕیز
- PDF جارێک دادەگیرێت و جارەکانی دواتر خێراتر لە بیرگەی مۆبایل دەکرێتەوە
- ئەگەر فایل لە سێرڤەر بگۆڕدرێت (هەمان لینk)، وەشانی نوێ خۆکار دەگیرێت

باشترکردنەکانی تر
- دوگمەی خوێندن ناچالاک کاتێک PDF بۆ topic ئامادە نییە
- جێگیری و ڕووکاری باشتر',
  1
);

-- Windows desktop (zip of build/windows/x64/runner/Release contents).
-- Upload erfan_academy_windows.zip to the URL below before running.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'windows'
  AND version_code < 15;

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
  15,
  '1.0.12',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy_windows.zip',
  0,
  'What is new in this update:

Grammar study PDFs
- Study button on each grammar topic card opens the lesson PDF in-app
- Multiple PDFs per topic show a picker with titles and order numbers
- PDFs download once and open faster from local storage
- Updated PDF files on the server are detected automatically (same URL)

Other improvements
- Disabled study button when a topic has no PDF yet
- Windows in-app update from Settings → About
- General stability and UI polish',
  'تغییرات این نسخه:

PDF آموزشی گرامر
- دکمهٔ مطالعه روی هر کارت topic، PDF درس را داخل اپ باز می‌کند
- چند PDF برای یک topic → لیست انتخاب با عنوان و شمارهٔ ترتیب
- PDF یک‌بار دانلود می‌شود و دفعات بعد سریع‌تر از حافظهٔ دستگاه باز می‌شود
- اگر فایل روی سرور عوض شود (با همان لینk)، نسخهٔ جدید خودکار گرفته می‌شود

سایر بهبودها
- دکمهٔ مطالعه غیرفعال وقتی PDF برای topic آماده نیست
- آپدیت ویندوز از تنظیمات → درباره
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

PDFی فێرکاری گرامەر
- دوگمەی خوێندن لەسەر هەر کارتی topic، PDFی وانە لە ناو ئەپ دەکاتەوە
- چەند PDF بۆ topic → لیستی هەڵبژاردن لەگەڵ ناو و ژمارەی ڕیز
- PDF جارێک دادەگیرێت و جارەکانی دواتر خێراتر لە بیرگەی ئامێر دەکرێتەوە
- ئەگەر فایل لە سێرڤەر بگۆڕدرێت (هەمان لینk)، وەشانی نوێ خۆکار دەگیرێت

باشترکردنەکانی تر
- دوگمەی خوێندن ناچالاک کاتێک PDF بۆ topic ئامادە نییە
- نوێکردنەوەی ویندۆز لە ڕێکخستنەکان → دەربارە
- جێگیری و ڕووکاری باشتر',
  1
);
