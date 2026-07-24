# Changelog

All notable engineering changes are documented here. Product features outside the stated sprint scope are not implied by an entry.

## Unreleased

### Added
- Sprint 2B provider search suggestions and bounded relevance-ranked search.

### Changed
- Directory search now normalizes Arabic text at query time, matches approved provider services and keeps exact/name matches ahead of weaker descriptive matches.

### Fixed
- Nothing currently staged.

### Security
- No security model changes staged.

### Documentation
- Sprint 2B search report and API contract documentation updated.

### Known Issues
- Physical OAuth verification and production browser verification remain environment-dependent.

## v0.2-directory — 2026-07-24

### Added
- A paged public directory contract with optional metadata, stable ordering and load-more support in Flutter.
- Active-only category/area filtering, reset controls and directory data-quality indicators in admin reports.

### Changed
- Provider listing now exposes safe rating/review/open-now metadata and supports name, latest, rating, review-count and nearest ordering.
- Open-now evaluation uses Africa/Cairo time, validated clocks and overnight ranges without treating invalid hours as open.

### Fixed
- Public directory queries no longer surface providers attached to inactive areas/categories; invalid pagination and sort values return clear 400 responses.
- Directory pagination deduplicates appended results and excludes providers without coordinates from nearby distance filtering.

### Security
- Public provider listing continues to require approved, non-archived, non-deleted records.

### Documentation
- API, testing, roadmap, feature-status and project activity documentation updated for Sprint 2A.

### Known Issues
- Provider-per-location remains the current branch representation; no dedicated Branch model was introduced.
- Distance ordering uses a simple coordinate-distance approximation and remains a candidate for a spatial query in a later maps sprint.

## v0.1-baseline — 2026-07-24

- Sprint 1 stabilized authentication blocking, uploads, ownership checks, taxonomy safety and audit metadata.
- Sprint 1.1 verified isolated PostgreSQL integration tests, staging migration and backup/restore workflow.
- Sprint 1.5 established source-backed engineering documentation, route inventory and validation rules.
- Baseline `v0.1-baseline` was established without adding product modules.
## Unreleased — Sprint 2D

- Hardened provider detail projection and active-area visibility.
- Added paginated provider reviews, owner-only replies, approved-review helpful checks and author review deletion.
- Improved mobile provider detail refresh, rating/open-state display, gallery URL deduplication and favorite synchronization.
