# Hena Qena implementation status

Last reviewed: 2026-07-22

This is the implementation checklist used by Codex and Claude. A phase is only marked complete when its code path exists and its automated checks pass; provider credentials and store accounts are tracked separately.

| Phase | Status | Evidence / remaining work |
|---|---|---|
| 0. Runtime foundation | Complete | Prisma migrations, isolated `henaqena` database, production deploy script, CI database service. |
| 1. Account and identity | Code complete, external setup pending | Sessions, logout, password reset, preferences, profile privacy, federated-token verification, and OTP webhook adapters exist. WhatsApp/SMS/email provider credentials remain external. |
| 2. Directory and search | Code complete | Provider search, pagination, filters, details, images, services/offers, contact links, and map-link fallback exist. Production Google Maps keys remain external. |
| 3. Community submissions | Code complete | Add/edit/report/ownership flows, moderation queues, audit records, notifications, and contribution history exist. |
| 4. Local listings | Code complete | Submission, moderation, images, reactions, expiry/renewal, archive and report routes exist. |
| 5. Reviews and reputation | Code complete | Category ratings, comments, replies, moderation, helpful votes, profiles, points and Qenawy levels exist. |
| 6. Prices, now and home ads | Code complete | Prices, offers, now updates, weighted/targeted home ads, seasonal settings and admin controls exist. |
| 7. Notifications/maps/search | Code complete, external setup pending | In-app notification center, preferences, pagination and map fallback exist. FCM/APNs and production map keys remain external. |
| 8. Admin platform | Code complete | Admin sessions/roles, moderation centers, import, constants, audit, users and content management exist. |
| 9. Production hardening | Partially complete | HTTPS/PM2/health checks and CI are live. Object storage, automated backups, monitoring and final secret rotation remain. |
| 10. Release QA | In progress | API/web CI passes; Flutter CI is being aligned with the current SDK. Real-device regression and store submission remain. |

## External blockers

The following are intentionally not fabricated in code: OTP provider credentials, Google/Apple client configuration, Firebase/APNs credentials, Google Maps keys, S3-compatible storage credentials, and Apple/Google store accounts.
