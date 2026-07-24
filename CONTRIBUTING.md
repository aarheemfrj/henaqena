# Contributing to Hena Qena

**Last verified:** 2026-07-24
**Source of truth:** repository scripts, CI and [Project Structure](./docs/PROJECT_STRUCTURE.md)
**Status:** Verified
**Owner:** Engineering

## Before coding

Read [Documentation Index](./docs/DOCUMENTATION_INDEX.md), the relevant feature status, and the current Sprint reports. Treat `apps/api/src/server.ts` and `apps/api/prisma/schema.prisma` as runtime authorities.

## Change rules

- Keep API validation, authorization and ownership checks server-side.
- Do not edit an applied Prisma migration; add a new migration with a clear name.
- Do not commit `.env`, credentials, tokens, uploads, backups or simulator artifacts.
- Preserve remote media URLs during local cleanup.
- Update the relevant docs and `PROJECT_ACTIVITY_LOG.md` when behavior or deployment contracts change.
- Avoid adding routes to legacy `apps/api/src/app.ts`; production is `src/server.ts`.

## Validation

```bash
cd apps/api && npm ci && npm run prisma:generate && npm run build && npm run test:integration
cd apps/web && npm ci && npm run lint && npm run build
cd apps/mobile && flutter pub get && flutter analyze --no-fatal-warnings --no-fatal-infos && flutter test
git diff --check
```

Use `apps/api/npm run test:db` (from the API directory) for a disposable PostgreSQL run. Never use a production database for tests.

## Reviews

Describe the user-visible behavior, authorization impact, migration/rollback plan and tests. Flag anything marked Unverified. Security-sensitive changes need a reviewer familiar with sessions, uploads and IDOR controls.

## Commit hygiene

Make focused commits with imperative messages. Keep generated output out of commits. If a change is documentation-only, state that explicitly.
