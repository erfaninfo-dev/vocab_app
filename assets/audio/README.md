# App audio assets

Place MP3 (or WAV/OGG) files in this folder. If a file is missing, playback is skipped — the app will not crash.

## Splash

| File | Purpose |
|------|---------|
| `splash_chime.mp3` | Soft startup chime (~1.5–2 s) |

Toggle: **Settings → Sound → Startup chime**.

## Word Builder game

| File | Purpose | Suggested length |
|------|---------|------------------|
| `word_success.mp3` | Short positive ding when a word is found | ~0.2–0.6 s |
| `word_error.mp3` | Soft “buzz” or low tone when the path is wrong | ~0.15–0.5 s |
| `level_success.mp3` | Bigger fanfare when the whole stage/level is finished | ~1.0–2.5 s |

These use the same **Startup chime** toggle in Settings until a separate game-sound switch is added.

### Where to find free sounds (Google / web)

Use **royalty-free** libraries (Pixabay, Kenney, Freesound CC0). Always check the license.

**English search terms**

| Need | Example searches |
|------|------------------|
| Correct word | `game success sound effect short`, `positive ding ui`, `correct answer sfx` |
| Wrong guess | `game wrong answer sound`, `error buzz ui short`, `negative feedback sfx` |
| Stage complete | `level complete fanfare`, `victory jingle short`, `game stage clear sfx`, `success fanfare mobile game` |

**Persian / Farsi (for Google)**

| Need | Example searches |
|------|------------------|
| درست | `صدای موفقیت بازی کوتاه`, `افکت صوتی پاسخ درست بازی` |
| اشتباه | `صدای اشتباه بازی`, `افکت خطا بازی موبایل` |
| پایان مرحله | `صدای تمام شدن مرحله بازی`, `فانفار پیروزی کوتاه` |

**Direct sites**

- https://pixabay.com/sound-effects/ — search: `success`, `wrong`, `victory fanfare`
- https://kenney.nl/assets/interface-sounds — CC0 UI pack (rename files after download)
- https://freesound.org/ — filter **CC0** only

**Tips**

- Prefer **short** clips; trim in Audacity if needed.
- Normalize volume (roughly -14 to -18 LUFS); the app also scales volume per effect.
- Export as **MP3** 128–192 kbps for smaller APK size.
