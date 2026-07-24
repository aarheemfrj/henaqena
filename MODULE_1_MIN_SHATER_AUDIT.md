# Module 1 — مين شاطر: Pre-Implementation Audit

**Date:** 2026-07-24  
**Auditor:** Codex  
**Baseline:** `v0.6-stable-core` (post-Sprint-2 stabilization freeze)  
**Status:** Audit complete; product implementation intentionally not started.

## Executive summary

«مين شاطر» غير موجود حاليًا كموديول مستقل في API أو Prisma أو Flutter أو لوحة الإدارة. الموجود هو دليل مقدمي الخدمات، التقييمات والردود، البلاغات، الحفظ، والإشعارات والمساهمات العامة. هذه البنية توفر معظم الحواجز المطلوبة، لكنها لا تجيب سؤال الترشيح المجتمعي: الدليل يجيب «مين موجود؟»، بينما هذا الموديول يجيب «الناس بترشح مين لمهمة معينة؟».

القرار: **GO للتنفيذ المرحلي بعد هذا التدقيق**، مع إبقاء الصور والنشر المجهول ووسم «أفضل ترشيح» الموسع خارج الإصدار الأول. لا توجد تعديلات Product Logic أو Migration ضمن مرحلة التدقيق.

## Existing implementation

- Flutter يعرض تبويب «مين؟» كواجهة الدليل الحالية (`DirectoryPage`) وليس كصفحة ترشيحات.
- API الإنتاجي هو Express في `apps/api/src/server.ts`، مع Prisma/PostgreSQL؛ لا يوجد `MinShater*` route أو model.
- `/api/me/contributions` يجمع providers/listings/reviews/reports فقط، ولا يملك أسئلة أو ترشيحات.
- `Provider`, `Review`, `ProviderReport`, `ListingReport`, `Notification` و`AuditLog` هي أقرب وحدات قائمة.
- مركز الاعتماد الموحد (`/admin/review-center`) وقوائم الإدارة الحالية تدعم أنماط Pending/Approved/Rejected والمراجعة، لكن لا تعرض Min Shater.

## Reusable components

- `sessionFromRequest` يمنع الجلسات للمستخدم المحظور، ويؤكد تسجيل الدخول.
- `publicAuthorSelect` يعرض هوية آمنة دون البريد أو الهاتف.
- `ReviewStatus` يوفر دورة Pending/Approved/Rejected القابلة لإعادة الاستخدام.
- فحص نشاط `Category` و`Area`، ومنع التكرار الحساس لحالة الأحرف.
- pagination ثابتة (`page`, `pageSize`, `hasMore`) مع حدود قصوى وترتيب deterministic.
- تطبيع العربية المستخدم في البحث الحالي.
- rate limiting، Zod validation، ownership checks، و`audit()` مع actor ID/role.
- public provider projections، visibility filters للـapproved/active/non-archived، وsafe media/phone handling.
- Notification `targetType`/`targetId` للفتح العميق.
- Flutter: `ApiClient`, `AuthSession`, `RefreshIndicator`, حالات loading/empty/error/retry، `ContributionsPage`، بطاقات الهوية، RTL والتنقل والـtheme.
- Next.js: `apiGet`/admin session، review center، filters/pagination/actions، وrole guards.

## Existing data models

| Model | Relevance | Reuse decision |
|---|---|---|
| `User`/`Session` | المؤلف، الحظر، الملكية | إعادة استخدام |
| `Provider`/`ProviderCategory` | ترشيح نشاط موجود | ربط اختياري مع approved provider فقط |
| `Category`/`Area` | تصنيف ومنطقة السؤال | إعادة استخدام مع active validation |
| `Review`/`ReviewHelpful` | نمط التفاعل وليس بديلًا للسؤال | لا نخلط التقييم بالترشيح |
| `ProviderReport`/`ListingReport` | نمط البلاغ والمراجعة | إنشاء report target خاص بالموديول |
| `Notification` | قرارات المراجعة/الترشيح | إعادة استخدام target deep-link |
| `AuditLog` | إجراءات الإدارة الحساسة | إعادة استخدام |

لا توجد جداول حالية لطلبات الترشيح أو الترشيحات أو Helpful خاص بها.

## Existing API patterns

- المسارات العامة تعيد إسقاطات صريحة ومحدودة، ولا تسلسل `User` الخام.
- المسارات الخاصة تبدأ بحل الجلسة، ثم تحقق الملكية والحالة والحظر.
- المحتوى المجتمعي يدخل المراجعة؛ المحتوى الذي تنشئه الإدارة يعتمد مباشرة.
- delete/archive في المحتوى الحالي soft lifecycle حيث تدعم الجداول ذلك.
- البلاغات لا تحذف تلقائيًا، وإجراءات الإدارة تسجل AuditLog.
- البحث الحالي يطبع العربية ويستخدم relevance bounded بدل fuzzy/AI.
- pagination والفرز يستخدمان ترتيبًا ثابتًا ومعايير tie-breaker.

## Existing Flutter patterns

- `main.dart` ما زال يحتوي معظم الشاشات، مع `ApiClient` منفصل للشبكة.
- `DirectoryPage` هو المسار الحالي الذي يفتح من تبويب «مين؟»؛ لا يوجد feed Min Shater.
- `ContributionsPage` يعرض مساهمات المستخدم الحالية ويمكن تمديده لتبويبي «أسئلتي/ترشيحاتي».
- توجد أنماط pull-to-refresh، retry، empty/error، وحماية زر الإرسال من التكرار يمكن إعادة استخدامها.
- الهوية الآمنة الحالية تعرض الاسم/الصورة دون كشف بيانات الحساب الخاصة، وRTL/theme قائمين.

## Existing admin patterns

- `apps/web/app/admin/review-center/page.tsx` مركز اعتماد موحد، مع إجراءات server actions.
- صفحات providers/listings/reviews/reports/archive/audit تستخدم جلسة الإدارة وأنماط status/filter/pagination.
- الأدوار الموجودة: `OWNER`, `MODERATOR`, `REVIEWER`, `CONTENT_EDITOR`؛ لا حاجة لدور جديد.
- `auditContext` يضيف `adminId` و`adminRole` إلى metadata في العمليات الإدارية.

## Product risks

- الخلط بين «الدليل» و«مين شاطر» قد يحوّل الترشيحات إلى قائمة مزودي خدمات غير موثقة.
- الترشيح اليدوي قد يكون لشخص غير موجود، لذلك لا يجوز إنشاؤه تلقائيًا كـProvider.
- الترشيح ليس تقييمًا ولا يجب أن يؤثر على rating أو verification.
- الطلبات المغلقة يجب أن تبقى قابلة للقراءة ولا تقبل ترشيحات جديدة.
- نشر Pending/Rejected سيقوض الثقة؛ دورة المراجعة إلزامية.

## Security risks

- IDOR في request/recommendation/report IDs؛ كل mutation يجب أن تقارن owner/session.
- المستخدم المحظور يجب منعه من الإنشاء، الترشيح، Helpful والبلاغ.
- providerId غير المعتمد يجب رفضه حتى لو عُرف ID مباشرة.
- لا تقبل moderation status أو helpful count من العميل.
- duplicate recommendation وduplicate helpful يجب حمايتهما بقيد/transaction.
- الإدارة تحتاج role checks وAuditLog لكل قرار أو إخفاء أو أرشفة.

## Privacy risks

- لا نعرض email أو account phone أو internal user ID في public projection.
- رقم الهاتف داخل الترشيح اليدوي هو محتوى أدخله المستخدم، وليس رقم حسابه؛ يلزم تطبيع/تحقق وسياسة إظهار واضحة.
- التوصية الأولية: لا يظهر رقم الترشيح اليدوي للضيف، ويظهر فقط بعد اعتماد وبحسب سياسة الحساب المسجل؛ لا يُسجل نص الهاتف في logs.
- لا يوجد anonymous posting في الإصدار الأول؛ نستخدم display name الحالي أو «عضو من قنا» حسب إعداد الخصوصية.
- هوية المبلّغ لا تظهر لصاحب المحتوى.

## Moderation risks

- القرار المقترح: السؤال والترشيح يدخلان `PENDING`، ولا يظهران للعامة قبل `APPROVED`.
- صاحب السؤال/الترشيح يرى حالة ومبرر الرفض الخاص به فقط.
- التعديل بعد الاعتماد يعيد المحتوى للمراجعة إذا كان هذا نمط النظام الحالي.
- البلاغات لا تحذف تلقائيًا؛ الإدارة تقرر resolve/dismiss/hide/archive.
- محتوى الإدارة المباشر يمكن اعتماده مباشرة فقط إذا كان إنشاءً إداريًا موثقًا.

## Duplicate-feature risks

- لا نعيد بناء دليل providers أو reviews أو contributions؛ Min Shater طبقة سؤال/ترشيح مستقلة.
- لا نستخدم Provider rating كترتيب للترشيحات.
- لا نضيف Social feed أو chat أو AI similarity.
- لا نضيف media module؛ نعيد استخدام media فقط في إصدار لاحق بعد مراجعة moderation.

## Recommended data model

إذا لم توجد جداول بديلة عند التنفيذ، أضف Migration additive للنماذج التالية:

- `MinShaterRequest`: userId, title, description, categoryId, areaId nullable, `status`, `moderationStatus`, rejectionReason, timestamps، closed/archived/deleted fields.
- `MinShaterRecommendation`: requestId, userId, providerId nullable، recommendedName nullable، phone/description، `moderationStatus`, rejectionReason، timestamps/lifecycle.
- `MinShaterHelpful`: recommendationId + userId، unique composite.
- `MinShaterReport`: reporterUserId، requestId أو recommendationId، reason/description/status، reviewer/timestamps.

قيود التنفيذ: category مطلوب ونشط، area إن وجد نشط، provider approved/active فقط، provider أو manual name أحدهما مطلوب، وفهارس للحالة والملكية والطلب والمزود والتاريخ والأرشفة. يفضل استخدام `ReviewStatus` القائم وتجنب enums مكررة.

## Recommended lifecycle

1. سؤال/ترشيح جديد → Pending.
2. صاحب المحتوى يرى Pending وسبب الرفض إن وجد.
3. Approved فقط يظهر في feed/detail العام.
4. Closed يبقى مقروءًا ولا يقبل ترشيحات.
5. Rejected/Archived/Deleted مخفي للعامة، والـsoft delete يحفظ الأثر.
6. تعديل المحتوى المعتمد يعيده للمراجعة عند الحاجة.
7. Helpful idempotent، والبلاغ يفتح مسار مراجعة ولا يحذف آليًا.

## Recommended public projections

### Request
`id`, `title`, short description، category id/name، area id/name أو «كل قنا»، safe author display، createdAt، open/closed، recommendationCount، viewer-safe flags فقط.

### Recommendation
`id`, safe provider summary إن وجد، manual name، phone وفق سياسة الإظهار، description، safe author display، createdAt، helpfulCount، viewerHelpful، accepted flag إن نُفذ لاحقًا، owner action flags.

لا تُعرض moderationStatus أو rejectionReason أو email/phone الحساب أو audit fields أو raw Prisma objects.

## Scope selected

- Audit ثم additive data model.
- Public feed/detail/recommendations/similar.
- Authenticated create/update/close/delete/my contributions.
- Provider-linked وmanual recommendations.
- Helpful/reporting، notifications، moderation/admin queue.
- Flutter feed/create/detail/recommendation/contributions.
- API integration tests وFlutter tests وdocumentation.

## Deliberately deferred items

- Anonymous posting.
- الصور داخل الأسئلة/الترشيحات.
- AI/fuzzy similarity أو auto-merge.
- توسيع Best Recommendation؛ يمكن تنفيذ اختيار واحد للمالك فقط إذا ظل بسيطًا وآمنًا.
- تأثير الترشيحات على تقييم/توثيق Provider.
- Chat، push infrastructure، access/refresh rotation، category parent/child، PostGIS/Redis/Elastic.

## Implementation stages

1. Data model and isolated migration.
2. Shared domain/public projections and API feed/detail.
3. Authenticated requests and recommendation API.
4. Helpful, reports, notifications and moderation.
5. Admin management center and role matrix.
6. Flutter feed/create/detail/recommendation/contributions.
7. Integration/widget tests, performance checks and documentation.
8. Full release gate; tag only after all required checks pass.

## GO / NO-GO

**GO for implementation after this audit commit.**  
**NO-GO for release/tag** until isolated PostgreSQL tests, migration/restore verification, API/Web/Flutter gates, public visibility checks, IDOR checks, audit checks and manual/device/staging evidence are complete.

