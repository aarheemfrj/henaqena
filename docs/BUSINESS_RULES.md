# Business Rules

**Last verified:** 2026-07-24
**Source of truth:** `apps/api/src/server.ts`, Prisma schema and Sprint 1/1.1 tests
**Status:** Verified for current API paths; external providers are Unverified
**Owner:** Product + Engineering

Each rule below names the enforced outcome. UI wording is not a substitute for the API rule.

## Identity and sessions

| Rule | Source | Actors | Result / error | Status |
|---|---|---|---|---|
| Blocked users cannot use an existing session | `server.ts` session resolver | User | 403; session is not accepted | Implemented |
| Blocked users cannot password/federated login | auth routes | User | 403 | Implemented |
| Password sessions last 30 days | auth/session code | User | expiry produces 401 | Implemented |
| Admin sessions last 12 hours | admin auth code | Admin | expiry produces 401 | Implemented |
| Federated email collision is rejected, not auto-merged | federated auth | User | 409 conflict | Implemented |
| Admin/system accounts cannot be blocked | admin users route | Owner/admin | 400/403 | Implemented |
| Access/refresh rotation | Not present | — | Deferred security sprint | Planned |

## Directory and moderation

- Public provider detail is visible only when approved. An authenticated owner may see their own pending provider for correction.
- Provider and listing mutations require the authenticated owner or an allowed admin role; direct IDs do not bypass ownership checks.
- Community submissions enter moderation. Content created through the admin control plane is treated as reviewed and is approved directly.
- Referenced categories/areas are deactivated rather than deleted; unused records may be deleted.
- Category/area names are compared case-insensitively for duplicates.
- Flat categories are current behavior; parent/child taxonomy is not implemented.

## Listings and media

- Listing state is controlled by `ListingStatus` plus archive/expiry fields; expired records are not treated as active public content.
- Provider/listing/avatar images accept JPEG, PNG or WebP bytes only, regardless of declared MIME; each image is limited to 2 MiB.
- Filenames are generated server-side. Replacements remove prior local files only after the new reference is accepted.
- Remote image URLs are never deleted by local cleanup. Unreferenced local files older than 24 hours are cleanup candidates.

## Reviews, reactions and favorites

- Reviews and replies are public only according to moderation status; provider details expose a bounded first page and `/api/providers/:id/reviews` provides deterministic pagination.
- A provider owner cannot review their own provider, and only the provider owner may reply to reviews for that provider.
- Helpful votes require an approved, visible review. Review deletion is limited to the review author.
- Favorite lists belong to one user; another user’s list ID is rejected.

## Notifications and settings

- Notifications are persisted rows with `readAt`; read-one and read-all mutate that state.
- `targetType`/`targetId` identify the entity for deep-linking. Push provider delivery is not implemented.
- Platform settings such as refresh/rotation intervals are admin-controlled and read by clients.

## Limits and operational rules

- JSON request body limit is 24 MB to accommodate encoded image batches.
- Admin actions should create audit entries including actor ID and role.
- Imports, archives and moderation must preserve referential integrity and should be tested against staging before production.

## Documentation discrepancies

- Older README text calls the API “core server” and lists only selected routes; the Express route inventory in [API Reference](./API_REFERENCE.md) is authoritative.
- Product plans mention Google/Apple, push, dynamic category hierarchy and external price/news sources; only the current API-backed portions are implemented.
