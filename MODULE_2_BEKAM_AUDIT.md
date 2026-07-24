# Module 2 — بكام؟ — Pre-Implementation Audit

## Executive summary

«بكام؟» موجود حاليًا كطبقة أولية: `PriceGuide` في Prisma، قراءة عامة للأسعار المعتمدة، إرسال سعر من المستخدم للمراجعة، وإدارة بسيطة في Next.js. لا توجد بعد دورة تأكيد مجتمعية، سجل تاريخ، مؤشر freshness/confidence، أو فصل واضح بين المنتج وسعر الخدمة التقديري.

## Existing implementation

- API: `GET/POST /api/prices` and admin list/create/status routes.
- Database: `PriceGuide` with name, category, min/max, unit, source note, area, moderation status and archive/delete timestamps.
- Flutter: «بكام؟» has offers/prices tabs, pull-to-refresh and a basic contribution form.
- Web: public price cards and an admin create/moderate table.
- Existing security: session requirement for user submission, approved-only public reads and existing admin session middleware.

## Reusable components

Reuse existing `ReviewStatus`, active `Area` validation, session/blocked-user checks, audit helper, safe API error handling, pagination conventions, pull-to-refresh, admin moderation actions and Decimal serialization.

## Gaps and risks

- No submitter/owner relation means attribution and edit history are weak.
- No confirmation model or expiry means stale prices can look current.
- A simple min/max range must not imply a guaranteed service fee.
- Duplicate products and case/Arabic variants can fragment the feed.
- Outliers, promotional prices and different units need explicit handling.
- Public cards must never expose account phone/email or internal moderation fields.
- Admin status endpoint currently changes status only and needs audited archive/restore semantics.

## Recommended data model

Additive follow-up models should include a price observation/confirmation relation and optional source user/provider, reported date, expiresAt, confidence and normalized key. Keep `PriceGuide` backward compatible and do not introduce parent/child taxonomy here. A history table is preferred over overwriting published values.

## Product rules

Products may show a typical range, unit, report count, freshness and confidence. Service prices must be labelled as reported estimates and never guaranteed. Every user/admin submission is moderated; confirmations never publish an unreviewed row. Outliers require review rather than silent averaging.

## Scope for the next implementation slice

1. Harden existing create/read/admin routes and active taxonomy validation.
2. Add deterministic duplicate detection and freshness metadata without breaking current cards.
3. Add confirmation/report endpoints only after the additive migration and isolated tests.
4. Improve admin edit/archive/restore and the mobile card/form.

## Deferred

Authoritative external feeds, automatic scraping, payments, AI price prediction, provider-owned professional packages and currency-market integrations are deferred.

## GO / NO-GO

**GO for a constrained stabilization slice.** Do not claim the complete prices module or release a new tag until isolated migration/tests, admin verification and device/staging checks pass.
