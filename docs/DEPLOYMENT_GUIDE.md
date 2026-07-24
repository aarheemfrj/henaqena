# Deployment Guide

**Last verified:** 2026-07-24
**Source of truth:** `deploy.sh`, `infra/ecosystem.config.cjs`, `infra/Caddyfile`, `.github/workflows/ci.yml`, package scripts
**Status:** Local/staging procedure verified; remote CI run and final VPS browser smoke test remain Unverified
**Owner:** Release/Operations

## Local development

1. Start PostgreSQL (Docker via `infra/docker-compose.yml` or local Postgres.app).
2. Configure `apps/api/.env` from `.env.example`.
3. In `apps/api`: `npm ci`, `npm run prisma:generate`, `npm run prisma:migrate`, then `npm run dev` (default API port 4000).
4. In `apps/web`: `npm ci`, set API URLs, then `npm run dev` on port 3100.
5. In `apps/mobile`: `flutter pub get`, then run with safe `--dart-define` values. See [Environment Variables](./ENVIRONMENT_VARIABLES.md).

## Test database

Use `cd apps/api && npm run test:db`. It starts `docker-compose.test.yml`, waits for health, applies `prisma migrate deploy`, runs integration tests, and removes the named volume. Never point this command at a production URL.

## CI

GitHub Actions starts PostgreSQL 16, runs Prisma generate/migrations, API integration tests/build, web lint/build and Flutter analyze/test. The workflow is `.github/workflows/ci.yml`; a remote run was not observed during Sprint 1.5.

## Staging and production

- Apply migrations with `npx prisma migrate deploy` from `apps/api` using the intended database URL.
- Build API with `npm run build`; build web with `npm run build`.
- Use PM2 config in `infra/ecosystem.config.cjs`: API on 4000 and web on 3100 unless the deployment environment explicitly maps ports.
- Put Caddy/CloudPanel in front for HTTPS and route the public domain to web/API.
- Persist `UPLOADS_DIR` and backup storage outside build directories.
- Start/reload with the repository `deploy.sh`; inspect its preflight and secret prompts rather than embedding values.

## Backup, restore and rollback

Create a custom-format `pg_dump --format=custom --no-owner`, verify with `pg_restore --list`, and restore only to a separate database first. Keep the previous application build and migration status available before a rollback. Never overwrite active production while testing a restore.

## Health and troubleshooting

- `GET /health` checks basic API availability; `/ready` is the readiness path.
- Check PM2 logs and PostgreSQL connectivity before assuming a code regression.
- A port conflict usually indicates an existing PM2 process; do not start a second server blindly.
- If images fail, verify upload directory ownership, disk space and `PUBLIC_API_BASE_URL`.

## Release gate

API integration tests against isolated PostgreSQL, API build, web lint/build, Flutter analyze/test, `git diff --check`, migration deploy on staging, backup restore, and auth/upload/ownership smoke checks must pass. Physical OAuth and remote browser admin checks are separately marked Unverified until performed.

Related: [Release Checklist](./RELEASE_CHECKLIST.md), [VPS Deployment](./VPS_DEPLOYMENT.md), [Security Model](./SECURITY_MODEL.md).
