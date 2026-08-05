# 8. Deployment Guide

1. Build Flutter app as today (`apps/mobile`).
2. Point `TAIFA_API_BASE_URL` at the Taifa API gateway.
3. Enable remote: `TAIFA_USE_REMOTE=true`.
4. No separate Super App backend deploy.

Feature flags: `SuperAppFlags` in `features/super_app/domain/feature_flags.dart`.
