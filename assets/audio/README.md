# App audio assets

Place MP3 (or WAV/OGG) files in this folder. If a file is missing, playback is skipped — the app will not crash.

## Unit sample book mode

| File | Purpose | Suggested length |
|------|---------|------------------|
| `page_flip.mp3` | Paper page-turn when swiping in book reader | ~0.2–0.5 s |

Toggle in book mode header (speaker icon, top-left beside title). Preference key: `sample_book_page_sound_enabled_v1` (default on).

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
| `letters_pop.MP3` | Bubble pop when a correct Angry Words letter explodes | ~0.15–0.5 s |
| `shot2.WAV` | Angry Words cage-phase blaster — one shot per bullet | ~0.1–0.15 s |
| `pop.WAV` | Angry Words candy / barrier bubble pop (one pop) | ~0.1–0.2 s |
| `sling_stretch.wav` | Slingshot rubber stretch **loop** while pulling; volume 0.15→1.0 and speed/pitch 0.85→1.25 follow tension | ~1.0–1.5 s, loopable |
| `sling_snap.wav` | Elastic snap on sling release | ~0.15–0.4 s |
| `sling_whoosh.wav` | Flight whoosh after a strong release | ~0.15–0.4 s |
| `egg_crack.wav` | Eggshell crack when a letter-egg / egg prop breaks | ~0.15–0.4 s |
| `canshoot.mp3` | Soda can dent / rupture; oil barrel first hit | ~0.2–0.6 s |
| `items/explosion.mp3` | Oil barrel final boom (second hit) | ~0.4–1.2 s |
| `pot.mp3` | Ceramic / glass / metal clang family (`breakCeramic`, `shatterGlass`, `clangMetal`) | ~0.2–0.5 s |

### Angry Words prop break families (`WbPropSoundFamily`)

All eight families remap onto existing assets (no new APK files required). Pitch stays inside each family's band; archetype `soundPitch` must fall in range. Cap concurrent plays in `AngryWordsPropBreakAudio` (6 / Windows 3).

| Family | Asset | Pitch range | Typical archetypes |
|--------|-------|-------------|--------------------|
| `popSoft` | `pop.WAV` | 1.1–1.35 | balloon, foam, plastic |
| `shatterGlass` | `pot.mp3` | 1.0–1.3 | glassBottle, iceBlock, crystal |
| `breakCeramic` | `pot.mp3` | 0.85–1.0 | ceramicJug, brick |
| `thudWood` | `pop.WAV` | 0.7–0.9 | woodCrate, woodBarrel, powderKeg |
| `clangMetal` | `pot.mp3` | 0.65–0.9 | tinCan, bronzeBell, steelPlate, goldTrophy |
| `crumbleStone` | `pop.WAV` | 0.5–0.7 | sandstone, concreteBlock, graniteBlock, stoneStatue |
| `splashFluid` | `pop.WAV` | 0.9–1.1 | watermelon, egg, magmaOrb, oilLamp |
| `sparkEnergy` | `shot2.WAV` | 1.1–1.4 | neonOrb, fireworkShell, discoBall |

**Special:** `bronzeBell` `ringDecay` hit pitches are fixed **1.2 / 1.0 / 0.8** by remaining HP (no jitter) so the player can hear HP.

Egg props still use dedicated `egg_crack.wav` via `AngryWordsEggCrackAudio`, not the family table.

Soda cans (`sodaCan`) use `canshoot.mp3` via `AngryWordsCanShootAudio` on dent and final pop. Oil drums (`oilDrum`) use `canshoot.mp3` on the first dent and `items/explosion.mp3` via `AngryWordsExplosionAudio` on the final boom.

### Train-escape tray scenario (odd levels)

| File | Purpose | Suggested length |
|------|---------|------------------|
| `train_horn.mp3` | Horn blast on every wrong answer | ~0.5–1.2 s |
| `rope_snap.mp3` | Rope snapping on every correct word | ~0.2–0.6 s |
| `train_approach.mp3` | Rumble loop while the train is close (2+ wrongs); volume ramps with tension | ~2–5 s, loopable |
| `train_pass.mp3` | Train rushing past after the character escapes (level complete) | ~1–2 s |
| `train_brake.mp3` | Screeching brake right before the game-over modal | ~1–2 s |

All train files are optional — missing files are skipped without crashing (same as the water sounds).

### Prison-escape tray scenario (every 3rd level)

| File | Purpose | Suggested length |
|------|---------|------------------|
| `guard_stir.mp3` | Soft stir / chair creak on every wrong answer | ~0.3–0.8 s |
| `key_jingle.mp3` | Key jingle on every correct word / key grab | ~0.2–0.6 s |
| `door_unlock.mp3` | Cell door unlock during victory escape | ~0.6–1.5 s |
| `guard_wake.mp3` | Guard waking up right before game-over modal | ~0.8–1.8 s |
| `heartbeat.mp3` | Heartbeat loop while tension is high (2+ wrongs); volume ramps | ~1–3 s, loopable |

All prison files are optional — missing files are skipped without crashing.

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
