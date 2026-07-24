# API Reference

**Last verified:** 2026-07-24
**Source of truth:** `apps/api/src/server.ts` (production Express entry point)
**Status:** Route inventory verified; individual response shapes should be checked against the handler before client changes
**Owner:** Backend Engineering

## Conventions

Base URL is environment-specific. JSON errors use `{ "error": "..." }` (some validation paths include field details). User auth uses `Authorization: Bearer <session>`; admin requests may use `x-admin-key` or an admin session cookie/header. A route marked **Manual review** has dynamic response branches and should be contract-tested before external SDK generation.

## Endpoint index

The table is intentionally exhaustive for routes registered by `apps/api/src/server.ts`. Dynamic `:id` routes share the same authorization rules as their parent resource.

| Module | Methods and paths | Auth / role | Main models | Status |
|---|---|---|---|---|
| Health | `GET /health`, `GET /ready`, `GET /api/bootstrap`, `GET /api/admin/health/details` | public; admin details guarded | PlatformSettings | Implemented |
| Auth | `POST /api/auth/register`, `/login`, `/federated`, `/verification/request`, `/verification/confirm`, `/password-reset/request`, `/password-reset/confirm`, `/logout`, `/logout-all` | public for entry; session for logout | User, Session, VerificationCode | Implemented |
| Admin auth | `POST /api/admin/auth/login`, `/logout`; `GET /api/admin/auth/me` | admin | AdminAccount, AdminSession | Implemented |
| Users | `GET/PATCH /api/me`, `GET /api/users/:id`, `PATCH /api/me/preferences`, `POST /api/me/password`, `GET /api/notifications`, `PATCH /api/notifications/:id/read`, `POST /api/notifications/read-all` | session; own record | User, Notification | Implemented |
| Taxonomy | `GET /api/areas`, `GET /api/categories` | public | Area, Category | Implemented |
| Providers | `GET/POST /api/providers`, `GET/PATCH /api/providers/:id`, `POST /api/providers/:id/favorite`, `GET /api/providers/:id/services`, `/offers` | public reads; session/owner/admin writes | Provider, Area, Category, ProviderService, ProviderOffer | Implemented |
| Provider reports | `POST /api/provider-reports`; admin `GET/PATCH /api/admin/provider-reports` | session; admin moderation | ProviderReport | Implemented |
| Provider media | `POST /api/uploads/provider-images`, `DELETE /api/uploads/provider-images`, `POST /api/uploads/avatar` | session | ProviderImage, User | Implemented |
| Listings | `GET/POST /api/listings`, `GET/PATCH/DELETE /api/listings/:id`, `GET /api/listings/categories`, `POST /api/listings/:id/favorite`, `/interested`, `/reports` | public approved reads; owner/session writes | Listing, ListingImage, ListingFavorite, ListingInterest, ListingReport | Implemented |
| Favorites | `GET /api/me/favorites`, `GET/POST/PATCH/DELETE /api/me/favorite-lists`, `GET/POST/DELETE /api/me/saved-searches` | session; list owner | FavoriteList, SavedSearch, ProviderFavorite, ListingFavorite | Implemented |
| Contributions | `GET /api/me/contributions`, `PATCH/DELETE /api/me/reviews/:id`, `POST /api/me/listings/:id/renew`, `DELETE /api/me/listings/:id` | session/owner | Review, Listing | Implemented |
| Offers | `GET /api/offers`, admin `GET/PATCH /api/admin/offers`, `DELETE /api/admin/offers/:id` | public read; admin write | ProviderOffer | Implemented |
| Ads | `GET /api/ads`, `POST /api/ads`, `POST /api/ads/:id/react`, admin `GET/PATCH/DELETE /api/admin/ads/:id`, `GET /api/admin/ads` | public read; session submit; admin | Ad, AdReaction | Implemented |
| Prices | `GET/POST /api/prices`, admin `GET/POST/PATCH /api/admin/prices` | public read; session/admin write | PriceGuide | Implemented |
| Qena now | `GET/POST /api/now`, `POST /api/now/:id/helpful`, admin `GET/POST/PATCH /api/admin/now` | public read; session/admin write | NowUpdate, NowHelpful | Implemented |
| Support | `POST /api/support-tickets`, admin `GET/PATCH /api/admin/support-tickets` | session; admin | SupportTicket | Implemented |
| Reviews | `POST /api/reviews`, `POST /api/reviews/:id/replies`, `POST /api/reviews/:id/helpful` | session | Review, ReviewReply, ReviewHelpful | Implemented |
| Admin overview | `GET /api/admin/overview`, `/audit`, `/archive`, `/catalog`, `/review-queue`, `/reports/summary`, `/services`, `/offers`, `/providers`, `/listings`, `/reviews`, `/replies` | admin role varies | Multiple | Implemented |
| Admin CRUD | `POST/PATCH/DELETE /api/admin/providers`, `/listings`, `/services/:id`, `/offers/:id`, `/reviews/:id`, `/replies/:id`; provider details/content; listing content | admin role + ownership where applicable | Provider, Listing, Review, Reply | Implemented |
| Admin users/team | `GET/POST/PATCH /api/admin/team`, `GET/PATCH /api/admin/users` | OWNER/team roles | AdminAccount, User | Implemented |
| Admin constants/settings | `GET /api/settings`, `PATCH /api/admin/settings`, `GET/POST /api/admin/constants/:type`, `PUT/DELETE /api/admin/constants/:type/:id` | public settings read; admin write | PlatformSettings, Category/Area-like constants | Implemented |
| Imports | `POST /api/admin/import/providers`, `POST /api/admin/import/providers/v2` | admin | Provider, DataSource, CollectionJob | Implemented/Partial by source |
| Data collection router | `GET /api/admin/data-collection/sources`, `/overview`, `/records`, `/duplicates`; `PATCH /records/:id`, `/duplicates/:id`, `/records/:id/social-links`; `POST /jobs`, `/jobs/:id/import-csv`, `/jobs/:id/run`, `/jobs/manual` | admin | DataSource, CollectionJob, CollectedBusiness, DuplicateCandidate | Implemented/Partial by source |
| Backups/maintenance | `GET/POST /api/admin/backups`, `DELETE /api/admin/backups/:filename`, `POST /api/admin/backups/restore`, `PATCH /api/admin/backups/schedule`, `POST /api/admin/maintenance/reset`, `/reset-all` | OWNER-equivalent | PostgreSQL/filesystem, PlatformSettings | Implemented; destructive flows require staging verification |
| Jobs | `POST /api/jobs/expire-listings` | admin/operational | Listing, Notification | Implemented |

## Request and response notes

- Provider/listing list endpoints accept query filters for search, category, area, approval/status and pagination; exact accepted keys are parsed in the handler.
- `GET /api/providers` accepts `areaId`, active `category` slug, `q`, `verified`, `openNow`, provider attribute flags, `sort` (`name`, `latest`, `rating`, `reviews`, or `distance`), `page`, `pageSize` and `meta=true`. With `meta=true` it returns `{ data, total, page, pageSize, hasMore }`; the default response remains the legacy array shape. `distance` additionally requires `latitude` and `longitude`.
- Public directory results are approved, non-archived, non-deleted providers in active areas; inactive categories are excluded from the category relation in the response.
- Each provider result includes `rating`, `reviewCount` and `openNow` (`true`, `false`, or `null` when hours are absent/invalid). Open-now uses `Africa/Cairo` and supports validated overnight ranges.
- POST/PATCH handlers validate JSON with Zod and return a created/updated record or an error object; callers must not assume every endpoint shares one envelope.
- Upload endpoints accept base64 payloads and return generated local URLs. See [Security Model](./SECURITY_MODEL.md) for validation rules.
- Admin endpoints may return summary objects, arrays or queue rows depending on the route; use the implementation as the contract.

## Authorization summary

`requireAdmin` accepts the configured API key or an admin session. `requireAdminRoles` narrows access to `OWNER`, `MODERATOR`, `REVIEWER` and `CONTENT_EDITOR` according to route. Owner routes compare the authenticated user ID to the resource owner before mutation. Public provider/listing details filter moderation state.

## Common status codes

| Code | Meaning |
|---:|---|
| 200 | Successful read/update/action |
| 201 | Resource created |
| 400 | Invalid input, state or file |
| 401 | Missing/invalid/expired session |
| 403 | Blocked user, insufficient role or ownership failure |
| 404 | Resource not visible or absent |
| 409 | Duplicate/conflicting identity or taxonomy |
| 413 | Request/image too large |
| 500 | Unexpected server/storage/database failure |

## Manual review points

There is no generated OpenAPI contract in the repository. Before publishing an SDK, inspect each handler’s Zod schema and response branch, especially admin overview/catalog, imports, backups, constants and dynamic lifecycle routes. `apps/api/src/app.ts` is legacy and must not be used as the production route catalog.

## Exact route inventory

This appendix preserves the method/path inventory from `server.ts` so a future contract extraction can compare against it:

```text
GET /health
GET /api/bootstrap
GET /ready
GET /api/admin/health/details
GET/PATCH/DELETE /api/me
GET /api/users/:id
PATCH /api/me/preferences
POST /api/auth/logout
POST /api/auth/logout-all
PATCH /api/me/password
GET /api/notifications
PATCH /api/notifications/:id/read
POST /api/notifications/read-all
POST /api/auth/register
POST /api/auth/login
POST /api/auth/federated
POST /api/auth/verification/request
POST /api/auth/verification/confirm
POST /api/auth/password-reset/request
POST /api/auth/password-reset/confirm
POST /api/admin/auth/login
POST /api/admin/auth/logout
GET /api/admin/auth/me
GET /api/areas
GET /api/categories
GET /api/providers
POST /api/uploads/provider-images
POST /api/uploads/avatar
DELETE /api/uploads/provider-images
PATCH /api/me/profile
POST/PATCH/GET /api/providers (POST creates; GET lists)
PATCH /api/providers/:id
POST /api/provider-reports
GET /api/providers/:id
POST /api/providers/:id/favorite
POST /api/providers/:id/services
POST /api/providers/:id/offers
GET /api/offers
GET/POST /api/listings
GET /api/listings/categories
GET /api/listings/:id
POST /api/listings/:id/favorite
POST /api/listings/:id/interested
POST /api/listings/:id/reports
GET /api/me/favorites
GET/POST /api/me/favorite-lists
PATCH/DELETE /api/me/favorite-lists/:id
GET/POST /api/me/saved-searches
DELETE /api/me/saved-searches/:id
GET /api/me/contributions
PATCH /api/me/reviews/:id
PATCH /api/me/listings/:id/renew
DELETE /api/me/listings/:id
POST /api/jobs/expire-listings
GET /api/ads
POST /api/ads/:id/react
POST /api/ads
GET/POST /api/prices
GET/POST/PATCH /api/admin/prices[/:id]
PATCH /api/admin/prices/:id
GET/POST /api/now
POST /api/now/:id/helpful
POST /api/support-tickets
GET/POST/PATCH /api/admin/now[/:id]
PATCH /api/admin/now/:id
POST /api/reviews
POST /api/reviews/:id/replies
POST /api/reviews/:id/helpful
GET /api/admin/overview
GET/POST /api/admin/backups
DELETE /api/admin/backups/:filename
POST /api/admin/backups/restore
PATCH /api/admin/backups/schedule
POST /api/admin/maintenance/reset
POST /api/admin/maintenance/reset-all
GET/POST/PATCH /api/admin/team[/:id]
PATCH /api/admin/team/:id
GET/PATCH /api/admin/users[/:id]
PATCH /api/admin/users/:id
GET/PATCH /api/admin/support-tickets[/:id]
PATCH /api/admin/support-tickets/:id
GET/PATCH /api/admin/listing-reports[/:id]
PATCH /api/admin/listing-reports/:id
GET /api/admin/audit
GET /api/admin/archive
GET /api/admin/catalog
GET /api/admin/review-queue
GET /api/admin/reports/summary
PATCH /api/admin/lifecycle/:entity/:id
GET /api/admin/services
GET /api/admin/offers
PATCH/DELETE /api/admin/services/:id
PATCH/DELETE /api/admin/offers/:id
POST /api/admin/import/providers
GET /api/admin/reviews
GET /api/admin/replies
PATCH /api/admin/reviews/:id/read
PATCH /api/admin/replies/:id/read
GET /api/admin/providers
GET /api/admin/providers/:id
POST /api/admin/providers
POST /api/admin/import/providers/v2
GET/PATCH /api/admin/provider-reports[/:id]
PATCH /api/admin/provider-reports/:id
GET/POST /api/admin/listings
GET /api/admin/ads
GET /api/settings
PATCH /api/admin/settings
PATCH /api/admin/providers/:id/details
PATCH/DELETE /api/admin/providers/:id
DELETE/PATCH /api/admin/listings/:id
DELETE /api/admin/services/:id
DELETE /api/admin/offers/:id
DELETE/PATCH /api/admin/ads/:id
PATCH /api/admin/providers/:id/content
PATCH/DELETE /api/admin/reviews/:id
PATCH /api/admin/replies/:id
PATCH /api/admin/listings/:id/content
GET/POST /api/admin/constants/:type
PUT/DELETE /api/admin/constants/:type/:id
```

The mounted data-collection router is included explicitly below because it is registered through `app.use` rather than as top-level handlers:

```text
GET /api/admin/data-collection/sources
GET /api/admin/data-collection/overview
GET /api/admin/data-collection/records
GET /api/admin/data-collection/duplicates
PATCH /api/admin/data-collection/records/:id
PATCH /api/admin/data-collection/duplicates/:id
POST /api/admin/data-collection/jobs
POST /api/admin/data-collection/jobs/:id/import-csv
POST /api/admin/data-collection/jobs/:id/run
PATCH /api/admin/data-collection/records/:id/social-links
POST /api/admin/data-collection/jobs/manual
```
