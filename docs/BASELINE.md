# Hena Qena v0.1 Baseline

**Baseline Version:** `v0.1-baseline`
**Date:** 2026-07-24
**Source of truth:** Git tag, Sprint reports, current repository and [Documentation Index](./DOCUMENTATION_INDEX.md)
**Status:** Established
**Owner:** Engineering

## Current Architecture

- Flutter mobile client in `apps/mobile`.
- Next.js 16 web/admin application in `apps/web`, served on the project’s web port.
- Node.js/Express production API at `apps/api/src/server.ts`.
- Prisma ORM with PostgreSQL migrations.
- Local filesystem uploads with validated image bytes and cleanup safeguards.
- PM2/CloudPanel/Caddy deployment assets and GitHub Actions validation.

## Completed Sprints

- **Sprint 1 — Production Stabilization — Closed.** Authentication blocking, upload validation/cleanup, authorization/IDOR protection, taxonomy safety and audit metadata were stabilized.
- **Sprint 1.1 — Production Verification & Integration Testing — Closed.** Isolated PostgreSQL runtime tests, staging migration, backup/restore and CI workflow were verified.
- **Sprint 1.5 — Engineering Documentation — Closed.** Engineering documentation, route coverage, internal-link validation and final build checks were completed.

## Current Feature Status

The authoritative matrix is [FEATURE_STATUS.md](./FEATURE_STATUS.md). Core authentication, directory, listings, reviews, favorites, notifications, admin moderation, imports and internal maps are implemented or partial. Google/Apple physical-device verification, push delivery, object storage, owner self-service portal, category hierarchy and access/refresh-token rotation remain partial, unverified or planned.

## Production Blockers

- Physical Google Sign-In verification on iOS and Android.
- Apple Sign-In callback/device verification.
- Final production secret rotation and confirmation of deployment secret wiring.
- Browser-driven admin smoke test against the live VPS.
- Push notification provider and object-storage decisions before scaling.

These blockers prevent a public production release, but do not prevent starting Sprint 2 development.

## Documentation Status

The required Sprint 1.5 documentation set is present, indexed and internally linked. The API reference covers all top-level routes and the mounted data-collection router. Documentation gaps remain explicitly marked rather than silently assumed complete.

## Test Status

- API build: passed.
- API integration suite: 75/75 passed against isolated PostgreSQL and staging during Sprint 1.1.
- Web lint/build: passed.
- Flutter analyze: passed with existing non-fatal infos/warnings only.
- Flutter tests: 8/8 passed.
- Backup restore and migration verification: passed on separate databases.

## CI Status

GitHub Actions contains API PostgreSQL migration/integration/build, web lint/build and Flutter analyze/test jobs. The workflow is configured and reviewed; an independently observed remote GitHub Actions run remains an operational follow-up.

## Known Technical Debt

- Single bearer sessions; access/refresh-token rotation is deferred.
- Flat categories without parent/child relations or audited merge workflow.
- Local filesystem media rather than object storage and scanning pipeline.
- Push delivery is not implemented in the API.
- Legacy `apps/api/src/app.ts` remains for older tests and is not the production entry point.
- Existing Flutter analyzer infos/warnings should be reduced before store release.

## Next Sprint Objective

Sprint 2 should begin with production verification closure and directory trust improvements: complete external authentication/device checks, strengthen contract/owner/admin smoke coverage, improve moderation/import observability, and reduce remaining client warnings without bypassing the documented security and migration gates.
