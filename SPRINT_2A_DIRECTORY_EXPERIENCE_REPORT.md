# Sprint 2A — Directory Experience Report

**Date:** 2026-07-24
**Baseline:** `v0.1-baseline` (commit `505c39e`)
**Scope:** Directory experience only. Search, advanced maps, provider-page redesign, reviews and favorites expansion remain out of scope.

## Executive summary

Sprint 2A is implemented on the existing Express/Prisma, Flutter and Next.js architecture. The public directory now has active-only taxonomy filtering, stable paged responses, optional metadata for load-more, deterministic sorting, Cairo-time open-now status and safe handling for missing optional data. Flutter consumes the paged contract with category/area selectors, reset, retry, pull-to-refresh and deduplicated load-more. Admin analytics exposes low-impact provider data-quality indicators.

## Existing behavior reviewed

- `GET /api/providers` previously paged before open-now filtering, sorted rating/reviews only inside one page, used server-local time, and returned no pagination metadata.
- Flutter treated category chips as text search, loaded one list page, kept no explicit taxonomy selection and did not offer load-more.
- Public category/area endpoints already filtered `isActive`; provider category joins and area visibility were not consistently constrained.
- Provider-per-location is the current representation. There is no `Branch` model, so no branch migration was introduced.
- Admin provider CRUD and moderation already existed; reporting exposed only missing location/phone indicators.

## Problems and UX gaps found

1. Invalid page/page-size/sort values were silently coerced instead of rejected.
2. Inactive areas/categories could leak into provider results through direct filters/joins.
3. Open-now used the host timezone and ignored `openingHours` JSON and invalid values.
4. Rating/review sorting had no stable ID tie-breaker and pagination could be inconsistent.
5. The directory had no explicit category/area selection state or load-more affordance.
6. Providers without coordinates were retained in a nearby distance filter, which was misleading.
7. Admin quality reporting did not expose missing category/image/hours or inactive-area references.

## Implemented scope

### API

- Added validated directory pagination and sort enums.
- Preserved the legacy array response by default; `meta=true` adds `{data,total,page,pageSize,hasMore}`.
- Added active-area and active-category visibility constraints.
- Added deterministic name/latest/rating/review-count/nearest ordering with ID/name tie-breakers.
- Added `rating`, `reviewCount` and `openNow` metadata. Open-now uses `Africa/Cairo`, validates `HH:MM`, supports overnight ranges and simple daily JSON/array ranges, and returns `null` for absent/invalid hours.
- Kept approved, non-archived, non-deleted public visibility rules.
- Extended admin report quality counts for category, image, hours and inactive-area references.

### Flutter

- Added a typed `ProviderPage` client for paged directory responses while keeping the existing list client compatible with legacy callers.
- Added active category/area controls, visible selected state through the filter sheet, reset, nearest option and load-more with ID deduplication.
- Sent coordinates only when available; denied/unavailable location falls back to a normal directory instead of blocking use.
- Added safe open-now status to provider cards and excluded coordinate-less items from an explicit nearby distance filter.
- Preserved existing loading, empty, retry, pull-to-refresh and image fallback behavior.

### Admin

- Added quality indicators to the existing analytics table without a redesign or automatic deletion/merge.

## Out of scope

- Sprint 2B unified search.
- Sprint 2C map clustering/spatial optimization.
- Sprint 2D provider-page/reviews/favorites redesign.
- Branch schema, category hierarchy, authentication/session changes, push notifications and external Google/Apple setup.

## Database changes and migrations

No schema or Prisma migration was required. Existing provider-per-location, flat category and area models remain unchanged.

## Tests added

The existing production-stabilization integration suite now includes:

- inactive category/area public filtering;
- stable page boundaries without duplicate IDs;
- invalid pagination/sort rejection;
- safe sparse-provider response fields;
- Cairo open-now, overnight and invalid-hours cases.

The isolated suite ran **78/78 tests** against PostgreSQL 15 in Docker Compose.

## Commands executed and results

| Command | Result |
|---|---|
| `npm run prisma:generate` (API) | Pass |
| `npm run test:db` (Docker Compose, migrations + Jest) | Pass — 8 suites, 78 tests |
| `npm run build` (API) | Pass |
| `npm run lint` (Web/Admin) | Pass |
| `npm run build` (Web/Admin) | Pass |
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | Pass with pre-existing non-fatal infos/warnings; no errors |
| `flutter test` | Pass — 8/8 |
| `git diff --check` | Pass |
| Documentation secret scan | Pass; only placeholder values in README |

The first test attempt used the developer database before the isolated workflow and exposed stale schema columns; no production data was changed. The test workflow was then run through Docker Compose after starting the local Colima engine and passed.

## Files modified

- `apps/api/src/server.ts`
- `apps/api/src/__tests__/production-stabilization.integration.test.ts`
- `apps/api/scripts/test-db.sh`
- `apps/mobile/lib/core/network/api_client.dart`
- `apps/mobile/lib/main.dart`
- `apps/web/app/admin/analytics/page.tsx`
- `docs/CHANGELOG.md`, `docs/API_REFERENCE.md`, `docs/TESTING_GUIDE.md`, `docs/DOCUMENTATION_GAPS.md`, `docs/FEATURE_STATUS.md`, `docs/ROADMAP.md`, `docs/DOCUMENTATION_INDEX.md`
- `README.md`, `CONTRIBUTING.md`, `PROJECT_ACTIVITY_LOG.md`

## Known limitations and remaining risks

- The current distance order is a coordinate-distance approximation in application code, not a PostGIS query; optimize in Sprint 2C if catalog scale requires it.
- `openingHours` accepts a small set of compatible JSON shapes; a formal multi-period schema remains technical debt.
- Physical-device directory verification, VPS browser verification and external OAuth remain environment-dependent and unverified here.
- Existing Flutter analyzer warnings remain non-fatal and pre-date Sprint 2A.

## Commit and tag

- Implementation commit: `5622296` (`feat(directory): complete Sprint 2A directory experience improvements`).
- Final report commit: `eae774b`.
- Tag: `v0.2-directory` created as an annotated tag on the final report commit.

## Go / No-Go for Sprint 2B

**GO for planning Sprint 2B**, subject to the remaining physical/VPS verification items being tracked separately. No critical directory, authorization or upload regression was introduced in the available automated validation.
