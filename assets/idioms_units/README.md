# Idioms for Speaking — unit illustrations

Map by **category title** (`unit_details` slug), not unit number — DB unit
order may differ from the book list.

| Category (slug) | File |
|-----------------|------|
| Age | `age_pic.webp` |
| Cities & Places | `city_pic.webp` |
| Communication | `communication_pic.webp` |
| Education | `education_pic.webp` |
| Entertainment & Free Time | `entertainment_pic.webp` |
| Environment | `environment_pic.webp` |
| Experiences & Memories | `experience_pic.webp` |
| Food | `food_pic.webp` |
| Friendship & Helping Others | `friendship_pic.webp` |
| Future & Plans | `futureplans_pic.webp` |
| Health & Lifestyle | `health_pic.webp` |
| Home & Family | `home_pic.webp` |
| Love & Relationships | `love_pic.webp` |
| Money | `money_pic.webp` |
| Negative Feelings | `negativefeeling_pic.webp` |
| Nature | `nature_pic.webp` |
| Opinions & Decisions | `opinion_pic.webp` |
| People & Personality | `people_pic.webp` |
| Shopping | `shopping_pic.webp` |
| Stress & Problems | `problems_pic.webp` |
| Success & Achievement | `achievement_pic.webp` |
| Positive Feelings | `positivefeeling_pic.webp` |
| Technology | `technology_pic.webp` |
| Time | `time_pic.webp` |
| Transport | `transport_pic.webp` |
| Travel | `travel_pic.webp` |
| Weather | `weather_pic.webp` |
| Work & Career | `work_pic.webp` |

Add slugs in `idioms_units_constants.dart` → `_kIdiomsAssetBySlug`.

**Format:** use **lossless** WebP (`VP8L`). Lossy WebP often fails silently on Flutter desktop (Windows/macOS/Linux).

### Image slot

All cards use the same illustration box (72% card width × 52% card height).
Optional per-file tweak: `kIdiomsImageSlotScaleByAsset` in `idioms_units_constants.dart`.
