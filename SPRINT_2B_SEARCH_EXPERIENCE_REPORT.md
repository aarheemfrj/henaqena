# Sprint 2B — Search Experience Report

**Status:** In progress
**Previous version:** `v0.2-directory`
**Scope:** Search experience only; no new product module, maps clustering, provider-page rebuild, authentication change or taxonomy hierarchy.

## Pre-implementation audit

### Existing behavior

- Public search is currently folded into `GET /api/providers?q=...`.
- The API uses PostgreSQL `contains` matching on provider name, description, address and active category name, then computes rating/open-now metadata and paginates in application memory.
- Flutter's directory screen debounces input for 350ms, sends the query to the providers endpoint, and has a local normalized fallback only after an empty API response.
- Saved searches are account-backed through `/api/me/saved-searches`; recent search history is not implemented as a separate capability.
- The web public provider/listing pages and admin data-collection/catalog pages use their own query parameters and do not share a typed search contract.

### Searchable entities in the current structure

- Providers, provider descriptions/addresses, active provider categories and provider services are present in Prisma.
- Active areas/categories are already exposed through the public taxonomy endpoints.
- Listings, prices and offers have separate endpoints; a unified search over those entities is not currently present and remains out of scope unless a safe existing query path supports it.
- News/events/jobs/real-estate/cars are not part of the current public provider-search contract.

### Current ranking, filtering and pagination

- Default provider ordering is verified-first, then Arabic name and ID; explicit sorts include name, latest, rating, review count and distance.
- Existing filters include area, category slug, verification, open-now and provider attributes. Pagination is page/pageSize with optional metadata and deterministic tie-breakers.
- Search relevance is not ranked: a weak description/category match can appear ahead of a direct name match.
- Search does not currently normalize Arabic text on the API, search provider services, expose suggestions, or provide a separate recent-history store.

### Risks and UX gaps

- Normalization differences (hamza forms, diacritics, tatweel and Arabic digits) can miss visually equivalent names.
- Provider-service names are not included in the current API search predicate.
- Loading/empty/error/retry states exist in Flutter, but suggestions, recent history, and stale-request protection are incomplete.
- The current in-memory score/pagination path is acceptable for the initial catalog but should be measured and kept bounded; no search-engine migration is justified for this sprint.
- Existing Prisma models have no search-specific indexes; no migration is justified before measuring a real query bottleneck.

This audit is the boundary for Sprint 2B implementation.

## Implementation status

### Stage 1 — API search contract and relevance (completed)

- Added bounded `q`/`categoryId` validation while preserving the existing `/api/providers` response contract.
- Added non-destructive Arabic/English normalization, a small documented alias dictionary and relevance tiers: exact name, prefix, name contains, service, category, area, then descriptive fields.
- Included approved, active provider services in matching without exposing an internal relevance field to clients.
- Added `/api/search/suggestions` with bounded results and approved/active visibility rules.
- Preserved deterministic pagination and stable tie-breakers across supported sorts.
- Added integration coverage for normalization, relevance, service/category/area matching, suggestions, inactive taxonomy exclusion, query limits and pagination.

**Validation:** isolated PostgreSQL test workflow passed: 8 suites, 82 tests. API build passed.

**Commit boundary:** to be recorded after staging this completed stage.
