# Engineering Roadmap

**Last verified:** 2026-07-24
**Source of truth:** Feature Status, Sprint reports, current code and product decisions
**Status:** Planning document; does not authorize implementation
**Owner:** Product + Engineering

## Completed baseline

The following baseline sprints are **closed بالكامل** and included in tag `v0.1-baseline`:

- **Sprint 1 — Production Stabilization — Closed:** auth blocking, upload validation/cleanup, IDOR protections, taxonomy safety and audit metadata.
- **Sprint 1.1 — Production Verification & Integration Testing — Closed:** isolated PostgreSQL integration tests, staging migration, backup/restore and CI coverage.
- **Sprint 1.5 — Engineering Documentation — Closed:** source-backed architecture, database, API, security, deployment, testing and feature-status documentation.

## Sprint 2 — Directory and trust depth

Sprint 2 is split into focused delivery gates:

### Sprint 2A — Directory Experience — Closed

Active taxonomy filtering, stable paginated provider listing, open-now calculation, nearby handling, safe empty/error states and admin data-quality indicators are implemented and verified in `SPRINT_2A_DIRECTORY_EXPERIENCE_REPORT.md`.

### Sprint 2B — Search — Closed

Provider directory search now has bounded query validation, Arabic/English normalization, relevance-ranked matching across provider names/services/categories/areas, deterministic pagination, suggestions and local recent-search UX. Search analytics and cross-module search remain out of scope.

### Sprint 2C — Maps — Implemented (local verification)

Internal Qena map markers now use a bounded API contract, approved-only visibility, valid-coordinate filtering, category coloring, actionable location permissions, recenter/follow behavior, route fitting and shared Haversine distance ordering. Clustering, offline tiles and production device verification remain deferred; see `SPRINT_2C_LOCATION_INTELLIGENCE_REPORT.md`.

### Sprint 2D — Provider Page / Reviews / Favorites — Planned

Provider-page depth, review/favorite UX improvements and related contract work. Not implemented in Sprint 2A.

## Sprint 3 — Security and media operations

1. Design access/refresh-token rotation with revocation and replay detection.
2. Introduce media scanning/thumbnails and a durable object-storage plan.
3. Define backup encryption, retention, restore drills and alerting.

## Sprint 4 — Product expansion

Only after the foundation is stable: richer prices/history, Qena Now source workflows, events, transport, jobs and other community modules. Each module requires API, admin, mobile UX, moderation rules and tests.

## Dependencies and gates

- No new module should bypass ownership/moderation rules.
- No schema migration without duplicate/reference audit and separate restore test.
- External integrations require credentials, quotas, privacy review and physical-device verification.
- Keep the [Feature Status](./FEATURE_STATUS.md) matrix honest; planned work is not shipped work.
