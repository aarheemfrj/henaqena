# Sprint 2D — Provider Experience, Reviews & Favorites

## Pre-implementation audit

**Date:** 2026-07-24  
**Scope:** provider details, gallery/contact actions, reviews/replies/helpful, and favorites only.

### Existing behavior

- `GET /api/providers/:id` already served approved providers and owner-visible pending providers, with active-area and archive filters. The response was assembled from a broad Prisma record and nested collections were not bounded consistently.
- Provider details already exposed services, current offers, images, approved reviews, replies, helpful counts, and favorite state. A dedicated paginated reviews route was not present before this sprint.
- Review creation was authenticated and duplicate-protected, but provider approval/area visibility and owner self-review were not enforced.
- Reply creation was authenticated but did not restrict replies to the provider owner.
- Helpful votes did not explicitly require an approved, visible review.
- Review editing existed for the author; deletion and a paginated review contract were missing.
- Favorite toggling used the authenticated user and named-list ownership checks; the mobile UI used optimistic state with rollback.
- Flutter `ProviderDetailPage` had gallery paging/full-screen viewing, contact actions, review creation, replies, helpful, and favorites, but helpful/reply actions triggered a full detail reload and image parsing did not deduplicate invalid URLs.

### Security and data risks found

1. Internal provider fields could be exposed through the public detail response.
2. Unbounded review nesting could make a provider detail response grow without limit.
3. A provider owner could review their own provider.
4. Any authenticated account could reply to a provider review.
5. Helpful votes could target a review that was not publicly visible.
6. The client had no explicit contract for paginated reviews or review deletion.

### Deliberate non-goals

No new product modules, booking, owner portal, video/object storage, map SDK, authentication redesign, or database migration are part of Sprint 2D.

### Audit boundary

The API hardening patch was already present in the working tree when this audit was reconstructed. It is documented here before any additional Flutter or documentation edits, and is isolated in commit `182250e`.
