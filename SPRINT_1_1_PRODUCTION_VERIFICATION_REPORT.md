# Sprint 1.1 — Production Verification & Integration Testing

**Project:** Hena Qena  
**Date:** 2026-07-24  
**Scope:** Runtime verification of Sprint 1 only; no product modules were added.

## Recommendation

**GO to start Sprint 2 development.** The isolated PostgreSQL integration suite, staging migration, staging runtime checks, and backup/restore verification all passed.  
**NO-GO for public production release until** CI has run successfully in GitHub and Google/Apple sign-in has been verified on physical iOS and Android devices with production credentials.

## Environment used

- macOS Apple Silicon development machine.
- PostgreSQL 18.4 from Postgres.app on `127.0.0.1:5432`.
- Three isolated databases were used: `henaqena_sprint11_test`, `henaqena_sprint11_staging`, and `henaqena_sprint11_restore`.
- API: Node.js/npm with Prisma 6.19.3 generated client.
- Admin: Next.js 16.2.10.
- Mobile: Flutter stable toolchain already pinned by the project.
- Docker/Colima was not running locally, so the local Docker script was prepared and the live test run used a dedicated local PostgreSQL database instead. CI uses a PostgreSQL service container.
- No production `DATABASE_URL`, uploads directory, or secrets were used.

## Database test setup

The test database was created separately from every existing database, then all committed Prisma migrations were applied with `npx prisma migrate deploy`. The database URL used for tests was:

`postgresql://aarheemfrj@127.0.0.1:5432/henaqena_sprint11_test?schema=public`

The reusable local Docker path is now `apps/api/scripts/test-db.sh`. It starts `apps/api/docker-compose.test.yml`, waits for PostgreSQL health, runs Prisma generate/migrations, executes the integration suite, and removes the named test volume on exit. It never references production configuration.

## Important migration issue found and fixed

The audit revealed that several fields already used by the running API were present in `schema.prisma` but absent from the migration history. This caused runtime errors such as missing `Provider.externalId` and `Listing.archivedAt` after a clean migration.

Added migration:

`apps/api/prisma/migrations/20260724063000_schema_alignment/migration.sql`

It safely adds archive fields, provider contact/social fields, `openingHours`, `externalId`, and the required indexes. It preserves existing rows and intentionally stops with a clear error if duplicate non-null `Provider.externalId` values exist before the unique index is created.

## Commands executed and results

| Command | Result |
|---|---|
| `npx prisma generate` | Passed |
| `npx prisma migrate deploy` on isolated test DB | Passed; 10 migrations applied |
| `npm test -- --runInBand` against isolated PostgreSQL | Passed: **75/75 tests** |
| `npm test -- --runInBand` against staging DB | Passed: **75/75 tests** |
| `npm run build` in `apps/api` | Passed |
| `npm run lint` in `apps/web` | Passed |
| `npm run build` in `apps/web` | Passed |
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | Passed with existing non-fatal infos/warnings only |
| `flutter test` | Passed: **8/8** |
| `bash -n apps/api/scripts/test-db.sh` | Passed |
| `git diff --check` | Passed |

## Tests added

`apps/api/src/__tests__/production-stabilization.integration.test.ts` adds runtime coverage for:

- Blocked user session rejection.
- Blocked password login rejection.
- Blocked federated login rejection using a mocked verified identity payload.
- Public rejection of non-approved provider IDs.
- Owner access to their own pending provider.
- Favorite-list ownership IDOR rejection.
- Provider and listing ownership violations.
- Invalid image bytes with a valid declared MIME type.
- Oversized image rejection.
- Provider image replacement cleanup.
- Avatar replacement cleanup.
- Listing image deletion cleanup.
- Remote image preservation.
- Case-insensitive category/area duplicate rejection.
- Referenced category/area deactivation instead of deletion.
- Audit metadata containing admin actor ID and role.
- Protection of ADMIN/SYSTEM users from block actions.
- Listing lifecycle cleanup with remote media.

## Bugs found

1. Clean migrated databases were missing archive/contact fields required by the current Prisma client.
2. Listing lifecycle cleanup still had a provider-only path check and could miss local listing images.
3. The existing test command did not reliably provide a disposable database when Docker was unavailable.
4. There was no production-runtime integration suite for the Sprint 1 security and upload fixes.

## Bugs fixed

- Added and verified the schema-alignment migration.
- Reused the safe local upload resolver in listing lifecycle cleanup.
- Added a real PostgreSQL integration suite and deterministic test database workflow.
- Added Docker Compose test volume cleanup and `--wait` health handling.
- Updated CI to run Prisma generate, migration deploy, integration tests, API build, admin lint/build, Flutter analyze, and Flutter tests.

## Migration result

- Applied all 10 migrations successfully to `henaqena_sprint11_test`.
- Applied all 10 migrations successfully to `henaqena_sprint11_staging`.
- Existing staging data preservation was checked by inserting a staging area, backing it up, and restoring it into a separate database; the row remained present after restore.
- No production database was touched.

## Staging verification result

The full 75-test integration suite ran against the staging database and passed. It exercised authentication blocking, public/owner visibility, ownership checks, image validation, provider/avatar/listing cleanup, category/area moderation, audit metadata, and lifecycle cleanup. The staging database was restored from its pre-test backup afterward, and the preservation row was confirmed.

Import, archive, and moderation route authorization/build paths are covered by the API build and existing route suite; the admin UI itself was not driven through a browser in this sprint.

## Google/Apple verification status

### Configured values and required variables

- API: `GOOGLE_CLIENT_IDS` must contain the iOS, Android, and Web client IDs, comma-separated.
- API: `APPLE_CLIENT_IDS` must contain the allowed Apple App ID/Service ID values.
- Flutter iOS: `GOOGLE_CLIENT_ID` = iOS client ID; `GOOGLE_SERVER_CLIENT_ID` = Web client ID.
- Flutter Android: `GOOGLE_CLIENT_ID` = Android client ID; `GOOGLE_SERVER_CLIENT_ID` = Web client ID.
- Apple web flow: `APPLE_SERVICE_ID` and `APPLE_REDIRECT_URI` are required.
- iOS bundle ID: `com.maalsoft.henaqena`.
- Android package: `com.maalsoft.henaqena`.
- Google redirect/deep-link configuration must match the generated iOS URL scheme and Android OAuth configuration.

The backend audience/issuer validation path is covered by the blocked-federated integration test with a mocked verified payload. Physical-device sign-in, real Google tokens, Apple credentials, redirect callbacks, and production console configuration remain **unverified** because they require live credentials and devices. No client IDs or secrets were committed.

## Backup and restore result

- Staging backup created with PostgreSQL custom format (`pg_dump --format=custom --no-owner`).
- Backup validity verified with `pg_restore --list`.
- Backup size: approximately 91 KB for the migration-only staging dataset.
- Restored into `henaqena_sprint11_restore`, a separate database, using `pg_restore --clean --if-exists --no-owner`.
- Restore verification returned the preserved staging row (`restore_count=1`).
- Active staging and production databases were not overwritten by the restore test.

## CI changes

- API CI now runs `npm run test:integration` after Prisma migration deployment.
- CI explicitly disables background jobs for tests and supplies isolated test environment variables.
- Admin CI now runs both `npm run lint` and `npm run build`.
- Local test workflow is available through `npm run test:db` and cleans its Docker volume automatically.

## Files modified

- `.github/workflows/ci.yml`
- `apps/api/package.json`
- `apps/api/docker-compose.test.yml`
- `apps/api/scripts/test-db.sh`
- `apps/api/src/server.ts`
- `apps/api/src/__tests__/production-stabilization.integration.test.ts`
- `apps/api/prisma/migrations/20260724063000_schema_alignment/migration.sql`
- `SPRINT_1_1_PRODUCTION_VERIFICATION_REPORT.md`
- `PROJECT_ACTIVITY_LOG.md`

## Remaining unverified items

- GitHub Actions run itself (workflow updated but not remotely executed in this session).
- Physical iOS Google Sign-In with production OAuth credentials.
- Physical Android Google Sign-In with release/debug SHA-1 configuration.
- Apple Sign-In callback and token exchange on a real device.
- Browser-driven admin import/archive/moderation flows against a live VPS deployment.
- Existing 29 non-fatal Flutter analyzer infos/warnings.

## Deferred security/data design

- Access/refresh-token rotation was not implemented. A later security sprint should add short-lived access tokens, rotating refresh tokens, token-family revocation, replay detection, and client migration with a dual-read/dual-write rollout.
- Category parent/child relations were not implemented. A safe later proposal is to add nullable `parentId`, reject cycles, backfill only after an audited mapping, and retain the current flat category behavior during rollout.

## Sprint 2 starting conditions

Sprint 2 may begin as development work. Before production release, run the GitHub CI workflow, apply the schema-alignment migration on the real staging VPS, perform the physical Google/Apple checks, and drive the admin browser flows once against the staging deployment.

