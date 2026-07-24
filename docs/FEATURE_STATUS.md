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

These statuses describe completed engineering sprints, not new product features.

Legend: **Implemented** = present in current code; **Partial** = some paths/UI or external setup missing; **Planned** = not implemented; **Unverified** = code exists but runtime evidence is missing.

| Module | Status | Evidence / notes |
|---|---|---|
| Email/password auth and sessions | Implemented | API register/login/session/logout; 30-day bearer sessions |
| Guest navigation | Partial | Client navigation exists; guest restrictions vary by action |
| OTP verification/reset | Partial | API/webhook hooks exist; provider delivery is external/unverified |
| Google login | Partial/Unverified | Flutter/API verification paths exist; physical devices and production config pending |
| Apple login | Partial/Unverified | Flutter/API hooks exist; callback/device verification pending |
| Profiles/preferences/avatar | Implemented | API and mobile/web paths present; upload rules enforced |
| Block/unblock and admin roles | Implemented | Admin endpoint/UI and audit metadata covered by Sprint 1.1 |
| Provider directory | Implemented/Partial | CRUD, moderation, media and owner paths; broad catalog population is data-dependent |
| Categories/areas | Implemented | Reads, duplicate checks and safe deactivation; parent/child taxonomy planned |
| Listings/classifieds | Implemented/Partial | Lifecycle, media, favorites, reports; advanced marketplace flows are not present |
| Reviews/replies/helpful | Implemented/Partial | API moderation and reactions exist; full social UX varies by screen |
| Favorites/lists/saved searches | Implemented | Ownership checks and refresh paths present |
| Ads/home campaigns | Implemented/Partial | API/admin controls and reactions; external ad billing is not present |
| Prices | Implemented/Partial | API/admin CRUD; authoritative live feeds and history depth depend on data |
| Qena Now | Implemented/Partial | API/admin content and helpful votes; push delivery not implemented |
| Notifications | Implemented/Partial | Persisted/read/unread/deep-link target; push provider not implemented |
| Internal map | Implemented/Partial | Flutter map with provider pins; navigation uses optional external directions |
| Google Maps/Places | Partial/Unverified | Feature-flagged and credential-dependent |
| Data import/collection | Implemented/Partial | Admin import and OSM/Google paths; source quotas and browser E2E pending |
| Admin dashboard | Implemented/Partial | Next.js CRUD/moderation/settings/import screens; full browser audit pending |
| Owner business portal | Planned | Owner API checks exist; dedicated self-service portal is not complete |
| Analytics/reporting | Partial | Admin summaries/audit endpoints; full product analytics dashboards are limited |
| Backups/restore/reset | Implemented/Partial | API and scripts exist; destructive operations require operational approval |
| Push notifications | Planned | DB notifications only |
| Access/refresh rotation | Planned | Deferred security sprint |
| Category hierarchy | Planned | Deferred data migration |
| Object storage/thumbnail pipeline | Planned | Current storage is local filesystem |
| Jobs, rentals, cars, emergencies, tourism, education expansions | Planned/Partial | Some directory data can represent them; dedicated modules are not all present |

## Audit rule

When a feature changes, update this table and the [Documentation Gaps](./DOCUMENTATION_GAPS.md) entry if runtime evidence is still missing. Do not mark an external integration Implemented solely because a client package is installed.
