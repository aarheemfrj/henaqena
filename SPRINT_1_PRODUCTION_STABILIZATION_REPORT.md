# Sprint 1 — Production Stabilization Report

**Project:** Hena Qena  
**Scope:** Production stabilization only  
**Date:** 2026-07-24  
**Owner:** Codex

## Executive summary

Sprint 1 focused on making the existing authentication, upload, authorization, data integrity, and operational paths safer without introducing new product modules or changing the application architecture. Backend and admin builds pass, and Flutter analysis/tests complete without errors. Full API integration tests could not run because the local PostgreSQL/Docker service was unavailable during the audit.

## What was already present

- Email/password registration and login, guest navigation, logout and logout-all flows.
- Federated authentication endpoints and Flutter Google/Apple integration hooks.
- Session persistence in PostgreSQL with hashed bearer sessions and expiry.
- Provider, listing, avatar and advertisement image upload paths.
- Admin and owner route guards, ownership checks, and an existing audit-log table.
- Prisma models for categories, areas, providers, listings, ads, prices, and moderation states.
- Next.js administration screens and Flutter client screens connected to the same API.

## Problems discovered

1. Blocked users were not consistently rejected by every authenticated session path.
2. Federated accounts could collide by email; the behavior was not documented as an intentional safe rejection.
3. Sessions are a single expiring bearer token; there is no separate rotating access/refresh-token pair.
4. Uploaded images trusted the declared MIME type and had incomplete cleanup on replacement/deletion.
5. Large multi-image JSON requests could exceed the body limit.
6. Public provider lookup could expose non-approved records when an ID was known directly.
7. A favorite list ID was not verified as belonging to the current user (IDOR risk).
8. Sensitive admin actions did not consistently carry the acting admin identity in audit metadata.
9. Category/area name matching was case-sensitive and deletion could break references.
10. Parent/child category hierarchy is not represented in the current schema.

## Files modified

- `apps/api/prisma/schema.prisma`
- `apps/api/prisma/migrations/20260724060000_production_stabilization/migration.sql`
- `apps/api/src/server.ts`
- `apps/web/app/admin/actions.ts`
- `apps/web/app/admin/users/page.tsx`
- `PROJECT_ACTIVITY_LOG.md`

## Database migrations

Migration `20260724060000_production_stabilization` adds `User.isBlocked`, `User.blockedAt`, and `User.blockedReason`. Existing users remain active (`isBlocked = false`). The migration is additive and does not delete or rewrite application data.

## What was fixed

### Authentication and sessions

- Every session lookup now rejects expired sessions and blocked users.
- Email/password and federated login explicitly reject blocked accounts with a clear 403 response.
- Federated email collisions remain a safe 409 rejection rather than silently merging two accounts.
- Logout behavior remains unchanged and existing session deletion is preserved.

### Uploads and files

- Server-side image validation now checks JPEG/PNG/WebP magic bytes, not only the client MIME declaration.
- Per-image limit remains 2 MB; the JSON body limit is 24 MB to safely support up to ten images with encoding overhead.
- Upload names remain server-generated and path traversal is rejected.
- Local upload deletion is restricted to the configured public API origin and approved upload directories.
- Old local images are removed after provider/listing/avatar replacement and after provider/listing deletion.
- A lifecycle cleanup pass removes unreferenced local files older than 24 hours; remote URLs are never deleted by this cleanup.
- Added authenticated deletion endpoint for provider images.

### Roles, permissions, and IDOR protection

- Admin audit metadata now records the acting admin ID and role through request context.
- Provider detail lookup only exposes approved records publicly; an owner can still view their own pending record.
- Favorite list ownership is checked before adding/removing a favorite.
- Added admin user block/unblock endpoint and admin UI action. System/admin accounts cannot be blocked through this action.
- Existing owner ownership checks remain in place for provider updates, services, offers, and listings.

### Categories and data integrity

- Area/category resolution and admin create/update duplicate checks are now case-insensitive.
- Deleting a category or area that is referenced by content now deactivates it instead of breaking relationships; unused records can still be deleted.
- Existing duplicate rows were not auto-merged because that requires a data-owner decision and a live database review.

## Validation performed

| Area | Command/check | Result |
|---|---|---|
| API | `npm run prisma:generate` | Passed |
| API | `npm run build` | Passed |
| Web | `npm run lint` | Passed |
| Web | `npm run build` | Passed; all routes generated |
| Flutter | `flutter analyze --no-fatal-infos --no-fatal-warnings` | Passed with existing non-fatal infos/warnings; no errors |
| Flutter | `flutter test` | Passed: 8/8 |
| Formatting | `git diff --check` | Passed |

## What could not be tested

- API Jest integration suite: local PostgreSQL was not reachable on `127.0.0.1:5432`.
- Database test bootstrap: Docker/Colima daemon was unavailable, so the test database could not be created.
- Real Google/Apple sign-in on physical production builds: requires device credentials, production redirect configuration, and live provider secrets.
- Orphan cleanup against production storage: requires a live production filesystem and database snapshot.

## Manual test checklist

1. Apply the migration with the production-safe Prisma deploy command.
2. Register, log in, refresh the app, log out, and verify guest navigation.
3. Block a test user in the admin panel; verify API access, app access, and existing contribution history behavior. Unblock and verify recovery.
4. Try Google login with a configured iOS/Android client; verify duplicate email returns the documented conflict instead of creating a second account.
5. Upload valid JPEG, PNG, and WebP images; verify oversized files, renamed extensions, invalid bytes, and empty files are rejected.
6. Replace provider/listing/avatar images and confirm old local files are removed; delete the record and confirm its local files are removed.
7. Attempt to use another user's favorite list ID and another provider/listing ID; verify 403/404 behavior.
8. Create category/area names differing only by case; verify duplicate rejection. Delete a referenced category/area and verify it becomes inactive.
9. Review Audit Logs for admin ID/role metadata after block, content update, deletion, and moderation actions.
10. Run the web admin flows for user blocking, provider editing, import, approval, and archive on the staging database.

## Remaining risks

- Access/refresh token separation and rotation are not implemented; the current 30-day hashed bearer session remains an architectural follow-up.
- OTP delivery and Google/Apple production credentials still require live provider configuration and device testing.
- Existing Flutter analyzer infos/warnings remain and should be reduced before store release.
- Parent/child category relations are not modeled yet; Sprint 1 only prevents destructive category/area changes.
- Full integration coverage requires a reachable PostgreSQL test database.
- The API-key admin mode is intentionally powerful; keep the key outside Git and rotate it operationally.

## Sprint 2 proposal

1. Add database-backed integration/contract tests with an isolated PostgreSQL service in CI.
2. Design and migrate to short-lived access tokens plus rotating refresh tokens, with client logout/revocation semantics.
3. Complete Google/Apple production credential validation on physical iOS and Android devices.
4. Add a safe media job queue for thumbnails, virus/content checks, and scheduled orphan cleanup.
5. Add explicit category parent/child modeling and a reviewed duplicate-merge workflow.
6. Expand admin audit-log browsing, export, retention, and alerting.
7. Reduce remaining Flutter analyzer warnings and add end-to-end smoke tests for critical user journeys.

