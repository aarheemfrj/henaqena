# Sprint 2D — Provider Experience, Reviews & Favorites Report

**Date:** 2026-07-24  
**Status:** Completed for the scoped API/mobile contract and local verification.

## Scope and guardrails

This sprint covered provider detail, gallery/contact presentation, reviews/replies/helpful reactions, and favorites. No new product module, authentication/session redesign, map SDK, booking, owner portal, or database migration was introduced.

## What existed

- Provider detail, media gallery/full-screen viewer, contact actions, reviews, replies, helpful reactions and favorite lists were already present.
- Provider detail allowed an authenticated owner to view a pending provider and public users to view approved providers.
- Review editing, moderation and favorite-list ownership checks already existed.

## Findings and fixes

1. Public provider detail could serialize internal lifecycle/ownership fields. Replaced the broad response with an explicit safe projection and a viewer-only `isOwner` flag.
2. Provider detail nested reviews were unbounded. The detail contract now returns a bounded first page (20); a dedicated paginated reviews endpoint was added with a maximum page size of 30.
3. Rating was calculated only from the first nested page. It is now an aggregate over all approved reviews.
4. Inactive areas are excluded from provider detail visibility.
5. Owners can no longer review their own provider; review creation validates approved provider visibility and active area.
6. Review replies are restricted to the provider owner, and helpful votes require an approved visible review.
7. Review authors can delete their own review through `DELETE /api/me/reviews/:id`, with an audit entry.
8. Flutter now exposes the aggregate rating/count/open state, supports pull-to-refresh on provider detail, deduplicates gallery URLs, and hides the reply action from non-owners.

## Files changed

- `apps/api/src/server.ts`
- `apps/api/src/__tests__/production-stabilization.integration.test.ts`
- `apps/mobile/lib/core/network/api_client.dart`
- `apps/mobile/lib/main.dart`
- `docs/API_REFERENCE.md`
- `docs/BUSINESS_RULES.md`
- `docs/SECURITY_MODEL.md`
- `docs/FEATURE_STATUS.md`
- `docs/ROADMAP.md`
- `docs/CHANGELOG.md`
- `SPRINT_2D_PROVIDER_EXPERIENCE_AUDIT.md`
- `PROJECT_ACTIVITY_LOG.md`

## Database migrations

None. Existing Prisma schema and moderation/favorite tables were sufficient.

## Validation

- `cd apps/api && npm run build` — passed.
- `cd apps/api && npm run test:db` — passed against isolated Docker PostgreSQL; 8 suites / 85 tests.
- `cd apps/mobile && flutter analyze --no-fatal-infos --no-fatal-warnings` — passed with the repository's existing 45 informational/warning diagnostics; no errors.
- `cd apps/mobile && flutter test` — passed; 10 tests.
- Web/admin lint/build — not rerun in this stage because no web/admin source changed; the last Sprint 2C baseline gates remain applicable.
- `git diff --check` — pending final documentation commit and will be run before closing.

## Tests added or extended

The API integration suite verifies safe public projection, owner self-review rejection, owner-only replies, paginated review visibility, helpful access, and author deletion. Existing Sprint 1/1.1 authorization, upload and taxonomy tests continue to pass.

## Deferred / not implemented

- Full review pagination UI (the API/client contract is ready; the current screen remains bounded to the detail payload).
- Inline optimistic helpful-count update (current behavior refreshes the detail snapshot).
- Physical-device verification of gallery/contact/favorite behavior.
- Push delivery, access/refresh rotation, map SDK and object storage remain outside Sprint 2D.

## Recommendation

**GO for Sprint 2E planning** after the final repository-wide web gates and `git diff --check` pass. Production deployment still requires physical-device verification and external integration credentials.

## Final Release Gate

| Check | Result |
|---|---|
| `cd apps/api && npm run prisma:generate` | Pass |
| `cd apps/api && npm run test:db` | Pass — isolated Docker PostgreSQL, 8 suites / 86 tests |
| `cd apps/api && npm run build` | Pass |
| `cd apps/web && npm run lint` | Pass |
| `cd apps/web && npm run build` | Pass |
| `cd apps/mobile && flutter analyze --no-fatal-infos --no-fatal-warnings` | Pass — 0 errors; 45 existing non-fatal diagnostics |
| `cd apps/mobile && flutter test` | Pass — 10/10 |
| `git diff --check` | Pass |
| Documentation links | Pass; no broken internal links |
| Secrets scan | No real credentials found in docs/README |
| API route inventory | 142 server routes accounted for in API reference |
| Public provider/review visibility | Pass; approved/active filters and safe projection verified |
| Pagination/favorite/ownership regression checks | Pass; no duplicate page result, IDOR rejected, blocked actions rejected |

**Commit:** `34753b4` is the existing Sprint 2D documentation commit; the final verification tests are recorded in the follow-up freeze commit.
**Tag status:** `v0.5-provider` already existed and was preserved unchanged; no existing tag was rewritten.
**Deferred:** physical device journeys, full review pagination UI, optimistic Helpful update, push delivery, token rotation and object storage.
**Final decision:** **GO** for the post-Sprint-2 stabilization freeze. Production release remains gated on device/staging verification.
