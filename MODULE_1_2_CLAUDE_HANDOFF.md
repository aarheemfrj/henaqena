# Hena Qena — Module 1 + Module 2 Closure Handoff

هذا الملف هو نقطة التسليم الرسمية إلى Claude. يجب تنفيذ الخطة بالترتيب، مع الفصل بين كل مرحلة والأخرى، وCommit مستقل عند اكتمال كل مرحلة.

## قواعد العمل غير القابلة للتغيير

- المشروع على فرع `main`.
- لا تبدأ Module 3 أو أي Product Feature جديدة.
- لا تغيّر الـArchitecture إلا لعيب حقيقي مكتشف أثناء التحقق.
- لا تضف Price History أو Migration جديدة للتاريخ في هذه المهمة.
- لا تستخدم Production Database للاختبارات.
- لا تستخدم AI أو Payments أو Chat أو Marketplace أو Push infrastructure جديدة.
- لا تنشئ أي Tag قبل نجاح Release Gate الخاص بالموديول.
- لا تعمل Force Push ولا تعدّل Tags سابقة.
- حافظ على الملفات المحلية غير المتتبعة التالية ولا تضفها أو تحذفها:
  - `docs/DEPLOYMENT_NOTES.md`
  - `while closing eyes-henaqena.sql.gz`
  - `while closing eyes-uploads.tar.gz`
  - `while closing eyes.bundle`

## الحالة الحالية

### Core

Core stabilization مكتمل سابقًا.

### Module 1 — «مين شاطر؟»

الحالة الحالية: **Partial / غير مغلق رسميًا**.

الموجود فعليًا:

- نماذج الطلبات والترشيحات والبلاغات.
- دورة Pending/Approved/Rejected/Archived/Deleted.
- Public feed/detail/recommendations.
- إنشاء وتعديل وحذف وإغلاق الطلبات.
- Provider recommendation وManual recommendation.
- Helpful مع حماية التكرار.
- Reports.
- Admin moderation center.
- User contributions.
- Flutter feed/request/recommendation flows.
- API integration coverage.

الفجوات التي تمنع الإغلاق:

- Staging runtime verification.
- Android verification.
- iOS verification.
- Notification deep-link verification في foreground/background/closed app.
- التأكد اليدوي من owner/admin journeys على بيئة staging.
- أي Defects حقيقية تظهر أثناء التحقق.

لا يوجد Tag `v0.7-min-shater` حتى الآن لأن Release Gate لم ينجح بالكامل.

### Module 2 — «بكام؟»

الحالة الحالية: **Stabilization Slice / غير جاهز للإصدار**.

الموجود فعليًا:

- Public approved/active/non-expired prices.
- إخفاء الأسعار المؤرشفة والمحذوفة والمناطق غير النشطة.
- منع القيم الصفرية والسالبة.
- حماية duplicate pending/approved submissions.
- `PriceConfirmation` بعلاقة one-per-user/price وupsert.
- Confirmation count وlatest confirmation وviewer state.
- `validUntil`, `confidenceScore`, `sourceType`, `lastReviewedAt`.
- Admin create/edit/approve/reject/archive/restore.
- Audit logs لعمليات الإدارة والتأكيد.
- Advisory outlier signal حسب category + area.
- `GET /api/admin/prices?outliersOnly=true`.
- Flutter confirmation and freshness/confidence display.
- Admin direct editing for name/category/range/unit/source/validity/confidence.

الفجوات التي تمنع الإغلاق:

- Staging migration and data-preservation verification.
- Runtime verification على Android وiOS.
- Browser verification لمسار الإدارة كاملًا.
- Offline/weak-network verification.
- إصلاح العيوب الحقيقية فقط إن ظهرت أثناء التحقق.
- قرار Price History موثق فقط، دون تنفيذ Migration جديدة.

لا يوجد Tag `v0.8-bekam` حتى الآن.

## أهم Commits الحالية

### Module 1

- `5f70b88`
- `03df68c`
- `95922d6`
- `622a26e`
- `cfbd511`
- `8beae58`
- `1a124e1`
- `4d50094`

### Module 2

- `59c4e10` — audit
- `00e4277` — validation/freshness hardening
- `7321b84` — confirmations API/model
- `90ca7f5` — mobile confirmation
- `f3e27e5` — freshness/confidence/archive lifecycle
- `8a21873` — mobile freshness display
- `3f1762c` — advisory outlier review
- `ecd6d92` — admin outlier filter/docs
- `4b4ba3b` — admin editing/archive controls
- `3ef5f88` — admin editing regression test
- `8a1d1e4` — Module 2 handoff

## الملفات التي يجب قراءتها أولًا

- `MODULE_1_MIN_SHATER_AUDIT.md`
- `MODULE_1_MIN_SHATER_REPORT.md`
- `MODULE_2_BEKAM_AUDIT.md`
- `MODULE_2_BEKAM_REPORT.md`
- `MODULE_2_BEKAM_HANDOFF.md`
- `SPRINT_2F_POST_SPRINT_2_STABILIZATION_FREEZE_REPORT.md`
- `PROJECT_ACTIVITY_LOG.md`
- `docs/CHANGELOG.md`
- `docs/FEATURE_STATUS.md`
- `docs/ROADMAP.md`
- `docs/SYSTEM_ARCHITECTURE.md`
- `docs/DATABASE_GUIDE.md`
- `docs/API_REFERENCE.md`
- `docs/BUSINESS_RULES.md`
- `docs/SECURITY_MODEL.md`
- `docs/TESTING_GUIDE.md`
- `docs/DOCUMENTATION_GAPS.md`

## ترتيب التنفيذ المطلوب

### المرحلة 1 — Repository and Baseline Audit

تحقق من:

- `git status`, branch, HEAD, latest commits, existing tags.
- untracked files.
- pending migrations.
- working tree.
- availability of staging, devices and environment variables.

أنشئ:

- `MODULE_1_2_RELEASE_CLOSURE_AUDIT.md`

سجل فيه baseline وGO/NO-GO لبدء التحقق فقط. لا تنشئ Tag.

Commit:

`docs(release): audit module 1 and module 2 closure baseline`

### المرحلة 2 — Module 1 Static Verification

شغّل:

- API: `npm run prisma:generate`, `npm run test:db`, `npm run build`
- Web: `npm run lint`, `npm run build`
- Flutter: `flutter analyze --no-fatal-infos --no-fatal-warnings`, `flutter test`
- `git diff --check`
- documentation links, secrets scan, route docs, public-field leak, IDOR, blocked-user, audit-log checks.

تحقق من request/recommendation lifecycle، visibility، ownership، helpful، reports، admin moderation، notifications، deep links، pagination، Arabic normalization، loading/error/retry/stale protection.

### المرحلة 3 — Module 1 Staging and Device Verification

على Staging غير إنتاجي:

- طبّق migrations بأمان.
- خذ backup وسجّل row counts قبل وبعد.
- اختبر guest، authenticated user، owner، recommendation، helpful، reports، admin moderation.
- اختبر notification targets وdeep links في foreground/background/closed app.
- اختبر Android وiOS، وoffline/weak network/reconnect/double tap/pagination/pull-to-refresh.

أي شيء غير متاح يسجل `UNVERIFIED` صراحة.

### المرحلة 4 — Module 1 Fixes Only

أصلح فقط defects حقيقية مثل crash، visibility، IDOR، deep-link، duplicate، stale state، owner action، audit، privacy leak، closed-request bypass.

أضف regression test لكل إصلاح. لا تضف صورًا أو Chat أو AI أو Anonymous posting أو social expansion.

### المرحلة 5 — Module 1 Final Report and Gate

حدّث `MODULE_1_MIN_SHATER_REPORT.md` بكل النتائج.

ينجح Release Gate فقط إذا:

- pending/rejected مخفيان عن العامة.
- owner يرى pending.
- ownership وclosed-request rules سليمة.
- duplicate recommendation/helpful محميان.
- reports/admin moderation تعمل.
- notification deep links تعمل.
- لا يوجد private data leak.
- API/Web/Flutter checks ناجحة.
- staging وAndroid وiOS verified أو blocker موثق.
- لا يوجد Critical/High مفتوح.

عند النجاح فقط:

- Commit: `feat(min-shater): close community recommendations release`
- Annotated tag: `v0.7-min-shater`

عند الفشل: لا تنشئ Tag، وسجّل NO-GO.

### المرحلة 6 — Module 2 Static Verification

تحقق من public filtering، submission validation، confirmation uniqueness، freshness، confidence، admin lifecycle، outlier privacy، audit، Decimal serialization، blocked-user and rate limits.

شغّل نفس أوامر API/Web/Flutter وchecks الخاصة بالتسريب والمigrations والـoutlier.

### المرحلة 7 — Module 2 Staging Verification

استخدم Staging غير إنتاجي فقط:

- Backup قبل migrations.
- row counts وmigration status قبل/بعد.
- طبّق:
  - `20260724220619_price_confirmations`
  - `20260724224317_price_freshness_confidence`
- تحقق من preserving existing data/defaults/indexes.
- اختبر public visibility لكل الحالات.
- اختبر create/edit/approve/reject/archive/restore/outlier filter/audit.
- اختبر confirmations، expiry، inactive areas، duplicates، guest/blocked restrictions.

### المرحلة 8 — Module 2 Device and Browser Verification

على Android وiOS:

- افتح «بكام؟».
- confirm «أيوه» ثم «اتغير».
- تحقق من persistence/count/freshness/confidence.
- guest CTA، offline، weak network، reconnect، no duplicate cards، no crash.

على Chrome ويفضل Safari:

- admin login، create، edit، approve/reject، archive/restore، outlier filter، refresh، empty/error، direct reload، unauthorized role.

### المرحلة 9 — Module 2 Fixes Only

أصلح فقط defects فعلية، وأضف regression tests. لا تضف price history أو scraping أو AI أو payments أو notifications جديدة.

### المرحلة 10 — Price History Decision

أنشئ فقط:

- `MODULE_2_PRICE_HISTORY_DECISION.md`

يتضمن limitations الحالية، بدائل PriceObservation/versioning، migration/query/admin/mobile impact، backfill/retention، recommendation، وGO/NO-GO لمهمة مستقبلية.

لا تضف migration للتاريخ الآن.

### المرحلة 11 — Module 2 Final Report and Gate

حدّث `MODULE_2_BEKAM_REPORT.md` ليشمل static/staging/device/browser/migration/security/audit/outlier/results/limitations.

عند نجاح كل gates فقط:

- Commit: `feat(bekam): close community price guide release`
- Annotated tag: `v0.8-bekam`

وإلا: NO-GO بلا Tag.

### المرحلة 12 — Combined Closure

أنشئ:

- `MODULE_1_2_RELEASE_CLOSURE_REPORT.md`

يتضمن جدول Module 1 وModule 2، HEAD، final status، commits/tags، untracked artifacts، secrets/docs status، وتوصية Module 3.

لا توصي ببدء Module 3 إلا إذا كان الموديولان GO، والـTags موجودة، ولا يوجد Critical/High، والـworking tree نظيف باستثناء الملفات المحلية المحفوظة عمدًا.

### المرحلة 13 — Documentation Updates

حدّث حسب النتيجة الفعلية:

- `docs/CHANGELOG.md`
- `docs/FEATURE_STATUS.md`
- `docs/ROADMAP.md`
- `docs/SYSTEM_ARCHITECTURE.md`
- `docs/DATABASE_GUIDE.md`
- `docs/API_REFERENCE.md`
- `docs/BUSINESS_RULES.md`
- `docs/SECURITY_MODEL.md`
- `docs/TESTING_GUIDE.md`
- `docs/DOCUMENTATION_GAPS.md`
- `PROJECT_ACTIVITY_LOG.md`

لا تكتب `Completed` إذا كانت runtime/device verification ناقصة.

### المرحلة 14 — Final Validation

أعد تشغيل كل أوامر API/Web/Flutter، ثم:

- `git diff --check`
- `git status --short`
- internal-link check
- secrets scan
- route docs check
- destructive migration check
- public response leak check
- pending/rejected check
- outlier public leak check
- audit coverage
- untracked artifact preservation

## الناتج النهائي المطلوب

1. `MODULE_1_MIN_SHATER_REPORT.md`
2. `MODULE_2_BEKAM_REPORT.md`
3. `MODULE_2_PRICE_HISTORY_DECISION.md`
4. `MODULE_1_2_RELEASE_CLOSURE_AUDIT.md`
5. `MODULE_1_2_RELEASE_CLOSURE_REPORT.md`
6. سبب إنشاء أو عدم إنشاء `v0.7-min-shater`
7. سبب إنشاء أو عدم إنشاء `v0.8-bekam`
8. Final GO/NO-GO لبدء Module 3

## Instruction to Claude

Continue from this handoff and inspect the repository before editing. Execute one phase at a time, create a separator commit between phases, record unavailable environment/device checks as `UNVERIFIED`, never claim release readiness without evidence, and do not begin Module 3.
