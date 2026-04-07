# IELTS Essential Words — راهنمای زمینه برای AI و توسعه‌دهندگان

این سند **توضیح دقیق و کامل** پروژه را برای مدل‌های زبانی، ابزارهای اتوماسیون و هر کسی که تازه وارد کدبیس می‌شود، جمع‌بندی می‌کند. مسیرها نسبت به ریشهٔ پوشهٔ پروژه `Ielts essential words` هستند.

---

## ۱. هدف محصول

اپلیکیشن **IELTS Essential Words** برای یادگیری و مرور لغات آیلتس طراحی شده است. کاربر:

- از **صفحهٔ اصلی** لیست **کتاب‌ها** را می‌بیند، روی یک کتاب می‌زند و وارد **یونیت‌ها** می‌شود.
- اگر برای آن یونیت **سکشن** تعریف شده باشد، ابتدا **سکشن‌ها** را می‌بیند؛ اگر نه، مستقیم به **لیست لغات** همان یونیت می‌رود.
- برای هر محدوده می‌تواند **کارت لغت**، **فلش‌کارت**، **کوییز**، **مورد علاقه** و **سخت** را استفاده کند.
- **مرور روزانه (Review)** با الگوریتم **فاصله‌گذاری تکرار (SRS)** و **آمار / استریک** و **یادآور نوتیفیکیشن** (اندروید) پشتیبانی می‌شود.
- **زبان ترجمهٔ محلی** بین **فارسی** و **کردی** قابل انتخاب است؛ هر دو جهت **RTL** در نظر گرفته می‌شوند.

---

## ۲. معماری کلی (دو بخش)

| بخش | نقش | تکنولوژی |
|-----|-----|----------|
| **کلاینت** | UI، ناوبری، ذخیرهٔ محلی ترجیحات و SRS | Flutter (Dart SDK ^3.8)، Material 3 |
| **بک‌اند** | خواندن کتاب‌ها، یونیت‌ها، سکشن‌ها و لغات از دیتابیس | PHP + MySQL (فایل‌های داخل `api/`) |

کلاینت دادهٔ لغات را **از طریق HTTP JSON** از سرور می‌گیرد؛ آدرس پایه در کد ثابت است و باید برای محیط خودتان عوض شود (بخش تنظیمات فنی).

---

## ۳. ساختار پوشه‌ها

```text
Ielts essential words/
  AGENTS.md                 ← همین فایل
  api/                      ← اسکریپت‌های PHP و SQL سید
    config.php              ← اتصال PDO به MySQL، هدر JSON و CORS
    books.php
    units.php
    sections.php
    words.php
    seed_financial_business_book.sql   ← نمونهٔ سید یک کتاب (MySQL 8+)
  ielts_vocab_app/          ← پروژهٔ Flutter
    lib/
      main.dart
      core/                   ← تم، روتر، SRS، آمار، TTS، نوتیفیکیشن، زبان
      data/                   ← مدل‌ها و ApiService
      domain/                 ← Riverpod providers مربوط به API
      features/               ← صفحه‌ها به‌صورت feature-based
    pubspec.yaml
    README.md                 ← راهنمای قدیمی/تبدیل اکسل (ممکن است با جریان API-only هم‌پوشانی داشته باشد)
```

---

## ۴. کلاینت Flutter — جزئیات فنی

### ۴.۱ وابستگی‌های اصلی (`ielts_vocab_app/pubspec.yaml`)

- **flutter_riverpod** — مدیریت وضعیت و `FutureProvider` برای API
- **go_router** — مسیرها و `ShellRoute` برای نوار پایین
- **shared_preferences** — علاقه‌مندی، سخت، SRS، آمار، تم، زبان، نوتیفیکیشن
- **http** — فراخوانی REST
- **flutter_tts** — تلفظ لغات
- **flutter_local_notifications** + **timezone** — یادآور روزانه (مقداردهی اولیه در `main.dart`)

### ۴.۲ نقطهٔ ورود

- `lib/main.dart`: `WidgetsFlutterBinding.ensureInitialized()`، `initNotifications()`، سپس `runApp(ProviderScope(child: IeltsVocabApp()))`.
- `IeltsVocabApp`: `MaterialApp.router` با `theme` / `darkTheme` و `routerConfig` از `routerProvider`.

### ۴.۳ ناوبری (`lib/core/router/app_router.dart`)

- **`/`** → `SplashScreen` (~۱.۳ ثانیه) → **`/home`**
- **`ShellRoute`** (نوار پایین مشترک) برای:
  - `/home`, `/review`, `/stats`, `/settings`
  - مسیرهای عمیق‌تر کتاب:  
    `/books/:bookId/units` → (در صورت وجود سکشن) `/books/:bookId/units/:unit/sections` → `/books/:bookId/units/:unit/sections/:section/words`
  - اگر یونیت **بدون سکشن** باشد: `/books/:bookId/units/:unit/words`
  - فلش‌کارت و کوییز با همان الگو، با یا بدون `:section`
  - `/favorites` — علاقه‌مندی‌ها

**رفتار مهم:** در `UnitsScreen` اگر `sections.php` آرایهٔ خالی برگرداند، اپ مستقیم به مسیر `.../words` می‌رود (بدون صفحهٔ سکشن).

### ۴.۴ لایهٔ داده و API (`lib/data/services/api_service.dart`)

- ثابت **`kApiBaseUrl`**: در حال حاضر مقدار نمونه `'http://erfaninfo.com/wordsapi'` است. **برای استقرار باید به دامنه/مسیر واقعی API خودتان تغییر کند.**

**اندپوینت‌های مورد انتظار (هم‌تراز با `api/*.php` در همین ریپو):**

| عمل | متد | پارامترها |
|-----|-----|-----------|
| لیست کتاب‌ها | GET | `books.php` |
| یونیت‌های یک کتاب | GET | `units.php?book_id=` |
| سکشن‌های یک یونیت | GET | `sections.php?book_id=&unit=` |
| لغات (حالت‌ها) | GET | `words.php?book_id=` و در صورت نیاز `&unit=` و `&section=` |

**نکتهٔ همگام‌سازی با کد:** متد `searchBooks` در کلاینت به `books.php?search=...` درخواست می‌زند، اما **نسخهٔ `books.php` داخل این ریپو** پارامتر `search` را پیاده‌سازی نمی‌کند. برای جستجوی کتاب روی سرور باید بک‌اند را گسترش دهید یا جستجو را فقط سمت کلاینت محدود کنید.

### ۴.۵ Riverpod (`lib/domain/api_providers.dart`)

- `apiServiceProvider`, `apiBooksProvider`, `apiUnitsProvider(bookId)`, `apiSectionsProvider((bookId, unit))`, `apiWordsProvider((bookId, unit, section?))`, `apiAllWordsForBookProvider(bookId)`
- جستجو: `bookSearchQueryProvider` + `apiSearchBooksProvider` (وقتی query خالی است همان `fetchBooks` را صدا می‌زند)

### ۴.۶ مدل لغت و شناسهٔ یکتا (`lib/data/models/vocab_entry.dart`)

- فیلدها: `bookId` (رشته)، `word`, `type`, معنی/مثال انگلیسی، فارسی، کردی، `unit`, `section` (nullable).
- **`id` یک شناسهٔ ترکیبی است** (بر اساس `bookId`, `word`, `section`, `unit`, `meaningFa`) — برای **علاقه‌مندی، سخت، SRS** استفاده می‌شود؛ تغییر دادن منطق بدون مهاجرت داده می‌تواند رکوردهای ذخیره‌شده را از بین ببرد.

### ۴.۷ ویژگی‌های محلی (بدون سرور)

- **`WordPreferencesController`** (`lib/features/words/word_preferences_controller.dart`): `favorite_words`, `difficult_words` در SharedPreferences.
- **SRS** (`lib/core/srs/`): کارت‌ها با کلید `srs_cards_v1`؛ امتیازدهی با مقیاس شبیه SM-2 (`SrsRating`: again/hard/good/easy).
- **آمار** (`lib/core/stats/stats_service.dart`): روزهای مطالعه، تعداد مرور، نتایج کوییز، استریک.
- **زبان ترجمه** (`lib/core/language/language_provider.dart`): فارسی / کردی با fallback متقابل برای فیلدهای خالی.
- **تم** (`lib/features/settings/theme_mode_controller.dart`): روشن / تیره / سیستم.
- **نوتیفیکیشن** (`lib/core/notifications/notification_service.dart`): زمان روزانه قابل تنظیم؛ کانال اندروید `ielts_daily`.

### ۴.۸ CI (GitHub Actions)

- `ielts_vocab_app/.github/workflows/build_apk.yml`: روی push به `main` (و دستی) APK ریلیز می‌سازد و آرتیفکت آپلود می‌کند. **مسیر checkout باید همان پوشهٔ اپ باشد** (اگر ریپوی جدا دارید، workflow را با ساختار ریپو هماهنگ کنید).

---

## ۵. بک‌اند PHP — قرارداد API

### ۵.۱ پیکربندی (`api/config.php`)

- `DB_HOST`, `DB_USER`, `DB_PASS`, `DB_NAME` برای MySQL.
- `sendJson` / `sendError`: JSON UTF-8، CORS برای GET (و OPTIONS با 204).

### ۵.۲ جداول مفهومی (استنتاج از کوئری‌ها)

- **`books`**: `id`, `title`, `description`, `sort_order`
- **`words`**: حداقل `book_id`, `unit`, `unit_details`, `section` (nullable), `word`, `type`, `meaning_en`, `meaning_fa`, `meaning_kur`, `example_en`, `example_fa`, `example_kur` (و در سید نمونه: `page`)

### ۵.۳ رفتار هر اندپوینت

- **`books.php`**: همهٔ کتاب‌ها به ترتیب `sort_order`, `title`.
- **`units.php`**: برای `book_id`، یونیت‌های متمایز از روی جدول `words` با `MAX` روی `unit_details` گروه‌بندی شده‌اند.
- **`sections.php`**: برای `book_id` + `unit`، فقط ردیف‌هایی که `section IS NOT NULL` — اگر هیچی نبود، `[]` یعنی یونیت بدون سکشن.
- **`words.php`**:
  - با `book_id` + `unit` + `section`: فقط آن سکشن
  - با `book_id` + `unit` (بدون section در query): همهٔ ردیف‌های آن یونیت (برای یونیت‌های بدون سکشن؛ در DB ممکن است `section` همه NULL باشد)
  - فقط `book_id`: **تمام لغات کتاب** (برای صفحهٔ علاقه‌مندی‌ها و مرور SRS)

---

## ۶. دادهٔ نمونه و SQL

- **`api/seed_financial_business_book.sql`**: درج یک کتاب نمونه «Financial - Business» با ۱۲۰ لغت placeholder (`financial_term_001` …)، `section = NULL`، و `unit_details` برای هر یونیت. برای MySQL 8+ با `WITH RECURSIVE` نوشته شده است.

---

## ۷. کارهای رایج برای توسعه‌دهنده / AI

1. **تغییر سرور API:** مقدار `kApiBaseUrl` در `ielts_vocab_app/lib/data/services/api_service.dart`.
2. **اندروید و HTTP cleartext:** اگر از `http://` استفاده می‌کنید، ممکن است نیاز به تنظیم شبکهٔ امن در اندروید باشد؛ برای production ترجیحاً HTTPS.
3. **جستجوی کتاب:** یا `books.php` را با `?search=` تکمیل کنید یا فراخوانی `searchBooks` را حذف/تغییر دهید تا با بک‌اند همخوان باشد.
4. **هماهنگی README با کد:** `ielts_vocab_app/README.md` هنوز به مسیر اکسل/JSON asset اشاره می‌کند؛ اگر دیگر از asset محلی استفاده نمی‌شود، آن بخش را به‌روز کنید تا گمراهی پیش نیاید.

---

## ۸. خلاصهٔ یک‌خطی برای پرامپت‌های AI

> پروژه یک اپ Flutter آیلتس است که لغات را از APIهای PHP/MySQL می‌گیرد؛ ناوبری Book → Unit → (اختیاری Section) → Words است؛ SRS، آمار، علاقه‌مندی، TTS و نوتیفیکیشن محلی‌اند؛ پایهٔ URL در `ApiService` و قرارداد JSON در `api/*.php` تعریف شده است.

---

*آخرین به‌روزرسانی سند: هم‌تراز با وضعیت کدبیس در زمان نوشتن (بررسی ساختار `lib/`، `api/`، `pubspec.yaml`).*
