# Documentation Gaps

**Last verified:** 2026-07-24
**Source of truth:** code review, Sprint 1/1.1 reports, and available local runtime evidence
**Status:** Partially Verified
**Owner:** Engineering; resolve each item with evidence rather than assumption.

## Documentation Discrepancies

- README lists API port 4000 and web port 3100, while the VPS deployment uses PM2 and a reverse proxy; the exact CloudPanel route is deployment-specific.
- README describes a few “main endpoints” but is not a complete API catalog; [API_REFERENCE](./API_REFERENCE.md) is the authoritative route inventory.
- The repository contains both production `src/server.ts` and legacy `src/app.ts`; only `server.ts` is production, but some legacy tests target `app.ts`.
- Sprint 1.1 found schema fields that had been added before a migration was recorded; the alignment migration now documents and closes that gap.

## Missing runtime evidence

- GitHub Actions has been configured but its remote run was not observed in this session.
- Google Sign-In has configured client IDs in project history, but physical iOS/Android sign-in with live tokens is unverified.
- Apple Sign-In callback, service ID and device flow are unverified.
- Browser-driven admin import/archive/moderation against the VPS is unverified; API integration coverage is available.
- Push notification delivery provider is not configured in the repository.

## Ambiguous or partial paths

- `ADMIN_DASHBOARD_PASSWORD` and `ADMIN_SESSION_SECRET` are configured by the web deployment, while API admin authorization uses API key/admin sessions; exact CloudPanel secret wiring should be confirmed manually.
- External Google Maps and social enrichment are feature-flagged and may be disabled; their production quotas and billing are external decisions.
- `apps/api/src/data-collection` uses raw SQL for collection tables that Prisma declares for schema awareness; changes require reviewing both SQL and schema.

## Stale/dead-code candidates

- `apps/api/src/app.ts` is a legacy reduced application used by existing tests and should not be treated as the production route surface.
- `apps/admin` is described in README as an old temporary model; the active admin UI is `apps/web/app/admin`.
- Historical backup bundles and “while closing eyes” artifacts exist untracked in the workspace; they were not inspected, deleted, or added.

## Product-owner decisions still needed

- Access/refresh-token migration and session revocation design.
- Parent/child category mapping and duplicate merge policy.
- Object-storage provider and retention policy for media.
- Final OTP, Google, Apple, maps and push-notification providers.
- Whether API-key admin mode remains enabled after all web clients use admin sessions.
