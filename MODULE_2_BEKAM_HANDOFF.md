# Hena Qena — Module 2 «بكام؟» Handoff

## Current baseline

The project is on `main`. Module 1 («مين شاطر») is implemented partially and remains without a release tag because device, staging and notification deep-link verification were not complete.

Module 2 («بكام؟») is implemented as an incremental stabilization slice. It is **not release-ready** and must not receive a release tag yet.

Latest Module 2 commits:

- `59c4e10` — pre-implementation audit
- `00e4277` — submission validation and public freshness hardening
- `7321b84` — price confirmations API and additive model
- `90ca7f5` — mobile confirmation interaction
- `f3e27e5` — freshness, confidence and archive lifecycle
- `8a21873` — mobile freshness/confidence display
- `3f1762c` — advisory outlier review API
- `ecd6d92` — admin outlier filter and documentation
- `4b4ba3b` — complete admin price editing and archive controls
- `3ef5f88` — admin price editing regression coverage

## Implemented

### API/backend

- Public `GET /api/prices` returns approved, active, non-expired prices only.
- Inactive areas, archived rows and deleted rows are excluded publicly.
- Deterministic ordering is used.
- User price submissions require positive values, active areas and reject duplicate pending/approved rows.
- `POST /api/prices/:id/confirm` supports one upsertable confirmation per user and price.
- Public response includes confirmation count, latest confirmation, viewer confirmation state and freshness.
- `PriceGuide` now has additive fields:
  - `validUntil`
  - `confidenceScore`
  - `sourceType`
  - `lastReviewedAt`
- Admin-created prices default to administrative source and confidence 80.
- Admin can edit price metadata and range through `PATCH /api/admin/prices/:id`.
- Admin can archive/restore through `PATCH /api/admin/prices/:id/archive`.
- All sensitive admin changes are audited.
- Admin-only advisory outlier signal is available through:
  - `GET /api/admin/prices`
  - `GET /api/admin/prices?outliersOnly=true`
- Outlier detection is advisory only; it never auto-rejects or changes a price.
- Public users never receive the outlier signal.

### Database

Applied additive migrations:

- `20260724220619_price_confirmations`
- `20260724224317_price_freshness_confidence`

No destructive migration was added in the current slice.

### Flutter

- Price cards support authenticated confirmation actions.
- Confirmation count and freshness/confidence wording are displayed.
- Guest users receive a login CTA for protected confirmation actions.

### Web/admin

- `/admin/prices` supports:
  - Create price.
  - Edit name, category, range, unit, source, validity and confidence.
  - Approve/reject pending prices.
  - Archive/restore prices.
  - Filter advisory outliers.

## Verification already completed

- API TypeScript build: passed.
- Isolated Docker PostgreSQL migration run: passed.
- API integration suite: **90/90 passed**.
- Web/Admin lint: passed.
- Web/Admin production build: passed.
- Flutter tests previously passed: 9/9.
- `git diff --check`: passed.

## What remains

### Required before Module 2 release

1. Staging verification against a non-production staging database:
   - Apply migrations safely.
   - Verify existing data preservation.
   - Test price confirmation.
   - Test admin edit/archive/restore.
   - Verify public expiry filtering.
   - Verify audit records.
2. Device verification on iOS and Android.
3. Manual browser verification of the complete admin price workflow.
4. Decide whether price history/observations are needed; do not add them without a separate migration review.
5. Improve outlier logic only if real data proves the current median/2.5x heuristic insufficient.
6. Update final Module 2 release report after staging verification.
7. Do not create a Module 2 release tag until all release gates pass.

## Important constraints

- Do not use production database for tests.
- Do not commit secrets or environment values.
- Do not auto-reject prices based on outlier detection.
- Do not expose moderation fields or outlier signals in public API responses.
- Do not add a new product module while finishing Module 2.
- Keep migrations additive and test them on isolated PostgreSQL.
- Preserve these local untracked artifacts; do not add or delete them:
  - `docs/DEPLOYMENT_NOTES.md`
  - `while closing eyes-henaqena.sql.gz`
  - `while closing eyes-uploads.tar.gz`
  - `while closing eyes.bundle`

## Recommended next implementation slice

Start with staging verification and a focused runtime test report. If code changes are required, keep them limited to real defects discovered during staging. After that, decide on a separate price-history design before adding any new database model.

## Files to provide to ChatGPT/Claude

Attach these files first:

1. `MODULE_2_BEKAM_HANDOFF.md` (this file)
2. `MODULE_2_BEKAM_AUDIT.md`
3. `MODULE_2_BEKAM_REPORT.md`
4. `apps/api/src/server.ts`
5. `apps/api/prisma/schema.prisma`
6. `apps/api/prisma/migrations/20260724220619_price_confirmations/migration.sql`
7. `apps/api/prisma/migrations/20260724224317_price_freshness_confidence/migration.sql`
8. `apps/api/src/__tests__/production-stabilization.integration.test.ts`
9. `apps/web/app/admin/prices/page.tsx`
10. `apps/web/app/admin/actions.ts`
11. `apps/mobile/lib` price-related files, especially the price card and API client files
12. `docs/API_REFERENCE.md`
13. `docs/DATABASE_GUIDE.md`
14. `docs/FEATURE_STATUS.md`
15. `docs/ROADMAP.md`
16. `PROJECT_ACTIVITY_LOG.md`

When asking Claude for code, explicitly say: “Continue from this handoff. Do not redesign architecture, do not add a new module, and do not create a release tag until staging verification passes.”
