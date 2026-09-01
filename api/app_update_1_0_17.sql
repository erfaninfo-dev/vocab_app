-- Release manifest for Erfan Academy 1.0.17+17.
-- Run after uploading APK and erfan_academy_windows.zip to downloads/.

UPDATE app_updates
SET is_active = 0
WHERE platform = 'android'
  AND version_code < 17;

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
  17,
  '1.0.17',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy.apk',
  0,
  'What is new in this update:

Speaking Part 1
- Browse topics and practice questions with model answers

Idioms
- Dedicated idioms units with progress tracking

Accounts
- Save and switch between multiple accounts on one device

Word Builder PvP
- Challenge level selection and session improvements

Other improvements
- Home and book navigation polish, stability fixes',
  'تغییرات این نسخه:

Speaking Part 1
- مرور موضوعات و تمرین سؤال‌ها با پاسخ نمونه

Idioms
- یونیت‌های اختصاصی اصطلاحات با پیگیری پیشرفت

حساب‌ها
- ذخیره و جابه‌جایی بین چند حساب روی یک دستگاه

Word Builder PvP
- انتخاب سطح چالش و بهبود جلسه

سایر بهبودها
- ظاهر خانه و ناوبری کتاب، رفع باگ‌ها',
  'گۆڕانکارییەکانی ئەم وەشانە:

Speaking Part 1
- بابەتەکان و پرسیارەکان لەگەڵ وەڵامی نموونە

Idioms
- یەکەکانی تایبەتی دەستەواژە لەگەڵ بەدواداچوونی پێشکەوتن

هەژمارەکان
- پاشەکەوت و گۆڕینی چەند هەژمار لەسەر یەک ئامێر

Word Builder PvP
- هەڵبژاردنی ئاستی بەرەنگاربوونەوە و باشترکردنی دانیشتن

باشترکردنەکانی تر
- ڕووکاری ماڵ و گەڕان لە کتێب، چاککردنی جێگیری',
  1
);

UPDATE app_updates
SET is_active = 0
WHERE platform = 'windows'
  AND version_code < 17;

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
  17,
  '1.0.17',
  'http://erfaninfo.com/wordsapi/downloads/erfan_academy_windows.zip',
  0,
  'What is new in this update:

Speaking Part 1
- Browse topics and practice questions with model answers

Idioms
- Dedicated idioms units with progress tracking

Accounts
- Save and switch between multiple accounts on one device

Word Builder PvP
- Challenge level selection and session improvements

Other improvements
- Home and book navigation polish, stability fixes',
  'تغییرات این نسخه:

Speaking Part 1
- مرور موضوعات و تمرین سؤال‌ها با پاسخ نمونه

Idioms
- یونیت‌های اختصاصی اصطلاحات با پیگیری پیشرفت

حساب‌ها
- ذخیره و جابه‌جایی بین چند حساب روی یک دستگاه

Word Builder PvP
- انتخاب سطح چالش و بهبود جلسه

سایر بهبودها
- ظاهر خانه و ناوبری کتاب، رفع باگ‌ها',
  'گۆڕانکارییەکانی ئەم وەشانە:

Speaking Part 1
- بابەتەکان و پرسیارەکان لەگەڵ وەڵامی نموونە

Idioms
- یەکەکانی تایبەتی دەستەواژە لەگەڵ بەدواداچوونی پێشکەوتن

هەژمارەکان
- پاشەکەوت و گۆڕینی چەند هەژمار لەسەر یەک ئامێر

Word Builder PvP
- هەڵبژاردنی ئاستی بەرەنگاربوونەوە و باشترکردنی دانیشتن

باشترکردنەکانی تر
- ڕووکاری ماڵ و گەڕان لە کتێب، چاککردنی جێگیری',
  1
);
