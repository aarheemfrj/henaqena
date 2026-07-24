# Testing Guide

**Last verified:** 2026-07-24
**Source of truth:** package scripts, `.github/workflows/ci.yml`, `apps/api/src/__tests__`, `apps/mobile/test`
**Status:** Verified; remote CI and physical OAuth remain Unverified
**Owner:** QA/Engineering

## Test layers

1. **API build/type check:** `npm run build`.
2. **API integration:** Jest + Supertest against real isolated PostgreSQL; Sprint 2A extends the suite to 78 runtime tests.
3. **Web quality:** Next.js ESLint and production build.
4. **Flutter:** analyzer with existing non-fatal infos/warnings and widget tests.
5. **Manual staging:** auth, moderation, ownership, media replacement/deletion, imports, archive and restore.

## Isolated database workflow

```bash
cd apps/api
npm run test:db
```

The script starts `docker-compose.test.yml`, waits for PostgreSQL, runs `prisma migrate deploy`, runs integration tests and removes the test volume. A local Postgres database can be used only when its name/URL is explicitly isolated from development and production.

## Required regression coverage

- blocked session/password/federated login
- approved-only public providers and owner pending visibility
- favorite-list/provider/listing ownership
- invalid bytes, MIME mismatch and oversized image rejection
- map bounds validation, approved-only marker visibility, missing-coordinate exclusion and Haversine distance
- local replacement/deletion and remote URL preservation
- taxonomy duplicate/deactivation behavior
- active-only directory taxonomy, stable pagination, invalid directory query rejection and Cairo open-now edge cases
- admin actor/role audit metadata and protected accounts

## Manual staging checklist

1. Apply migrations with `prisma migrate deploy`; verify row counts.
2. Register/login/logout and block/unblock a disposable user.
3. Submit and moderate provider/listing/review/ad content.
4. Replace avatar/provider/listing images and inspect filesystem cleanup.
5. Try another user’s IDs and confirm 403/404.
6. Import data, archive a record and restore a backup into a separate database.
7. Verify admin roles and owner boundaries in the browser.
8. Complete Google/Apple checks on physical devices when credentials are available.

## CI expectations

CI must fail on migration, integration, build, lint, analyze or test errors. Warnings may remain non-fatal only where the existing Flutter configuration explicitly permits them. Never weaken a failing check to hide a regression.

## مين شاطر coverage

The isolated PostgreSQL integration suite covers guest/authenticated/blocked access, pending-to-approved visibility, owner IDOR checks, approved-provider and manual recommendations, duplicate prevention, closed-request rejection, helpful idempotency, reports and admin moderation. Run `npm run test:db` from `apps/api`; the suite creates and migrates a disposable Docker database.
