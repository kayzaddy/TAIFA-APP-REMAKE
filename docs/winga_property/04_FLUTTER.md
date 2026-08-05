# Winga Property — Flutter (Phase 1)

## Routes

| Route | Screen |
| --- | --- |
| `/winga-property` | `WingaPropertyScreen` |

## Structure

```
features/winga_property/
  domain/property_models.dart
  application/property_repository.dart
  application/property_providers.dart
  application/seed_property_repository.dart
  presentation/winga_property_screen.dart
  presentation/property_detail_sheet.dart

data/winga_property/
  property_api_paths.dart
  rest_property_repository.dart
```

## Remote mode

```bash
flutter run -d windows \
  --dart-define=TAIFA_USE_REMOTE=true \
  --dart-define=TAIFA_API_BASE_URL=http://127.0.0.1:8000
```

Navigate to `/winga-property` or deep-link from super-app catalog.

## Features

- Search bar + category chips
- Verified listing cards with photos
- Map toggle with pin chips
- Detail sheet (photos, video tour link, verification badge)
- Favorites toggle
