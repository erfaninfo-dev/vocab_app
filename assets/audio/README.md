# App audio assets

Place MP3 (or WAV/OGG) files in this folder. Filenames must be **snake_case with lowercase extensions** (Android assets are case-sensitive). If a file is missing, playback is skipped — the app will not crash.

## Unit sample book mode

| File | Purpose | Suggested length |
|------|---------|------------------|
| `page_flip.mp3` | Paper page-turn when swiping in book reader | ~0.2–0.5 s |

Toggle in book mode header (speaker icon, top-left beside title). Preference key: `sample_book_page_sound_enabled_v1` (default on).

## Splash

| File | Purpose |
|------|---------|
| `splash_chime.mp3` | Soft startup chime (~1.5–2 s) |

## Global Settings → Sound

| Preference key | Toggle | Default |
|----------------|--------|---------|
| `sound_music_enabled_v1` | Music (BGM) | true |
| `sound_sfx_enabled_v1` | Sound effects | true |
| `sound_haptics_enabled_v1` | Haptics / vibration | true |

On first launch after upgrade, legacy keys (`splash_sound_enabled`, `word_builder_session_sfx_v1`, `word_builder_session_bgm_v1`) migrate into all three when the new keys are absent.

## Word Builder game

| File | Purpose | Suggested length |
|------|---------|------------------|
| `word_success.mp3` | Short positive ding when a word is found | ~0.2–0.6 s |
| `word_error.mp3` | Soft “buzz” or low tone when the path is wrong | ~0.15–0.5 s |
| `level_success.mp3` | Bigger fanfare when the whole stage/level is finished | ~1.0–2.5 s |
| `letters_pop.mp3` | Bubble pop when a correct Angry Words letter explodes | ~0.15–0.5 s |
| `shot2.wav` | Angry Words cage-phase blaster (primary) | ~0.1–0.15 s |
| `shot.wav` | Angry Words blaster variant (50/50 with shot2) | ~0.1–0.2 s |
| `pop.wav` | Angry Words candy / barrier bubble pop | ~0.1–0.2 s |
| `pot.mp3` | Porcelain jug / glass bottle break | ~0.15–0.4 s |
| `egg_crack.wav` | Free-phase letter-egg crack (distinct from pop) | ~0.1–0.25 s |
| `sling_stretch.wav` | Slingshot rubber stretch loop while pulling | ~1.0–1.5 s, loopable |
| `sling_snap.wav` | Slingshot release snap | ~0.1–0.25 s |
| `sling_whoosh.wav` | Ball flight whoosh after release | ~0.15–0.4 s |

Full Angry Words audio/game docs: `.cursor/docs/12-word-builder-angry-words-spec.md`.

### Train-escape tray scenario

| File | Purpose |
|------|---------|
| `train_horn.mp3` | Horn on wrong answer |
| `rope_snap.mp3` | Rope snap on correct word |
| `train_approach.mp3` | Rumble loop at high tension |
| `train_pass.mp3` | Train pass on level complete |
| `train_brake.mp3` | Brake before game-over |

Optional — missing files are skipped without crashing.

### Prison-escape tray scenario

| File | Purpose |
|------|---------|
| `guard_stir.mp3` | Stir on wrong answer |
| `key_jingle.mp3` | Key on correct word |
| `door_unlock.mp3` | Door unlock on victory |
| `guard_wake.mp3` | Guard wake before game-over |
| `heartbeat.mp3` | Heartbeat at high tension |

Optional — missing files are skipped without crashing.

**Tips:** Prefer short clips; normalize ~-14 to -18 LUFS; export MP3 128–192 kbps.
