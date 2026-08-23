# ۱۴ — رصد سیستم فعلی Prop در Angry Words (پیش از طراحی Prop Archetype عمومی)

> این سند صرفاً یک **تحقیق/آدیت** است؛ هیچ فایل کدی در حین نوشتن آن تغییر نکرده. هر ادعا با ارجاع دقیق `فایل:خط` همراه است تا قابل راستی‌آزمایی باشد. مسیرهای فایل نسبت به ریشهٔ ریپو (`ielts_vocab_app/`) نوشته شده‌اند.

## ⚠️ اصلاحیه روی یک ادعای غلط در نسخهٔ اول این گزارش

نسخهٔ اول این سند (نوشته‌شده توسط ایجنت تحقیق) ادعا کرده بود که `angry_words_loadout.dart` در working tree فعلی «کاملاً خالی (۰ بایت)» است و پروژه کامپایل نمی‌شود. **این ادعا هنگام بازبینی نهایی رد شد و غلط بود** — فایل در working tree فعلی **۲۰۸۰ خط** دارد (نه صفر) و کاملاً سالم است؛ `git diff --stat` نشان می‌دهد نسبت به `HEAD` فقط ۳۸۸ خط اضافه و ۸۵ خط حذف شده (یک ویرایش معمولی، نه پاک‌شدن کامل فایل). به‌عنوان مثال، `enum AngryWordsPropMaterial` در working tree خط ۱۳۷ است، در `HEAD` خط ۱۳۸ — یعنی عملاً یک خط اختلاف، نه ۱۷۷۷ خط. منشأ این ادعای غلط در تحقیق مشخص نیست (احتمالاً خطای خواندن یک فایل موقت/خالی نامرتبط توسط ایجنت).

**تأثیر روی بقیهٔ گزارش:** ارجاعات فایل:خط که برای `angry_words_loadout.dart` در بخش‌های زیر آمده (مثلاً بخش ۱، ۵) بر اساس `HEAD` نوشته شده‌اند، ولی چون تفاوت working tree و HEAD برای این فایل فقط در حد چند خط است (نه ساختاری)، این ارجاعات عملاً هنوز تقریباً درست‌اند (خطای احتمالی ±۱ خط در بخش‌های ابتدایی فایل). سایر فایل‌های هدف تحقیق (physics, painter, letter_board, wb_prop_archetype, cargo_plaque, پوشه‌های `debris/` و `atlas/`) در working tree سالم و کامل بودند و این مشکل نداشتند.

فایل `.cursor/docs/12-word-builder-angry-words-spec.md` که در دستور تحقیق به آن ارجاع شده بود **پیدا نشد** — در واقع کل پوشهٔ `.cursor/docs/` قبل از این تحقیق در ریپو وجود نداشت (با آن به عنوان بخشی از این تسک ساخته شد). جستجوی کامل ریپو برای هر فایل با الگوی `*angry-words-spec*` یا `*word-builder*spec*` نتیجه‌ای نداد. بنابراین بخش‌های ۵ و ۸ آن سند قابل ارجاع نبودند و این آدیت صرفاً از روی کد منبع نوشته شده.

---

## ۱) فیلدهای `AngryWordsPropBubble`

تعریف کلاس در `lib/features/word_builder/presentation/widgets/angry_words/angry_words_physics.dart:81-138`.

| فیلد | نوع | توضیح |
|---|---|---|
| `id` | `final int` | شناسهٔ یکتا (کانتر از `9000` در `_layoutBarrierProps`, خط ۷۴۱) |
| `pos` | `Offset` | موقعیت جهان |
| `vel` | `Offset` | سرعت (برای drift/wander) |
| `radius` | `double` | شعاع فعلی (با resize/stretch تغییر می‌کند) |
| `phase` | `final double` | فاز سینوسی برای wander/pulse |
| `baseSpeed` | `final double` | سرعت پایهٔ حرکت تصادفی |
| `wanderFreq` | `final double` | فرکانس نوسان حرکت |
| `palette` | `final int` | ایندکس پالت رنگ؛ کامنت می‌گوید «۰..۵» ولی مقداردهی واقعی با `rng.nextInt(12)` است (خط ۸۱۰) — مغایرت کوچک بین کامنت و کد |
| `material` | `AngryWordsPropMaterial` | یکی از ۱۷ متریال فیزیکی (تعریف در `angry_words_loadout.dart`, خطوط ۱۳۷-۱۵۵ در نسخهٔ HEAD) |
| `maxHp` | `int` | سقف HP |
| `hp` | `int` | HP فعلی؛ در constructor برابر `maxHp` مقداردهی می‌شود (`: hp = maxHp`, خط ۹۸) |
| `hitFlash` | `double = 0` | شدت فلاش سفید لحظهٔ برخورد (decay هر فریم در painter دیده می‌شود، نه در physics) |
| `freezeT` | `double = 0` | زمان باقی‌ماندهٔ یخ‌زدگی/چسبندگی اسلایم؛ در stepper بشکه decay می‌شود |
| `stretchT` | `double = 0` | مقدار کشش لاستیکی پیش از پاپ نهایی (۰..۱) |
| `pendingStretchPop` | `bool = false` | فلگ اینکه ضربهٔ بعدی روی لاستیک قطعی/کشنده است |
| `cargo` | `LetterInstance?` | حرفی که این prop مخفی کرده (اگر باشد) |
| `cargoTintIndex` | `int?` | رنگ یکتای اختصاصی حرف مخفی‌شده |
| `skinEmoji` | `String?` | برای استیج‌های ۳۵/۳۶ — به‌جای دایرهٔ متریال، ایموجی رسم می‌شود (فیزیک تغییر نمی‌کند) |
| `archetype` | `WbPropArchetype?` | اسکین آرکی‌تایپ اختیاری (اتلس/سیلوئت)؛ اگر `null` باشد از `material` استنتاج می‌شود |
| `spawnT` | `double = 1` | پیشرفت pop-in (۰..۱) هنگام رفیل دیوار |
| `removed` | `bool = false` | فلگ حذف/نابودی |

Getterها: `holdsLetter => cargo != null` (خط ۱۳۶)، `isSpawnVisible => spawnT > 0.02` (خط ۱۳۷).

کلاس‌های همسایهٔ مرتبط در همان فایل: `AngryWordsPropPop` (خط ۱۴۱-۱۶۱، رویداد «یک prop ترکید»)، `AngryWordsYolkBlob` (خط ۱۶۴-۱۷۶، بخش ۶).

---

## ۲) مسیر کامل «گلوله می‌خورد تا prop نابود می‌شود»

مسیر اصلی (ضربهٔ مستقیم گلوله)، در `angry_words_physics.dart`:

1. **کاهش HP** — `_collideBulletWithProps(AngryWordsBullet b)` (خط ۱۸۶۰) برای هر prop برخورد‌کرده، آسیب مؤثر را با `_effectiveBulletDamage(b, P)` (خط ۱۹۷۱) حساب می‌کند و در خط **۱۸۸۹**: `P.hp -= dmg;` را اجرا می‌کند.
   - دو مسیر دیگر کاهش HP: `_splashAt(...)` (خط ۲۰۳۷) برای آسیب انفجاری/AoE، خط **۲۰۵۹**: `P.hp -= d;` و `_douseNearbyMagma(Offset at)` (خط ۲۲۱۱) برای خنک‌کردن ماگما توسط آب، خط **۲۲۱۷**: `P.hp -= 1;`.
   - یک مسیر «HP فوری صفر» هم هست: `_tryHammerSmash` (خط ۱۲۵۰) برای استیج‌های چکشی، خط **۱۲۷۰**: `best.hp = 0;` سپس مستقیم `_popProp(best)` (خط ۱۲۷۲) — بدون عبور از منطق شرطی معمول.

2. **تصمیم «نابود شد یا نه»** — بعد از کاهش HP در `_collideBulletWithProps`:
   - خط **۱۹۱۶**: `if (P.hp > 0) { ... }` → prop زنده مانده: `hitFlash=1`، knockback، و گلوله یا می‌میرد یا (اگر لیزر/پیرس) رد می‌شود.
   - استثنای لاستیک (خط ۱۹۳۹-۱۹۵۴): وقتی `material == rubber` و ضربهٔ کشنده باشد ولی هنوز stretch نشده، به‌جای پاپ فوری، `P.hp` به `1` برگردانده می‌شود، `stretchT=1` و `pendingStretchPop=true` — یعنی یک فریم «کشش لاستیکی» قبل از پاپ واقعی اضافه می‌شود.
   - در غیر این دو حالت، خط **۱۹۵۶**: `_popProp(P, steamy: steamyHit);` صدا زده می‌شود → این یعنی نابودی.
   - در `_splashAt`، تصمیم در خط **۲۰۶۴**: `if (P.hp <= 0) _popProp(...)`.
   - در `_douseNearbyMagma`، تصمیم در خط **۲۲۲۱**: `if (P.hp <= 0) _popProp(P, steamy: true);`.

3. **تابع مرکزی نابودی** — `_popProp(AngryWordsPropBubble P, {bool steamy = false})` در خط **۲۰۷۳**:
   - `P.removed = true` (خط ۲۰۷۵) — از این لحظه دیگر در فیزیک/رندر شرکت نمی‌کند.
   - اگر `cargo` داشت و فاز `cage` بود، `_revealLetterFromProp(cargo, P)` صدا می‌شود (خط ۲۰۸۹) — یعنی آزادسازی حرف مخفی از داخل prop.
   - اگر متریال `egg` بود: `_spawnYolkFromEgg(P)` (خط ۲۰۹۶) → `spillYolkAt(...)` (خط ۲۱۱۲/۲۱۱۶) که یک `AngryWordsYolkBlob` می‌سازد (بخش ۶).
   - در پایان تابع (خط ۲۰۹۸-۲۱۰۸)، یک شیء `AngryWordsPropPop` به صف داخلی `_pendingPropPops` اضافه می‌شود — **این خودِ debris/juice بصری نیست**، فقط یک «رویداد» حاوی موقعیت/متریال/آرکی‌تایپ/رنگ/کاراکتر افشا‌شده است.

4. **مصرف رویداد و spawn واقعی debris** — این بخش **در `angry_words_physics.dart` اتفاق نمی‌افتد**؛ در `angry_words_letter_board.dart` است:
   - در `_onTick` (خط ۳۱۹)، خط **۳۹۶**: `final propPops = _world.takePropPops();` صف را تخلیه می‌کند (`AngryWordsPhysicsWorld.takePropPops`, تعریف در physics.dart خط ۶۷۲).
   - خط **۳۹۹**: برای هر پاپ، `_spawnPropExplosion(pop, playSound: true)` صدا زده می‌شود.
   - `_spawnPropExplosion` (تعریف در letter_board.dart خط **۶۷۹-۷۸۷**) لیستی از `AngryWordsExplosionBit` می‌سازد و یک `AngryWordsLetterExplosion` جدید به لیست `_explosions` اضافه می‌کند (خط ۷۵۲-۷۶۴) — همین لیست توسط `AngryWordsBoardPainter._paintExplosions` رندر می‌شود (بخش ۳ و ۴).

5. **پخش صدا** — همچنان داخل `_spawnPropExplosion`، خطوط **۷۶۷-۷۸۶**:
   - اگر `pop.material == egg`: `ref.read(angryWordsEggCrackAudioProvider).play(...)` (خط ۷۷۱) — صدای مخصوص شکستن تخم‌مرغ.
   - در غیر این صورت: خانوادهٔ صدا از روی آرکی‌تایپ (`spec.soundFamily`) یا اگر آرکی‌تایپ نبود از روی متریال (`wbSoundFamilyForMaterial(pop.material)`, تعریف در `lib/features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart:49-62`) گرفته می‌شود و با `ref.read(angryWordsPropBreakAudioProvider).play(...)` (خط ۷۷۸-۷۸۴) پخش می‌شود. پیاده‌سازی این provider در `lib/core/audio/angry_words_prop_break_audio.dart` است (سیستم صدای هم‌زمانِ محدود به ۳ تا ۶ صدا؛ جزئیات در همان فایل، خط ۲۸-۱۲۳).
   - نکته: `AngryWordsPropBreakAudio` و `AngryWordsPropPop.archetype` هر دو تازه (بخشی از refactor جاری) اضافه شده‌اند؛ صدای «مبتنی بر متریال» (`wbSoundFamilyForMaterial`) صرفاً fallback برای propهایی است که هنوز آرکی‌تایپ ندارند.

**خلاصهٔ زنجیره:** `_collideBulletWithProps` (کاهش HP) → شرط `hp<=0` → `_popProp` (پرچم‌گذاری/آزادسازی letter/yolk + enqueue کردن `AngryWordsPropPop`) → (فریم بعد در ویجت) `takePropPops` → `_spawnPropExplosion` (ساخت بیت‌های debris بصری + پخش صدا).

---

## ۳) `AngryWordsExplosionBit` و `AngryWordsBitShape`

هر دو در `lib/features/word_builder/presentation/widgets/angry_words/angry_words_painter.dart` تعریف شده‌اند:

- **`AngryWordsBitShape`** (خط ۱۳): `enum { round, shard, chip, drop, spark, dust, glitter }` — دقیقاً **۷ شکل**. رسم هرکدام در `_paintExplosionBit` (خط ۱۸۱۱-۱۸۸۵):
  - `round` (۱۸۲۱-۱۸۲۲): یک `drawCircle`.
  - `dust` (۱۸۲۳-۱۸۳۰): یک `drawCircle` با `maskFilter` بلور.
  - `drop` (۱۸۳۱-۱۸۳۵): یک `drawOval`.
  - `chip` (۱۸۳۶-۱۸۵۱): `save`+`translate`+`rotate` → یک `drawRRect` → `restore`.
  - `shard` (۱۸۵۲-۱۸۶۲): `save`+`translate`+`rotate` → یک `drawPath` (مثلث نامنظم) → `restore`.
  - `spark` (۱۸۶۳-۱۸۷۵): `save`+`translate`+`rotate` → یک `drawLine` → `restore`.
  - `glitter` (۱۸۷۶-۱۸۸۳): دو `drawLine` (بعلاوهٔ) یک `drawCircle`.
  - **مهم:** این `AngryWordsBitShape` هفت‌گانه با `WbShardShape` هجده‌گانه در `wb_prop_archetype.dart` (خط ۸۹-۱۰۸: `shard, chunk, crumb, dust, scrap, sliver, seed, coin, spark, droplet, fluff, ribbon, streamer, halfShell, plate, ember, prism, glint`) **دو enum کاملاً جدا و ناهم‌نام هستند**. سیستم فعلی فقط از `AngryWordsBitShape` استفاده می‌کند؛ `WbShardShape` بخشی از دادهٔ آرکی‌تایپ‌های تازه (`WbShatterRecipe`) است که — طبق کامنت بالای فایل (خط ۶-۱۰) — «هنوز در گیم‌پلی سیم نشده» (`gameplay still unwired`). یعنی موقع طراحی سیستم عمومی باید تصمیم گرفت این دو enum یکی شوند یا map بین‌شان لازم است.

- **تعداد spawn هر انفجار** — این تعداد **در `angry_words_letter_board.dart`** تعیین می‌شود، نه در painter:
  - حالت عمومی (پاپ یک prop غیر تخم‌مرغی) در `_spawnPropExplosion` (خط ۶۹۰-۶۹۳):
    ```
    final bitBudget = math.max(2, (profile.count * motionScale).round().clamp(2, 16));
    ```
    یعنی حتی اگر `profile.count` تا ۳۴ باشد (مثلاً شیشه؛ `_popProfileFor`, خط ۷۹۱-۷۹۴)، سقف واقعی spawn **۱۶ بیت** است (`clamp(2, 16)`)؛ `motionScale` از `WbMotion.of(context).particleScale` می‌آید (خط ۶۸۸-۶۸۹).
  - حالت تخم‌مرغ (خط ۷۰۳-۷۱۵): `eggN = math.max(4, (12 * motionScale).round())` — بدون سقف بالایی صریح (فقط کف ۴).
  - بخار اضافه هنگام برخورد یخ↔ماگما (خط ۷۳۷-۷۵۰): `steamN = math.max(2, (6 * motionScale).round())` بیت `dust` اضافه، روی همان انفجار.
  - انفجار حرف حل‌شده (کلمهٔ درست، نه prop) در `_spawnExplosion` (خط ۶۲۰-۶۴۵): همیشه دقیقاً **۱۴ بیت** ثابت، بدون `motionScale`.
  - شکستن پوستهٔ تخم‌مرغ آزاد (letter-egg) در `_spawnEggLetterBreak` (خط ۶۴۸-۶۷۷): همیشه دقیقاً **۱۸ بیت** ثابت.

- **محاسبهٔ lifetime** — دو لایه دارد:
  1. **عمر کل انفجار** (`AngryWordsLetterExplosion.life`) در لحظهٔ ساخت (letter_board.dart خط ۶۹۴-۶۹۷):
     ```
     final life = (profile.life * (0.55 + 0.45 * motionScale))
         .clamp(0.35, WbShatterRecipe.kMaxPlayableLifetimeSec);
     ```
     که `profile.life` پیش‌فرض `1` است (`_AngryWordsPopProfile`, letter_board.dart خط ۱۳۸۶) مگر برای stone (`1.05`, خط ۸۶۳) و foam (`1.15`, خط ۸۹۶) override شده باشد؛ و `kMaxPlayableLifetimeSec = 0.9` در `wb_prop_archetype.dart:155`.
  2. **افت این عمر در هر فریم** در `_onTick` (letter_board.dart خط ۳۵۲-۳۶۲):
     ```
     final decay = foam/sand ? 1.15 : (stone/metal ? 1.35 : 1.55);
     e.life = (e.life - dt * decay).clamp(0.0, 2.0);
     ```
     و وقتی `life <= 0` شد، `_explosions.removeWhere((e) => e.life <= 0)` آن را حذف می‌کند.
  - **بیت‌ها عمر مستقل ندارند** — همه از `e.life` مشترک استفاده می‌کنند؛ اندازهٔ رسم هر بیت `s = bit.size * life * (juicy ? 1.15 : 1.0)` است (painter.dart خط ۱۸۱۸)، یعنی با نزدیک‌شدن `life` به صفر، بیت‌ها هم کوچک‌تر/کم‌رنگ‌تر می‌شوند تا محو شوند؛ زمان‌بندی جداگانه‌ای در سطح هر `AngryWordsExplosionBit` وجود ندارد.

---

## ۴) شمارش canvas operations برای رسم هر orb/prop در هر فریم

⚠️ نکتهٔ مهم پیش از شمارش: تابع `_paintProps` (خط ۹۴۰-۱۱۵۵ در `angry_words_painter.dart`) مسیری است که **همیشه واقعاً اجرا می‌شود**. یک مسیر دوم و batch-شده هم هست (`paintPropsWithAtlas`، در `atlas/wb_prop_atlas_paint.dart`) که با یک `drawRawAtlas` تمام propها را با یک فراخوانی canvas می‌کشد، اما فقط وقتی فعال می‌شود که `AngryWordsBoardPainter.atlasPack != null` باشد. جستجوی کامل ریپو نشان داد **تنها محل ساخت `AngryWordsBoardPainter`** (letter_board.dart خط ۱۲۹۵-۱۳۰۷) پارامتر `atlasPack` را پاس نمی‌دهد — یعنی این مقدار همیشه `null` است و مسیر اتلس فعلاً **کد مرده از منظر گیم‌پلی واقعی** است (کاملاً نوشته و تست‌پذیر، اما wired نشده). پس شمارش زیر مربوط به مسیر واقعاً فعال `_paintProps` است.

**عملیات ثابت به‌ازای هر prop غیر-ایموجی** (بدنهٔ حلقه در `_paintProps`، بدون شاخهٔ ایموجی):

| خط | عملیات |
|---|---|
| ۹۷۵ | `canvas.saveLayer(...)` |
| ۹۸۰ | `canvas.drawOval(...)` — سایه |
| ۹۸۸ | `canvas.drawOval(...)` — پرشدگی گرادیانی (`ui.Gradient.radial`) |
| — | `_paintPropMaterialDetail(...)` (خط ۱۰۰۳) — **متغیر با متریال**، جدول پایین |
| ۱۰۰۵ | `canvas.drawOval(...)` — هایلایت |
| ۱۰۴۳ | `canvas.drawOval(...)` — استروک لبه (rim) |
| ۱۱۵۳ | `canvas.restore()` |

یعنی حداقل **۴ `drawOval` + ۱ `saveLayer` + ۱ `restore`** برای هر prop، به‌علاوهٔ جزئیات متریال.

**عملیات شرطی/اختیاری** (اضافه بر مورد بالا، به ترتیب کد):

| شرط | خط(ها) | عملیات اضافه |
|---|---|---|
| `material ∈ {candy, plastic, gold}` | ۱۰۲۱-۱۰۳۲ | ۲× `drawLine` (اسپارکل صلیبی) |
| `maxHp>=2 \| \| material ∈ {stone, metal, gold, crystal}` | ۱۰۵۵-۱۱۰۳ | ۱× `drawCircle` (حلقهٔ زره) + اگر `crack>0.15` تا ۳× `drawLine` (خطوط ترک) |
| `freezeT > 0.05` | ۱۱۰۴-۱۱۲۳ | ۱× `drawCircle` (حلقهٔ یخ/چسبندگی) + اگر `material==slime` یک `drawCircle` دیگر |
| `hitFlash > 0.05` | ۱۱۲۴-۱۱۳۰ | ۱× `drawCircle` (فلاش سفید) |
| `cargo != null` | ۱۱۳۲-۱۱۵۲ | `AngryWordsCargoPlaque.paintBacking` (۲× `drawCircle` همیشه، +۲× `drawRRect` اگر `usePlaque`) + `paintGlyph` (۱× `TextPainter`/`paint`) — جزئیات در `angry_words_cargo_plaque.dart:32-107` |

**جزئیات متریال در `_paintPropMaterialDetail`** (خط ۱۳۲۶-۱۵۴۶؛ تعداد عملیات per-material):

| متریال | عملیات | خط |
|---|---|---|
| `wood` | ۳× `drawLine` | ۱۳۳۹-۱۳۵۳ |
| `stone` | ۲× `drawCircle` | ۱۳۵۶-۱۳۶۵ |
| `metal` | ۲× `drawCircle` + ۱× `drawLine` | ۱۳۵۶-۱۳۷۵ |
| `water` | ۲× `drawCircle` | ۱۳۷۷-۱۳۸۶ |
| `ice` | حلقهٔ ۳× `drawLine` | ۱۳۸۸-۱۳۹۸ |
| `crystal` | ۱× `drawPath` | ۱۴۰۰-۱۴۱۲ |
| `porcelain` | ۲× `drawLine` | ۱۴۱۸-۱۴۲۷ |
| `egg` | ۲× `drawOval` (+ اگر `hitFlash>0.35`: ۲× `drawLine` دیگر) | ۱۴۲۹-۱۴۶۲ |
| `sand` | حلقهٔ ۵× `drawCircle` | ۱۴۶۵-۱۴۷۲ |
| `foam` | ۲× `drawCircle` | ۱۴۷۴-۱۴۸۳ |
| `magma` | ۲× `drawCircle` | ۱۴۸۵-۱۴۹۸ |
| `gold` | حلقهٔ ۴× `drawCircle` | ۱۵۰۰-۱۵۰۷ |
| `slime` | ۱× `drawCircle` + ۱× `drawOval` | ۱۵۰۹-۱۵۲۱ |
| `rubber` | ۱× `drawArc` | ۱۵۲۳-۱۵۳۲ |
| `glass` | ۱× `drawLine` | ۱۵۳۴-۱۵۴۱ |
| `candy` / `plastic` | صفر (فقط `break;`) | ۱۵۴۲-۱۵۴۴ |

**مثال کف (ساده‌ترین prop ممکن)** — متریال `candy`، بدون cargo، `maxHp==1`، بدون freeze/flash:
`saveLayer`(۱) + `drawOval`×۴ (سایه/پرشدگی/هایلایت/لبه) + `drawLine`×۲ (اسپارکل کندی) + `restore`(۱) = **۸ فراخوانی canvas** (بدون شمارش `Paint()` هایی که خودشان canvas op نیستند).

**مسیر ایموجی** (`_paintEmojiProp`, خط ۱۲۰۵-۱۳۲۴؛ برای propهای stage ۳۵/۳۶ که `skinEmoji != null`): `saveLayer`(۱) + `drawCircle` سایه (۱) + یک `TextPainter`/`paint` برای گلیف ایموجی (۱) + همان بلوک‌های اختیاری زره/یخ/فلاش/cargo (مثل بالا) + `restore`(۱).

---

## ۵) لیست کامل call site های `isPorcelainOnlyWall` و `isBottleOnlyWall`

**پیدا نشد.** جستجوی case-insensitive روی کل ریپو (`*.dart`, هم working tree و هم نسخهٔ `HEAD` قدیمی‌تر فایل خالی‌شدهٔ `angry_words_loadout.dart`) برای الگوهای `isPorcelainOnlyWall`, `isBottleOnlyWall`, و حتی نسخه‌های شل‌تر (`isPorcelain`, `isBottle`, `OnlyWall`) هیچ نتیجه‌ای برنگرداند. این دو identifier **در کد فعلی این ریپو (و در آخرین نسخهٔ تاریخچه‌شدهٔ فایل خالی) وجود ندارند** — نه به این نام دقیق و نه به نام مشابه.

نزدیک‌ترین منطق مشابه که پیدا شد (که شاید منظور تسک همین بوده و بعداً تغییرنام گرفته/refactor شده باشد):

- یک متغیر محلی (نه getter عمومی) به نام `porcelainShell` در `angry_words_letter_board.dart:476-478`:
  ```dart
  final porcelainShell = primarySpec != null &&
      primarySpec.holdsCargoWell &&
      primarySpec.material == AngryWordsPropMaterial.porcelain;
  ```
  که مشخص می‌کند آیا هنگام برخورد به یک حرف در فاز آزاد (free-phase letter)، به‌جای شکستن پوستهٔ تخم‌مرغ استاندارد + ریختن `yolk`، باید افکت شکستن سفال (jug/کوزه، مثل استیج ۲۲) پخش شود یا نه (خط ۴۸۰-۴۹۵).
- ثابت `_eggOnlyWall` (نه بطری) در نسخهٔ HEAD فایل `angry_words_loadout.dart:393` — یک `wallMix` مخصوص که فقط از متریال egg تشکیل شده (برای استیج ۹ استفاده می‌شود، رجوع خط ۸۳۲).
- کامنت‌های «Locked stage-23 glass bottle» و «Locked stage-22 ceramic jug» در `wb_prop_archetype.dart:920-921, 952-953` اشاره دارند که آرکی‌تایپ‌های `ceramicJug` و `glassBottle` برای این دو استیج **قفل‌شده و رفتار خاص خودشان را دارند** (بدون yolk، صدای `pot.mp3`)، ولی این منطق از طریق چک `holdsCargoWell && material==porcelain/glass` روی `WbArchetypeSpec` پیاده شده، نه از طریق یک getter بولین با نام `isPorcelainOnlyWall`/`isBottleOnlyWall`.

**نتیجه برای تیم بعدی:** اگر قرار است این دو identifier «بعداً حذف شوند» (طبق فرض دستور تحقیق)، در حال حاضر چیزی برای حذف‌کردن با این نام وجود ندارد — شاید در برنچ/کامیت دیگری بوده‌اند، یا این فرض اشتباه بوده. پیشنهاد می‌شود پیش از هر اقدام حذف، با جستجوی مشابه در کامیت‌های قدیمی‌تر (`git log -S` روی این نام‌ها) دوباره تأیید شود.

---

## ۶) الگوی `AngryWordsYolkBlob`

تعریف در `angry_words_physics.dart:164-176` — یک کلاس بسیار سادهٔ mutable:
```dart
class AngryWordsYolkBlob {
  Offset pos; Offset vel; double radius;
  bool removed = false; bool onFloor = false;
}
```

**چرخهٔ عمر:**
1. **Spawn** — فقط از دو مسیر: (الف) نابودی یک prop با `material == egg` در `_popProp` → `_spawnYolkFromEgg` (خط ۲۱۱۱-۲۱۱۳) → `spillYolkAt` (خط ۲۱۱۶-۲۱۲۶)؛ (ب) برخورد درست به یک letter-egg آزاد در فاز `free` که مستقیماً از خارج (از `angry_words_letter_board.dart:492`) با `_world.spillYolkAt(hitPos, fromRadius: eggR, seed: hit.id)` صدا زده می‌شود.
   - `spillYolkAt` (خط ۲۱۱۶-۲۱۲۶) یک `AngryWordsYolkBlob` با `radius = (fromRadius*0.55).clamp(7,14)` و سرعت اولیهٔ تصادفی رو‌به‌پایین می‌سازد و به لیست `yolks` اضافه می‌کند.
2. **گام فیزیکی هر فریم** — `_stepYolks(dt)` (خط ۲۱۲۸-۲۱۶۱):
   - اگر هنوز روی زمین نیست (`!onFloor`): گرانش اعمال می‌شود، اصطکاک هوا نمایی روی محور x (`exp(-dt*0.35)`)، و وقتی به خط زمین (`yolkFloorY = height - 38`) رسید، `onFloor=true` و سرعت y صفر می‌شود، سرعت x کمی افت می‌کند (`*0.72`).
   - اگر روی زمین است: فقط لغزش افقی با اصطکاک نمایی + کمی نیروی باد (`windVector.dx * 0.12`)؛ ارتفاع y ثابت روی خط زمین قفل می‌ماند.
   - clamp به عرض صفحه (کمانه‌کردن نرم از دیواره‌های چپ/راست، خط ۲۱۴۹-۲۱۵۷).
3. **ادغام (merge)** — `_mergeYolks()` (خط ۲۱۶۳-۲۱۹۴): هر جفت بلاب که فاصلهٔ مرکزشان کمتر از `(rA+rB)*0.78` باشد، بر اساس وزن مساحت (`area/total`) ادغام می‌شوند (موقعیت/سرعت وزن‌دار، شعاع از `sqrt(areaA+areaB)` با کلمپ `[7,36]`)؛ اگر یکی روی زمین بود، نتیجهٔ ادغام هم روی زمین قفل می‌شود.
4. **برخورد با گلوله** — `_nudgeYolksWithBullet(b)` (خط ۲۱۹۶-۲۲۰۸): فقط یک تلنگر سرعتی می‌دهد (گلوله از یولک عبور می‌کند، هیچ HP/تخریبی روی یولک نیست).
5. **پاک‌سازی** — `yolks.removeWhere((Y) => Y.removed)` در پایان `_stepYolks` (خط ۲۱۶۰) — ولی توجه: **هیچ‌جا `Y.removed=true` ست نمی‌شود مگر در ادغام** (خط ۲۱۹۱)؛ یعنی یولک‌ها به‌خودی‌خود منقضی نمی‌شوند و فقط با ادغام‌شدن در بلاب دیگر از بین می‌روند — عمر نامحدود (`life`/TTL ندارند).

**چرا این الگو برای Generalize کردن مناسب است:** این دقیقاً همان الگویی است که پروژه از قبل به‌صورت آگاهانه دارد generalize می‌کند. فایل جدید `lib/features/word_builder/presentation/widgets/angry_words/debris/wb_secondary_body.dart` یک `WbSecondaryBody`/`WbSecondaryPool`/`WbSecondaryWorld` عمومی دارد که `WbSecondaryKind.yolk` را به‌عنوان یکی از ۸ نوع «جسم ثانویهٔ درازمدت» (`coin, candy, seed, yolk, waxPool, oilPool, acidPool, fireSpot`) در کنار هم می‌گذارد (خط ۸-۱۷). کامنت‌های خودِ فایل صراحتاً می‌گویند:
- خط ۱۰۹: «Yolk path mirrors `AngryWordsPhysicsWorld` yolk logic»
- خط ۱۲۵: «Same spill recipe as legacy `AngryWordsPhysicsWorld.spillYolkAt`»
- خط ۲۹۲: «Exact merge rules from legacy `_mergeYolks` — no List alloc in hot path»
- خط ۳۲۲: «Legacy `_nudgeYolksWithBullet` behavior»

یعنی `spillYolkAt`, `_stepYolks`, `_mergeYolks`, `_nudgeYolksWithBullet` هرکدام یک متد معادل در `WbSecondaryWorld` دارند (`spillYolkAt`, `_stepYolk`, `_mergeYolks`, `nudgeYolksWithBullet`) با همان فرمول‌های عددی دقیق (کلمپ‌ها، ضرایب اصطکاک، `floor - radius*0.35` و غیره) — فقط با یک `pool` با ظرفیت ثابت (۱۲۰، به‌جای `List` بدون سقف) و یک enum گسترش‌یافته. **این فایل هنوز به گیم‌پلی متصل نشده** (هیچ ارجاعی از `angry_words_physics.dart` یا `angry_words_letter_board.dart` به `WbSecondaryWorld` پیدا نشد) — یعنی سیستم جدید کاملاً نوشته شده ولی wiring آن باقی مانده. طراحی سیستم عمومی prop archetype می‌تواند مستقیماً از همین abstraction استفاده کند به‌جای اختراع دوباره.

مشابه آن، `debris/wb_fluid_pool.dart` یک `WbFluidPoolSystem` عمومی برای «لکه‌های ماندگار روی زمین» (`wax, oil, acid, water, yolk`) دارد که مستقل از `WbSecondaryBody` است (احتمالاً برای رد پای بصری/استاتیک به‌جای جسم فیزیکی متحرک) — این هم wired نشده.

---

## ۷) رسم Damage State

پاسخ کوتاه: **بله، یک مکانیزم بصری برای کاهش HP وجود دارد، ولی محدود به «حلقهٔ زره + خطوط ترک ساده» است، نه یک اسپرایت/مرحلهٔ مجزا.**

در مسیر واقعاً فعال (`_paintProps`، بدون آرکی‌تایپ اتلس)، در `angry_words_painter.dart:1055-1103`:
```dart
if (P.maxHp >= 2 ||
    P.material == AngryWordsPropMaterial.stone ||
    P.material == AngryWordsPropMaterial.metal ||
    P.material == AngryWordsPropMaterial.gold ||
    P.material == AngryWordsPropMaterial.crystal) {
  ...
  final crack = 1.0 - (P.hp / P.maxHp).clamp(0.0, 1.0);
  canvas.drawCircle(c, r + 2.2, Paint()..color = armorColor... ); // حلقهٔ زره، رنگ بر اساس hp>=3
  if (crack > 0.15) {
    // ۱ خط ترک
    if (crack > 0.4) {
      // ۲ خط ترک دیگر (و اگر stone بود، خط سوم هم)
    }
  }
}
```
یعنی:
- یک **حلقهٔ استروک دور prop** همیشه رسم می‌شود وقتی `maxHp>=2` یا متریال «سخت» است؛ رنگش بین طلایی روشن (`hp>=3`) و نارنجی (کمتر) سوییچ می‌کند (خط ۱۰۶۰-۱۰۶۵) و ضخامتش با `hp>=3` بیشتر است.
- تعداد **خطوط ترک** به‌صورت پله‌ای با نسبت `crack = 1 - hp/maxHp` افزایش می‌یابد: هیچ خط (`crack<=0.15`) → ۱ خط (`>0.15`) → ۲ خط (`>0.4`) → اگر `material==stone` باشد یک خط سوم هم اضافه می‌شود (خط ۱۰۹۴-۱۰۹۹). خطوط ثابت هندسی هستند (مکان‌شان تصادفی/per-hit نیست)، فقط تعدادشان با پله‌های HP عوض می‌شود.
- همین منطق دقیقاً کپی شده برای مسیر ایموجی در `_paintEmojiProp` (خط ۱۲۴۰-۱۲۷۷)، با یک تفاوت ظاهری (بدون شاخهٔ ویژهٔ stone).
- علاوه بر این، `hitFlash` (فلاش سفید لحظه‌ای، خط ۱۱۲۴-۱۱۳۰) و `freezeT` (حلقهٔ یخ، خط ۱۱۰۴-۱۱۲۳) هم بازخورد بصری لحظه‌ای هستند ولی به HP گسسته نیستند — بلکه به «همین الان ضربه خورد» یا «یخ‌زده» مرتبطند، نه به پله‌های آسیب.

**اما یک مسیر دوم wired-نشده وجود دارد که دقیقاً مسئلهٔ «crack stage» را حل کرده:** در `atlas/wb_prop_atlas_paint.dart:50-63` و `atlas/wb_stage_atlas_pack.dart:61-73`، تابع `wbAtlasDamageStage({hp, maxHp, crackStages, atlasStages})` یک **ایندکس مرحلهٔ آسیب** برمی‌گرداند:
```dart
int wbAtlasDamageStage({required int hp, required int maxHp,
    required int crackStages, required int atlasStages}) {
  if (maxHp <= 1 || crackStages <= 0) return 0;
  final lost = (maxHp - hp).clamp(0, maxHp);
  if (lost <= 0) return 0;
  final stage = lost.clamp(1, crackStages);
  return stage.clamp(0, atlasStages - 1);
}
```
این مقدار به `WbAtlasSlotKey(archetypeIndex, damageStage, variant)` می‌رود (`wb_prop_atlas_paint.dart:88-100`) تا اسلات درست از یک **اتلس چندمرحله‌ای اسپرایت (per-archetype × per-damage-stage × per-variant)** انتخاب شود — یعنی هر آرکی‌تایپ می‌تواند چند اسپرایت جدا برای «سالم / کمی ترک‌خورده / خیلی ترک‌خورده» داشته باشد، دقیقاً بر اساس `WbArchetypeSpec.crackStages` (که در `wb_prop_archetype.dart` هرکدام مقدار ۰ تا ۲ دارند، مثل `woodCrate.crackStages=1`, `oilDrum.crackStages=2`). همچنین برای آرکی‌تایپ‌هایی با رفتار `crackCascade`/`spiderweb`، یک لایهٔ اورلی داینامیک ترک (`paintDynamicCrackOverlay`, فراخوانی در `wb_prop_atlas_paint.dart:178-186`) هم روی همان مرحله کشیده می‌شود.

فیلد `WbPropRuntime.damageStage` (`lib/features/word_builder/data/prop_archetypes/wb_prop_runtime.dart:30, 56`) هم دقیقاً برای همین منظور در سطح runtime نگه‌داری می‌شود، و `WbBreakHandler.onDamageStage(prop, newStage, ops)` (تعریف در `behaviors/wb_break_behavior_handler.dart:72`) هست تا رفتارهایی مثل `dentThenRupture`/`erode`/`crackCascade`/`spiderweb`/`ringDecay` هنگام رسیدن به یک مرحلهٔ جدید آسیب، افکت مخصوص خودشان (دندانه‌افتادن، صدای زنگ با pitch متفاوت، شاخهٔ ترک تازه) اجرا کنند — ولی این کل زیرسیستم (`WbPropRuntime`, `WbBreakHandler`, `wbAtlasDamageStage`) طبق بررسی بخش ۴ **در گیم‌پلی واقعی صدا زده نمی‌شود** (هیچ‌کدام از `angry_words_physics.dart` یا `angry_words_letter_board.dart` به این فایل‌ها ارجاع نمی‌دهند؛ فقط `wb_prop_atlas_paint.dart` از `wbAtlasDamageStage` استفاده می‌کند و آن هم چون `atlasPack` همیشه `null` است اجرا نمی‌شود).

**نتیجه برای طراحی «مرحلهٔ ترک» آینده:** پایهٔ کامل و آماده‌ای از قبل نوشته شده (`crackStages` per-archetype، `wbAtlasDamageStage`، `WbPropRuntime.damageStage`، `onDamageStage` هوک در هر `WbBreakHandler`) — کاری که باقی می‌ماند صرفاً **wiring** است: (۱) ساخت/تحویل واقعی `WbStageAtlasPack` به `AngryWordsBoardPainter.atlasPack` به‌جای `null`، یا (۲) اگر مسیر اتلس هنوز آماده نیست، پورت‌کردن همان منطق پلهٔ `crack` که الان به‌صورت hardcoded در `_paintProps`/`_paintEmojiProp` هست به یک تابع عمومی بر اساس `crackStages` واقعی هر آرکی‌تایپ به‌جای رشته‌شرط `maxHp>=2 || material∈{...}`.

---

## پیوست — فایل‌های خوانده‌شده در این تحقیق

- `lib/features/word_builder/presentation/widgets/angry_words/angry_words_loadout.dart` (working tree فعلی، ۲۰۸۰ خط — رجوع به «اصلاحیه» در ابتدای سند)
- `lib/features/word_builder/presentation/widgets/angry_words/angry_words_physics.dart` (۳۰۲۹ خط، کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/angry_words_painter.dart` (۳۵۰۴ خط، بخش‌های مرتبط با props/explosions/cargo کامل خوانده شد)
- `lib/features/word_builder/presentation/widgets/angry_words/angry_words_letter_board.dart` (۱۴۶۱ خط، کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/angry_words_cargo_plaque.dart` (۱۰۷ خط، کامل)
- `lib/features/word_builder/data/prop_archetypes/wb_prop_archetype.dart` (۱۸۱۲ خط، کامل)
- `lib/features/word_builder/data/prop_archetypes/wb_prop_sound_family.dart` (کامل)
- `lib/features/word_builder/data/prop_archetypes/wb_prop_runtime.dart` (کامل)
- `lib/features/word_builder/data/prop_archetypes/behaviors/wb_break_behavior_handler.dart` (کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/debris/wb_fluid_pool.dart` (کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/debris/wb_secondary_body.dart` (کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/atlas/wb_prop_atlas_paint.dart` (کامل)
- `lib/features/word_builder/presentation/widgets/angry_words/atlas/wb_stage_atlas_pack.dart` (بخش `wbAtlasDamageStage`)
- `lib/core/audio/angry_words_prop_break_audio.dart` (کامل)
- `.cursor/docs/12-word-builder-angry-words-spec.md` — **پیدا نشد** (کل پوشه وجود نداشت)

هیچ فایل کدی توسط این تحقیق تغییر نکرد؛ فقط همین فایل گزارش ساخته شد.
