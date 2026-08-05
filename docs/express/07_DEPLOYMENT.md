# Taifa Express — Deployment

## Backend

```bash
cd apps/backend
.venv/Scripts/python.exe manage.py migrate express
.venv/Scripts/python.exe manage.py seed_express
.venv/Scripts/python.exe manage.py test express
```

Register: `express.apps.ExpressConfig` in `INSTALLED_APPS`  
URL: `path("api/v1/express/", include("express.urls"))`

## Mobile

```bash
cd apps/mobile
flutter run -d windows \
  --dart-define=TAIFA_USE_REMOTE=true \
  --dart-define=TAIFA_API_BASE_URL=http://127.0.0.1:8000
```

Route: `/express`  
Offline seed: `SeedExpressRepository` when remote is off.

## Dependencies

- Payments wallet funded for payer device id  
- Commerce platform merchant (`ensure_platform_commerce_merchant(sector="express")`)  
- Trips delivery bike pricing for rider assignment (best-effort if no drivers)
