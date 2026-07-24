# Environment Variables

**Last verified:** 2026-07-24
**Source of truth:** `apps/api/.env.example`, `apps/web/.env.example`, `apps/mobile/.env.example`, `infra/.env.example`, and runtime reads
**Status:** Partially Verified (names are verified; production values and external credentials are not)
**Owner:** Deployment/Engineering.

No values below are production secrets. Use local `.env` files or the deployment secret store; never commit them.

## API

| Variable | Required | Sensitive | Purpose | Example format |
|---|---:|---:|---|---|
| `DATABASE_URL` | Yes | Yes | Prisma PostgreSQL connection | `postgresql://<USER>:<PASSWORD>@<HOST>:<PORT>/<DB>?schema=public` |
| `PORT` | No | No | API listen port | `4000` |
| `API_HOST` | No | No | API bind host | `127.0.0.1` |
| `ADMIN_API_KEY` | Production | Yes | API-key admin mode | long random string |
| `UPLOADS_DIR` | No | No | Local media root | `/srv/henaqena/uploads` |
| `PUBLIC_API_BASE_URL` | Yes for public uploads | No | URL prefix for generated media | `https://example.com` |
| `CORS_ORIGINS` | Production | No | Allowed browser origins | comma-separated URLs |
| `STORAGE_DRIVER` | No | No | Current storage selector | `local` |
| `ENABLE_BACKGROUND_JOBS` | No | No | Lifecycle/backup scheduler | `true`/`false` |

## Auth and notifications

| Variable | Component | Required | Sensitive | Purpose |
|---|---|---:|---:|---|
| `WHATSAPP_OTP_WEBHOOK_URL` | API | Optional | Yes | OTP delivery webhook |
| `SMS_OTP_WEBHOOK_URL` | API | Optional | Yes | SMS delivery webhook |
| `EMAIL_OTP_WEBHOOK_URL` | API | Optional | Yes | Email delivery webhook |
| `OTP_WEBHOOK_TOKEN` | API | Optional | Yes | Webhook bearer token |
| `GOOGLE_CLIENT_IDS` | API | Production social login | No | Comma-separated trusted Google audiences |
| `APPLE_CLIENT_IDS` | API | Production social login | No | Trusted Apple App/Service IDs |
| `PRIMARY_OWNER_EMAIL` | API | No | No | Protected reset owner identity |
| `PRIMARY_OWNER_PHONE` | API | No | No | Protected reset owner identity |
| `PRIMARY_OWNER_NAME` | API | No | No | Protected reset owner display name |

## Google/maps/search

| Variable | Required | Sensitive | Purpose |
|---|---:|---:|---|
| `GOOGLE_MAPS_API_KEY` | Optional | Yes | Optional external Google Places/maps collection |
| `GOOGLE_MAPS_PROVIDER_ENABLED` | No | No | Explicitly enable Google provider |
| `SEARCH_PROVIDER` | No | No | External enrichment selector |
| `SEARCH_API_KEY` | Optional | Yes | External search credential |
| `SEARCH_ENGINE_ID` | Optional | No | Search engine identifier |
| `SOCIAL_ENRICHMENT_ENABLED` | No | No | Enable enrichment jobs |

## Web/admin

| Variable | Required | Sensitive | Purpose |
|---|---:|---:|---|
| `NEXT_PUBLIC_API_BASE_URL` | Yes | No | Browser API base URL |
| `API_INTERNAL_BASE_URL` | Yes on server | No | Server-side API URL |
| `PORT` | Yes | No | Next.js port; production 3100 |
| `HOSTNAME` | No | No | Next.js bind host |
| `ADMIN_API_KEY` | Yes | Yes | Server action API authentication |
| `ADMIN_DASHBOARD_PASSWORD` | Yes in current deployment config | Yes | Dashboard gate/configuration |
| `ADMIN_SESSION_SECRET` | Yes in production | Yes | Admin session signing/secret |

## Flutter compile-time values

These are passed as `--dart-define`, not read from the API `.env`:

| Variable | Purpose | Example format |
|---|---|---|
| `API_BASE_URL` | API base URL | `https://api.example.com` |
| `GOOGLE_CLIENT_ID` | Platform-specific Google client | OAuth client ID |
| `GOOGLE_SERVER_CLIENT_ID` | Web/server audience | OAuth client ID |
| `APPLE_SERVICE_ID` | Apple web service ID | reverse-domain ID |
| `APPLE_REDIRECT_URI` | Apple callback | HTTPS URL |
| `GOOGLE_MAPS_API_KEY` | Optional native map key | provider key |
| `GOOGLE_MAPS_ENABLED` | Optional feature flag | `true`/`false` |
| `ENVIRONMENT` | Build environment label | `development` |

## CI/testing/deployment

CI sets `NODE_ENV=test`, `DATABASE_URL`, `ENABLE_BACKGROUND_JOBS=false`, `ADMIN_API_KEY`, and a temporary `UPLOADS_DIR`. The Docker test workflow defaults to a PostgreSQL container on host port 5434. Deployment additionally requires PM2/CloudPanel secrets and a persistent uploads/backup directory.

## Secret rules

- Do not put actual passwords, API keys, OAuth client secrets, webhook tokens, or database URLs in Git.
- Public OAuth client IDs are configuration, but keep environment-specific values outside documentation examples.
- Rotate `ADMIN_API_KEY`, `ADMIN_SESSION_SECRET`, database credentials, and webhook tokens after exposure.
