# 9. Deployment Guide

1. Ensure Payments + Enterprise apps migrated.
2. `python manage.py migrate acceptance`
3. `python manage.py seed_map` (optional demo merchant)
4. Expose `/api/v1/map/` behind same API gateway as payments.
5. Set `MAP_SIGNING_SECRET` (optional; defaults to `SECRET_KEY`).
6. Mobile: `--dart-define=TAIFA_USE_REMOTE=true` for live MAP.

No separate MAP database or settlement workers — capture is synchronous via enterprise orchestrator.
