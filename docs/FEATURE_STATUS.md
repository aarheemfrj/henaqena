# Feature Status

**Last verified:** 2026-07-24
**Source of truth:** current API routes, Flutter screens, Next.js pages, Sprint 1/1.1 reports
**Status:** Audit snapshot; not a product promise
**Owner:** Product/Engineering

## Baseline sprint status

| Sprint | Status | Baseline evidence |
|---|---|---|
| Sprint 1 — Production Stabilization | Implemented | Commit `4cb2c4b`; stabilization report and regression fixes |
| Sprint 1.1 — Production Verification & Integration Testing | Implemented | Commit `56f8803`; 75/75 isolated PostgreSQL integration tests, staging migration and restore verification |
| Sprint 1.5 — Engineering Documentation | Implemented | Commits `c7e1d5c` and `47dc98e`; documentation set, route audit and final validation |
| Sprint 2A — Directory Experience | Implemented | Sprint 2A report; isolated PostgreSQL tests, API build, web checks and Flutter analysis |
| Sprint 2B — Search Experience | Implemented | Search API integration tests, Flutter search widget test, API/web/mobile validation |

These statuses describe completed engineering sprints, not new product features.

Legend: **Implemented** = present in current code; **Partial** = some paths/UI or external setup missing; **Planned** = not implemented; **Unverified** = code exists but runtime evidence is missing.

| Module | Status | Evidence / notes |
|---|---|---|
| Email/password auth and sessions | Implemented | API register/login/session/logout; 30-day bearer sessions |
| Guest navigation | Partial | Client navigation exists; guest restrictions vary by action |
| OTP verification/reset | Partial | API/webhook hooks exist; provider delivery is external/unverified |
| Google login | Unverified | Flutter/API verification paths exist; physical devices and production config pending |
| Apple login | Unverified | Flutter/API hooks exist; callback/device verification pending |
| Profiles/preferences/avatar | Implemented | API and mobile/web paths present; upload rules enforced |
| Block/unblock and admin roles | Implemented | Admin endpoint/UI and audit metadata covered by Sprint 1.1 |
| Provider directory and search | Implemented | CRUD, moderation, media and owner paths; active filters, stable pagination, sorting, open-now handling, normalized relevance search and suggestions verified |
| Categories/areas | Implemented | Reads, duplicate checks and safe deactivation; parent/child taxonomy planned |
| Listings/classifieds | Partial | Lifecycle, media, favorites, reports; advanced marketplace flows are not present |
| Reviews/replies/helpful | Implemented | Provider detail, bounded reviews route, owner-only replies, helpful state and author deletion are covered by Sprint 2D API/mobile contracts |
| Favorites/lists/saved searches | Implemented | Ownership checks, named lists, optimistic detail state and refresh paths present |
| Ads/home campaigns | Partial | API/admin controls and reactions; external ad billing is not present |
| Prices | Partial | API/admin CRUD; authoritative live feeds and history depth depend on data |
| Qena Now | Partial | API/admin content and helpful votes; push delivery not implemented |
| Notifications | Partial | Persisted/read/unread/deep-link target; push provider not implemented |
| Internal map | Implemented | Bounded approved-only marker API, valid coordinates, category-colored pins, location/recenter states, route fitting and external directions fallback; clustering/offline tiles remain deferred |
| Google Maps/Places | Unverified | Feature-flagged and credential-dependent |
| Data import/collection | Partial | Admin import and OSM/Google paths; source quotas and browser E2E pending |
| Admin dashboard | Partial | Next.js CRUD/moderation/settings/import screens; full browser audit pending |
| Owner business portal | Planned | Owner API checks exist; dedicated self-service portal is not complete |
| Analytics/reporting | Partial | Admin summaries/audit endpoints; full product analytics dashboards are limited |
| Backups/restore/reset | Partial | API and scripts exist; destructive operations require operational approval |
| Push notifications | Planned | DB notifications only |
| Access/refresh rotation | Planned | Deferred security sprint |
| Category hierarchy | Planned | Deferred data migration |
| Object storage/thumbnail pipeline | Planned | Current storage is local filesystem |
| Jobs, rentals, cars, emergencies, tourism, education expansions | Planned | Some directory data can represent them; dedicated modules are not all present |

## Audit rule

When a feature changes, update this table and the [Documentation Gaps](./DOCUMENTATION_GAPS.md) entry if runtime evidence is still missing. Do not mark an external integration Implemented solely because a client package is installed.
