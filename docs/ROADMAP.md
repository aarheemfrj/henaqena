# Engineering Roadmap

**Last verified:** 2026-07-24
**Source of truth:** Feature Status, Sprint reports, current code and product decisions
**Status:** Planning document; does not authorize implementation
**Owner:** Product + Engineering

## Completed baseline

The following baseline sprints are **closed بالكامل** and included in tag `v0.1-baseline`:

- **Sprint 1 — Production Stabilization — Closed:** auth blocking, upload validation/cleanup, IDOR protections, taxonomy safety and audit metadata.
- **Sprint 1.1 — Production Verification & Integration Testing — Closed:** isolated PostgreSQL integration tests, staging migration, backup/restore and CI coverage.
- **Sprint 1.5 — Engineering Documentation — Closed:** source-backed architecture, database, API, security, deployment, testing and feature-status documentation.

## Sprint 2 — Directory and trust depth

1. Close remaining physical Google/Apple and staging browser verification.
2. Expand provider/listing contract tests and owner workflows.
3. Improve admin audit browsing, moderation queues and import observability.
4. Reduce Flutter analyzer warnings and add critical journey smoke tests.
5. Decide taxonomy hierarchy and duplicate merge policy before schema work.

## Sprint 3 — Security and media operations

1. Design access/refresh-token rotation with revocation and replay detection.
2. Introduce media scanning/thumbnails and a durable object-storage plan.
3. Define backup encryption, retention, restore drills and alerting.

## Sprint 4 — Product expansion

Only after the foundation is stable: richer prices/history, Qena Now source workflows, events, transport, jobs and other community modules. Each module requires API, admin, mobile UX, moderation rules and tests.

## Dependencies and gates

- No new module should bypass ownership/moderation rules.
- No schema migration without duplicate/reference audit and separate restore test.
- External integrations require credentials, quotas, privacy review and physical-device verification.
- Keep the [Feature Status](./FEATURE_STATUS.md) matrix honest; planned work is not shipped work.
