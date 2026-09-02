-- Release manifest for Erfan Academy 1.0.19+19.
-- Run after uploading APK and erfan_academy_windows.zip to downloads/.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'android'
  AND version_code < 19;

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
  19,
  '1.0.19',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy.apk',
  0,
  'What is new in this update:

Speaking Part 1
- Topic illustrations for all server topics

Other improvements
- Stability fixes',
  'تغییرات این نسخه:

Speaking Part 1
- تصویر اختصاصی برای همهٔ موضوعات سرور

سایر بهبودها
- رفع باگ‌ها',
  'گۆڕانکارییەکانی ئەم وەشانە:

Speaking Part 1
- وێنەی تایبەت بۆ هەموو بابەتەکانی سێرڤەر

باشترکردنەکانی تر
- چاککردنی جێگیری',
  1
);

UPDATE app_updates
SET is_active = 0
WHERE platform = 'windows'
  AND version_code < 19;

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
  19,
  '1.0.19',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy_windows.zip',
  0,
  'What is new in this update:

Speaking Part 1
- Topic illustrations for all server topics

Other improvements
- Stability fixes',
  'تغییرات این نسخه:

Speaking Part 1
- تصویر اختصاصی برای همهٔ موضوعات سرور

سایر بهبودها
- رفع باگ‌ها',
  'گۆڕانکارییەکانی ئەم وەشانە:

Speaking Part 1
- وێنەی تایبەت بۆ هەموو بابەتەکانی سێرڤەر

باشترکردنەکانی تر
- چاککردنی جێگیری',
  1
);
