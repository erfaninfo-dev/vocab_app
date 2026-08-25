-- Release manifest for Erfan Academy 1.0.16+16.
-- Run after uploading APK and erfan_academy_windows.zip to downloads/.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'android'
  AND version_code < 16;

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
  16,
  '1.0.16',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy.apk',
  0,
  'What is new in this update:

Windows in-app update
- Download and install updates from Settings → About on Windows desktop
- Improved updater reliability and logging

Grammar community
- Reactions on grammar practice results

Other improvements
- Stability and UI polish',
  'تغییرات این نسخه:

آپدیت ویندوز از داخل اپ
- دانلود و نصب از تنظیمات → درباره روی ویندوز
- بهبود قابلیت اطمینان updater و لاگ

جامعهٔ گرامر
- واکنش روی نتایج تمرین گرامر

سایر بهبودها
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

نوێکردنەوەی ویندۆز لە ناو ئەپ
- داگرتن و دامەزراندن لە ڕێکخستنەکان → دەربارە لە ویندۆز
- باشترکردنی updater و log

کۆمەڵگای گرامەر
- کاردانەوە لەسەر ئەنجامی ڕاهێنانی گرامەر

باشترکردنەکانی تر
- جێگیری و ڕووکاری باشتر',
  1
);

UPDATE app_updates
SET is_active = 0
WHERE platform = 'windows'
  AND version_code < 16;

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
  16,
  '1.0.16',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy_windows.zip',
  0,
  'What is new in this update:

Windows in-app update
- Download and install updates from Settings → About
- Improved updater (cmd start + log next to exe)

Grammar community
- Reactions on grammar practice results

Other improvements
- Stability and UI polish',
  'تغییرات این نسخه:

آپدیت ویندوز از داخل اپ
- دانلود و نصب از تنظیمات → درباره
- updater بهتر (لاگ کنار exe)

جامعهٔ گرامر
- واکنش روی نتایج تمرین گرامر

سایر بهبودها
- پایداری و ظاهر بهتر',
  'گۆڕانکارییەکانی ئەم وەشانە:

نوێکردنەوەی ویندۆز لە ناو ئەپ
- داگرتن و دامەزراندن لە ڕێکخستنەکان → دەربارە
- updater باشتر (log لە تەنیشت exe)

کۆمەڵگای گرامەر
- کاردانەوە لەسەر ئەنجامی ڕاهێنانی گرامەر

باشترکردنەکانی تر
- جێگیری و ڕووکاری باشتر',
  1
);
