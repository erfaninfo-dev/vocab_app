# Erfan Academy

Flutter app for IELTS vocabulary learning with:
- Unit-first navigation (`Unit 1`, `Unit 2`, ...)
- Section drill-down (`1`, `2`, `3`)
- Word cards, search, favorites, difficult words, flashcards
- Light/dark theme and Persian meaning support (RTL)

## Tech Stack
- Flutter (Material 3)
- `flutter_riverpod` for state management
- `go_router` for navigation
- `shared_preferences` for local persistence

## Project Structure

```text
lib/
  core/
    router/
    theme/
  data/
    models/
    repositories/
    services/
  domain/
  features/
    splash/
    units/
    sections/
    words/
    flashcards/
    favorites/
    settings/
assets/
  data/
tool/
  convert_excel.dart
```

## Setup
1. Install Flutter stable.
2. In project root, run:
   - `flutter pub get`
3. Launch app:
   - `flutter run`

## Dataset Format
Input rows must contain columns:
- `Word`
- `type`
- `meaning_en`
- `meaning_fa`
- `example`
- `Unit` in the format `section-unit` (example: `2-5`)

Rules:
- `1-2` means **Unit 2**, **Section 1**
- Units are sorted ascending
- Sections are shown in order `1, 2, 3`

## Replace Sample Data With Your Excel

### Option A: Convert Excel to JSON using provided script
1. Put your Excel file in project folder, for example: `data/words.xlsx`
2. Run:
   - `dart run tool/convert_excel.dart data/words.xlsx assets/data/sample_words.json`
   - Optional sheet name:
     `dart run tool/convert_excel.dart data/words.xlsx assets/data/sample_words.json Sheet1`
3. Restart app.

### Option B: Generate JSON yourself
Create/replace `assets/data/sample_words.json` with a JSON array of row objects.

## Notes
- Empty or malformed rows are skipped safely.
- Missing optional fields (like `example`) are allowed.
- Favorites and difficult words are stored locally on device.
