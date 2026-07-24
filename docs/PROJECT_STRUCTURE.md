# Project Structure

**Last verified:** 2026-07-24
**Source of truth:** repository tree and package entry points
**Status:** Verified
**Owner:** Engineering.

## Root

| Path | Purpose | Keep out |
|---|---|---|
| `apps/` | Product applications | Generated build output and secrets |
| `docs/` | Engineering/product documentation | Passwords, tokens and one-off scratch notes |
| `infra/` | Docker, proxy, PM2 and backup deployment assets | Production secrets |
| `.github/workflows/` | CI definitions | Credentials |
| `deploy.sh` | VPS deployment orchestration | Embedded passwords |
| `PROJECT_ACTIVITY_LOG.md` | Chronological project log | Secrets |

## API (`apps/api`)

- `src/server.ts`: production Express entry point and all current route handlers.
- `src/app.ts`: smaller legacy/test app; do not add production routes here.
- `src/bootstrap-owner.ts`, `src/seed.ts`: administrative bootstrap and seed utilities.
- `src/data-collection/`: OSM/Google/social collection jobs and supporting routes.
- `src/__tests__/`: Jest unit/integration tests.
- `prisma/schema.prisma`: database model source.
- `prisma/migrations/`: append-only migration history.
- `scripts/test-db.sh`: disposable Docker test workflow.
- `docker-compose.test.yml`: isolated PostgreSQL test service.
- `uploads/`, `backups/`: runtime directories; never commit generated files.

Add a new API module by adding a focused route/helper under `src/` and registering it from `server.ts`; keep validation and authorization beside the route. Add integration tests under `src/__tests__/`.

## Web/admin (`apps/web`)

- `app/page.tsx`: public home.
- `app/providers`, `app/listings`, `app/now`, `app/prices`: public content screens.
- `app/admin/`: admin layout, navigation, pages and server actions.
- `app/admin/actions.ts`: shared admin server actions.
- `app/*/actions.ts`: route-specific server actions.
- `app/globals.css`: shared styling.

Add an admin screen under `apps/web/app/admin/<route>/`, update `admin-nav.tsx` if navigation is required, and reuse the existing API/session helpers.

## Flutter (`apps/mobile`)

- `lib/main.dart`: current application shell and many screens.
- `lib/core/network/api_client.dart`: API client and response mapping.
- `lib/core/auth/`: persisted session and social authentication services.
- `lib/core/theme/`: palette/theme definitions.
- `test/widget_test.dart`: widget smoke tests.

Add a new Flutter feature in a dedicated core/service or screen section where possible, keep network calls in `api_client.dart`, and add a widget/integration test.

## Database, tests and docs

- Add migrations only under `apps/api/prisma/migrations/<timestamp>_<name>/`.
- Never edit an applied migration; create a new one.
- Put test-only fixtures in test setup, not seed data.
- Update `DOCUMENTATION_INDEX.md` and the relevant guide when behavior changes.

## Generated/runtime content

Do not commit `.next`, `dist`, `coverage`, local `.env` files, uploads, backups, simulator artifacts, or database dumps. Existing untracked backup artifacts in the workspace are intentionally outside this sprint.
