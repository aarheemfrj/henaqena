# Hena Qena — Project Memory

> This file is the authoritative working memory for Codex, Claude, and any developer joining the project.
> Update it whenever a major product, design, architecture, or scope decision changes.

---

## 1. Project Identity

**Project name:** Hena Qena  
**Arabic name:** هنا قنا  
**Parent company:** MaalSoft  
**Parent domain:** `maalsoft.com`  
**Official MaalSoft slogan:** لكل رقم قيمة

### Product positioning

Hena Qena is a local community services mobile application that starts in Qena Governorate, Egypt.

The product should not begin as:

- A food-delivery app.
- A ride-hailing app.
- A transportation operator.
- A payment wallet.
- A purely static business directory.
- A government service replacement.

The product should begin as:

> A trusted local information and community-services platform that helps people discover services, compare local prices, and know what is happening around them.

### Approved community direction

Hena Qena should feel like a comfortable local community where people can discover, contribute, ask, recommend, report, and return for useful daily information. The product may grow toward a local-community super-app, but it must not become an unfocused copy of a general social network.

Community capabilities should be built in layers:

- MVP foundation: profiles, contributions, reviews, prices, local alerts, classified advertisements, confirmations, reports, moderation, notifications, and easy sharing.
- Later community layer: a broader local feed, comments, reactions, follows, area/topic communities, and richer public profiles.
- Later social/market layer: private messaging, transactions, bookings, and other high-risk interactions only after trust, operations, and safety controls are proven.

All public community content remains subject to administration review, reporting, abuse controls, and clear local-safety and privacy rules.

### Approved community interaction and reputation direction

- Public reactions and likes are allowed on **عندك؟** advertisements to express interest and help eligible listings gain visibility.
- Reaction-based ranking must include anti-abuse controls: one reaction per user per listing, no self-boosting, rate limits, suspicious-account detection, recency, quality, and report penalties.
- Organic reactions are separate from paid sponsored placement. A sponsored listing must remain clearly labeled.
- Private messaging is not included in the initial release.
- Public replies may be supported under reviews, but a reply is not a new star rating. Users who want to rate a provider must submit their own separate review. Replies and reviews are moderated and reportable.
- Each user has a public profile page with their published reviews and approved contributions. Phone number and private account data remain hidden.
- Reputation points are awarded for approved, useful contributions rather than every raw submission. Reviews may earn points after moderation, with caps and anti-spam checks.
- Future rewards, recognition, and access levels can be tied to reputation points through administration controls.

### Approved initial reputation labels

The initial public reputation levels use the local term **قناوي**:

- **قناوي**: 0–49 points.
- **قناوي رايق**: 50–99 points.
- **قناوي أصيل**: 100–499 points.

Higher levels may be added later without changing the initial labels. Point thresholds and rewards remain administration-configurable.

### Approved interaction-control style

Community actions should use modern compact controls that combine a consistent outline icon with a short Arabic label. Labels remain visible for clarity and accessibility, especially for older users. Active states use brand teal or a restrained gold accent; icons must come from one consistent line-icon system rather than mixed emoji or unrelated symbols.

Examples include **مهتم**, **حفظ**, **مشاركة**, **مفيد**, **رد**, **تم التأكيد**, **غير صحيح**, and **إبلاغ** according to the content type.

### Approved public-profile visibility

By default, a user's public profile groups approved public contributions into clear sections:

- Reviews.
- Price contributions.
- Local alerts.
- Classified advertisements.
- Other approved contributions added later.

The user may switch the profile to **خاص**. A private profile hides the profile page, points, and contribution lists from public browsing. Content that has already been published in a provider, price, alert, or advertisement context remains governed by that content's integrity and moderation rules, and the user's name remains visible beside that published contribution. Tapping the name opens a private-profile notice rather than the user's contribution history. Platform administration retains the real account identity and audit history.

### Approved notification behavior

- Notifications are enabled by default after setup.
- Users can control notifications from Settings globally or by category.
- Location-sensitive notifications can target all saved areas or only the active/default area, according to the user's choice.
- A daily or periodic summary is optional and controlled from Settings.
- The notification center supports **تحديد الكل كمقروء**.
- Removing a notification from the active list does not destroy its text record; it remains available in the account notification history unless a later privacy/deletion policy removes it.
- Engagement notifications should be aggregated where possible, such as reporting a total number of interests on an advertisement rather than sending one push per interaction.

### Approved initial settings direction

- Version 1 launches in Arabic with the architecture prepared for English later.
- Light mode is the initial default.
- Dark mode is a later enhancement after the base identity is stable.
- Account security includes password change, phone verification state, optional email verification state, and recovery options.
- Account deletion requires an explicit confirmation and a short recovery window before final deletion.

### Approved refresh interaction

Pull-to-refresh is supported on content screens with changing lists or feeds, including the home feed, **مين؟** results, **بكام؟**, **دلوقتي**, **عندك؟**, and notifications. The refresh indicator should use the brand teal with a restrained gold completion accent. Detail, form, and settings screens do not need pull-to-refresh unless they contain a live list. Cached content and a clear offline/error state should remain available when a refresh cannot reach the server.

### Brand promise

**Arabic:** كل ما تحتاجه.. قريب منك  
Alternative approved strategic line: **قنا كلها هنا**

### Core brand personality

- Local.
- Trustworthy.
- Simple.
- Friendly.
- Modern.
- Useful.
- Community-driven.
- Suitable for different ages and genders.
- Not visually governmental.
- Not visually similar to food-delivery apps.

---

## 2. Target Market

### Initial geography

Start in **Qena City**, then expand gradually to:

1. Nag Hammadi.
2. Qus.
3. Dishna.
4. Other cities and centers in Qena Governorate.

Do not launch the entire governorate with empty data.

A new city should not be launched until the current city has:

- Useful coverage.
- Updated records.
- Active users.
- Community contributions.
- An operations team capable of reviewing submissions.

### Target audience

Broad local audience:

- Male and female.
- Approximate age range: 10–65.
- Students.
- Families.
- Employees.
- Business owners.
- Service providers.
- Older users who prefer simple interfaces.

The app must work for users with limited technical confidence.

### Initial neighborhood coverage

The first Qena City dataset should aim to cover the city broadly, including Downtown Qena, Madinet Al-Ommaal, Al-Sho'oun, Al-Masaken, Nagaa Saeed, Al-Maana, Al-Hamidat, Al-Ahwal, the Omar Effendi area, and Al-Mansheya.

Area names, spelling, boundaries, and duplicates must be validated locally before they are used as production seed data.

The area selector should include a non-selectable **تحديثات قادمة** indicator for future coverage. Users may select **قنا كلها** when they do not want to narrow to a neighborhood.

---

## 3. Strategic Product Decision

The product should evolve into a local super-app gradually, but the first release must stay focused.

### Approved MVP modules

#### 1. مين؟
A trusted and interactive local services directory.

Approved interface line: **مين شاطر في اللي محتاجه؟**

Users can:

- Search service providers.
- Filter by location and category.
- View contact details.
- View working hours.
- View verification status.
- Read ratings and reviews.
- Suggest edits.
- Report incorrect data.
- Add a missing provider.

#### 2. بكام؟
Local prices and offers.

Approved interface line: **اعرف الأسعار وقارنها في قنا**

Users and admins can:

- Add a product or service price.
- Attach optional proof.
- Confirm whether a price is still valid.
- View the last update date.
- Compare prices by area or provider.
- Report outdated or false prices.

#### 3. دلوقتي
Local alerts and community information.

Approved interface line: **اعرف إيه اللي بيحصل حواليك دلوقتي**

Examples:

- Road closure.
- Traffic or accident.
- Water or electricity interruption.
- Service outage.
- Local event.
- Important community notice.
- Missing item.
- Public-service update.

The app must clearly state that community alerts are not an official government reporting channel unless an official partnership is established.

#### 4. عندك؟
A moderated local-classifieds section for people in Qena.

Approved positioning line:

> اعرض اللي عندك، ودوّر على اللي محتاجه

The section may include:

- Products and used items.
- Cars and motorcycles.
- Property for sale or rent.
- Jobs and opportunities.

Version 1 does not include wanted/request listings. Permanent professional services remain in **مين؟**, not in **عندك؟**.

User listings must be reviewed by administration before publication. The initial release must not include in-app payments, delivery management, commissions, or in-app chat. The section name is **عندك؟**, including the question mark in brand presentation where visually appropriate.

Published advertisements remain visible for seven days. After seven days they are removed from public listings and archived under the user's account. The owner receives a notification that the advertisement ended and may request **إعادة نشر**. Re-publishing creates a new review cycle and a fresh publication date so the public feed remains current.

Initial contact options for an advertisement are phone call and WhatsApp. Other contact channels can be added later if approved.

Advertisement quality requirements:

- A valid price is mandatory for every published advertisement in Version 1.
- Placeholder or misleading prices, such as `1`, `0`, or an obviously incomplete amount, must be rejected unless a later category-specific rule explicitly permits them.
- At least one clear, real image of the advertised item/property is mandatory.
- The maximum number of images is five per advertisement.
- Images should be compressed, checked for basic quality, and associated with the advertisement lifecycle.
- A negotiable-price option may be supported, but it does not replace entering a meaningful amount.

Administration rejection must use a clear reason and notify the submitter. Initial structured reasons include:

- Missing or invalid price.
- Insufficient or unclear real images.
- Misleading or incomplete information.
- Wrong category or location.
- Prohibited or unsafe content.
- Duplicate advertisement.

When an advertisement expires, the owner receives a renewal notification. Choosing **لا أريد التجديد** deletes the advertisement and its images from the active system. If the owner does not respond within three days, the advertisement and associated media are automatically deleted. The implementation must still respect backup retention and audit requirements that may apply to the platform infrastructure.

### Approved عندك؟ submission flow

The add-ad experience should be a short three-step flow:

1. Choose the advertisement type and enter the title/basic information.
2. Add one to five real images, enter the required amount, select the area, and provide the description.
3. Choose phone/WhatsApp contact, review the preview, and submit for administration review.

After submission, the owner sees a pending state and receives a notification when the advertisement is approved or rejected. Rejection notifications must show the reason and provide **تعديل وإعادة إرسال** where the listing can be corrected. A final deletion or no-response expiry action must use a clear confirmation message because it cannot be restored through the user interface.

### Future modules

Add only after the MVP is working:

- متاح الآن
- فزعة قنا
- فعاليات
- مواصلات
- ازدحام / دوري
- Bookings
- Coupons
- Business dashboards
- Ticketing

---

## 4. Why This Product Can Win

The opportunity is not just a directory.

The main competitive advantage should be:

1. Local coverage.
2. Updated information.
3. Visible trust and verification.
4. Community contributions.
5. Admin review.
6. A reason to return daily.
7. Easy sharing through WhatsApp and social media.
8. Simple Arabic UX.
9. Strong data operations.
10. Gradual city-by-city expansion.

The project should optimize for:

> Trust first, usage second, revenue third.

---

## 5. Approved Brand Identity

### Logo direction

Approved icon concept:

- A rounded-square app icon.
- Dark teal background.
- White symbol combining:
  - A location pin.
  - The Latin letter Q.
  - A visual reference to Arabic ق.
- A gold circular point inside the symbol.

The icon should remain recognizable at small sizes.

### Primary logo

Arabic wordmark:

**هنا قنا**

The location/Q symbol can appear beside the Arabic wordmark.

### English form

**HENA QENA**

The visual similarity between `HENA` and `QENA` is a key brand idea.

### Approved colors

- Light teal: `#0D8F8A`
- Dark teal: `#085E5A`
- Gold: `#E9B44C`
- Off-white: `#F7F6F2`
- Charcoal: `#1F2933`

### Suggested typography

- Arabic UI: Tajawal
- Arabic headings / brand: Cairo
- English: Cairo or a clean geometric sans-serif

### Icon style

- Rounded outline icons.
- Consistent stroke width.
- Teal as the main stroke color.
- Small gold accents only.
- Simple enough for older users.

### Visual tone

- Clean.
- Rounded.
- Friendly.
- Local but not folkloric.
- Real images from Qena whenever possible.
- Avoid generic stock photos that look like Cairo or Gulf cities.

### Approved seasonal visual direction

The application keeps the simple, calm Version 1 visual foundation as its permanent base, while using the more expressive Version 2 header as a controlled seasonal layer.

Seasonal themes may be used for:

- Qena National Day and local Qena occasions.
- Ramadan and Eid al-Fitr.
- Eid al-Adha.
- Sham El-Nessim and other widely recognized public holidays.
- Approved local celebrations and community occasions.

Seasonal changes should be subtle and temporary, such as:

- A themed hero/header treatment.
- Small decorative motifs or illustrations.
- A limited accent variation within the approved brand palette.
- A short greeting or relevant local message.

The permanent logo, core navigation, readability, and accessibility must remain stable. Seasonal themes must have start and end dates, a fallback base theme, and administration controls for activation, preview, and removal. The seasonal layer should never turn the app into a cluttered festival interface or make important content harder to read.

---

## 6. Product Language and UX Writing

The interface should use simple Egyptian Arabic.

Examples:

Instead of:

> قم بتحديد الموقع الجغرافي للاستمرار

Use:

> حدد منطقتك علشان نعرض لك الأقرب

Instead of:

> لم يتم العثور على نتائج

Use:

> لسه مفيش نتائج هنا، جرّب قسم تاني أو ضيف الخدمة بنفسك

Instead of:

> إرسال بلاغ

Use:

> بلّغنا عن المشكلة

The tone must be:

- Friendly.
- Respectful.
- Clear.
- Not overly slang-heavy.
- Easy for older users.

### Approved primary navigation labels

The five bottom-navigation destinations use short, single-word Arabic labels:

1. الرئيسية
2. مين؟
3. بكام؟
4. دلوقتي
5. عندك؟

In RTL presentation, **الرئيسية** should begin at the right-hand side. Each module screen must include a short explanatory line so the compact label never causes ambiguity.

---

## 7. Data Is the Core Product

The application depends heavily on data quality.

The system must treat every record as having a lifecycle, source, owner, review state, and expiration policy.

### Minimum provider record

A provider record may include:

- Business/provider name.
- Short name.
- Primary category.
- Subcategories.
- Description.
- Governorate.
- City/center.
- Area.
- Full address.
- Landmark description.
- Latitude.
- Longitude.
- Phone.
- WhatsApp.
- Social links.
- Working hours.
- Service area.
- Home-service availability.
- Price level.
- Payment methods.
- Images.
- Verification level.
- Source.
- Last verified date.
- Verified by.
- Record status.
- Owner claim status.
- Average rating.
- Review count.
- Complaint count.
- Data completeness score.

### Record lifecycle

Recommended states:

1. Collected
2. Needs Review
3. Contact Attempted
4. Verified
5. Published
6. Needs Update
7. Reported
8. Temporarily Suspended
9. Closed
10. Archived

### Verification levels

Recommended levels:

- Unverified
- Community confirmed
- Phone verified
- Owner claimed
- Field verified
- Partner verified

Verification must be visible to users.

### Data freshness

Every important field should have a review policy.

Examples:

- Working hours: review every 60–90 days.
- Phone numbers: review every 90 days.
- Local prices: expire after a short configurable period.
- Offers: expire automatically.
- Temporary alerts: expire automatically.
- Business closure reports: require review.

### Data source tracking

Every record should store its source:

- Admin entry.
- Public business page.
- User contribution.
- Business owner.
- Phone verification.
- Field verification.
- Partner feed.
- Imported file.

Never copy third-party reviews and present them as Hena Qena user reviews.

---

## 8. Community Contributions

Users should be able to:

- Add a provider.
- Suggest an edit.
- Add a price.
- Confirm a price.
- Confirm whether a business is open.
- Add a photo.
- Add a review.
- Report incorrect information.
- Add a local alert.
- Confirm or reject an alert.

### Contributor reputation

The platform should not trust all contributions equally.

Possible reputation factors:

- Number of accepted edits.
- Rejected edits.
- Verified phone.
- Account age.
- Contribution accuracy.
- Reports against the user.
- Moderator trust.
- Geographic relevance.

Possible badges:

- مساهم جديد
- مساهم موثوق
- خبير منطقتك
- مصحح بيانات
- مراسل محلي

The first release can use a simple point system, then evolve later.

---

## 9. Reviews and Trust

Do not rank providers using star averages only.

Possible ranking factors:

- Verified reviews.
- Number of real customers.
- Response speed.
- Updated profile.
- Completed data.
- Complaint resolution.
- Working-hours accuracy.
- Recency.
- Verification level.
- Distance.
- Sponsored placement, clearly labeled.

Paid placement must never look like an organic recommendation.

### Review moderation

A review should support:

- Rating.
- Written text.
- Optional photos.
- Visit/service date.
- Moderation status.
- Abuse report.
- Provider reply.
- Reviewer trust score.

### Approved provider-detail review experience

The provider-detail page should place service information first, followed by a clear **قيّم الخدمة** action, then the rating summary and existing reviews. A compact bottom action may remain available while the user scrolls.

The initial review form should include:

- Multi-dimensional star ratings.
- An optional written comment.
- Optional visit/service date.
- Optional photo where appropriate.
- Clear moderation and abuse-reporting status.

The default universal rating dimensions are:

- Quality.
- Commitment.
- Value for money.

Category-specific dimensions may be added later, while dimensions that do not apply to a category should be hidden or marked not applicable. The overall score must show the dimension breakdown and should not rely on one star average alone. Adding a review requires a signed-in account.

---

## 10. Admin and Operations

The initial team can be:

- 1 person at first.
- Up to 3 people in the early stage.
- Later, a dedicated department inside MaalSoft.

### Suggested three-person operation

#### Person 1 — Data collection
- Finds providers.
- Adds initial data.
- Uploads public details.
- Marks the source.

#### Person 2 — Verification and moderation
- Calls providers.
- Reviews user submissions.
- Verifies edits.
- Handles duplicates.
- Handles reports.

#### Person 3 — Product and development
- Builds the app.
- Reviews analytics.
- Improves workflows.
- Manages releases.
- Designs automation.

### Admin dashboard requirements

The admin panel should include:

- Overview dashboard.
- Pending provider review.
- Pending edits.
- Old vs new value comparison.
- Duplicate detection.
- User review moderation.
- Alert moderation.
- Price moderation.
- Category management.
- City and area management.
- Verification queue.
- Expired data queue.
- Notification composer.
- Team task assignment.
- Employee activity log.
- Audit trail.
- Data quality reports.
- Import/export tools.
- Business account management.
- Owner claim requests.
- Abuse and ban management.

---

## 11. Seed Data Strategy

Do not launch an empty product.

Recommended initial Qena City seed target:

- A minimum launch target of 500 useful provider records, growing toward 800 as operations allow.
- 25–40 useful categories.
- Strong coverage of major neighborhoods.
- A meaningful number of verified providers.
- Prices and offers ready for initial use.
- Community alerts and examples.
- Content ready for the first month.

### Priority categories

High priority:

- Pharmacies.
- Doctors.
- Labs.
- Hospitals and clinics.
- Technicians.
- Maintenance.
- Restaurants.
- Supermarkets.
- Emergency services.
- Transportation information.
- Education and tutors.

Medium priority:

- Photography.
- Events.
- Lawyers.
- Accountants.
- Furniture.
- Electronics.
- Clothing.
- Home services.

Low priority:

- Rare or seasonal categories.

Do not expose a category if it has only a few weak records.

The administration system may contain additional categories before launch, but the mobile app should show only categories with useful and sufficiently verified coverage.

---

## 12. Recommended Technical Architecture

### Mobile app

**Flutter**

Reasons:

- One primary codebase for Android and iOS.
- Good Arabic and RTL support.
- Strong UI performance.
- Suitable for location, camera, push notifications, and maps.

### Backend

Recommended:

- Node.js
- TypeScript
- NestJS or a well-structured Next.js API
- PostgreSQL
- Prisma ORM
- Redis later if needed
- Object storage for images
- Firebase Cloud Messaging
- Apple Push Notification support through Firebase or direct integration

### Admin dashboard

Recommended:

- Next.js
- TypeScript
- Tailwind CSS
- Component system
- Role-based permissions
- Audit logs

### Infrastructure

Parent domain:

`maalsoft.com`

Suggested subdomains:

- `henaqena.maalsoft.com`
- `api.henaqena.maalsoft.com`
- `admin.henaqena.maalsoft.com`

Alternative shorter structure:

- `qena.maalsoft.com`
- `api.qena.maalsoft.com`
- `admin.qena.maalsoft.com`

Approved current public-platform direction:

- Use `henaqena.maalsoft.com` as the main Hena Qena subdomain.
- Keep dedicated API and administration subdomains available when the deployment architecture requires them.

Keep Hena Qena isolated from the accounting platform:

- Separate database.
- Separate Linux user.
- Separate environment variables.
- Separate process/container.
- Separate backups.
- Separate secrets.
- Separate logs.

### Development environment

Primary machine:

- MacBook Air 13-inch
- Apple M4
- 16 GB RAM
- macOS Tahoe 26.4 or newer

Required tools:

- Xcode
- iOS Simulator
- Android Studio
- Android SDK
- Android Emulator
- Flutter SDK
- Dart SDK
- VS Code
- Git
- GitHub
- Node.js LTS
- pnpm
- CocoaPods
- Docker Desktop
- PostgreSQL
- API testing tool

Xcode is required for iOS build/signing.
Android SDK is required for Android build.
Flutter does not replace platform SDKs.

---

## 13. Repository Structure

A monorepo is recommended for the first phase.

Suggested structure:

```text
hena-qena/
├── apps/
│   ├── mobile/
│   ├── admin/
│   └── api/
├── packages/
│   ├── shared-types/
│   ├── validation/
│   ├── design-tokens/
│   └── config/
├── database/
│   ├── prisma/
│   ├── seeds/
│   └── imports/
├── docs/
├── scripts/
├── infrastructure/
├── .github/
├── PROJECT_MEMORY.md
└── README.md
```

Suggested repository name:

`hena-qena`

### Branch strategy

- `main`: stable production-ready code
- `develop`: integration branch
- feature branches:
  - `feature/mobile-auth`
  - `feature/provider-directory`
  - `feature/admin-review`
  - etc.

Do not keep important work only as uncommitted local changes.

Commit frequently.

---

## 14. Initial Database Entities

Suggested first entities:

- User
- UserProfile
- Role
- Permission
- City
- Area
- Category
- Subcategory
- Provider
- ProviderBranch
- ProviderContact
- ProviderHours
- ProviderImage
- ProviderVerification
- ProviderClaim
- ProviderService
- ProviderPaymentMethod
- Review
- ReviewReply
- Contribution
- EditSuggestion
- Report
- PriceItem
- PriceEntry
- PriceConfirmation
- Offer
- LocalAlert
- AlertConfirmation
- Notification
- Favorite
- SearchLog
- AuditLog
- StaffTask
- ImportBatch
- MediaAsset

Use soft deletion where appropriate.

All important data changes should be auditable.

---

## 15. Search Requirements

Search is a major product feature.

It should support:

- Arabic.
- Common spelling differences.
- Local slang.
- Alternate category names.
- Provider name.
- Service name.
- Area.
- Landmark.
- Phone number.
- Tags.

Examples:

- نقاش
- دهانات
- صنايعي دهانات

These should map to related results.

Store normalized Arabic forms for search.

Possible normalization:

- Remove diacritics.
- Normalize Alef variants.
- Normalize Ya and Alef Maqsura.
- Normalize Ta Marbuta only carefully.
- Remove repeated spaces.
- Support Arabic and English numbers.
- Normalize Egyptian phone numbers.

---

## 16. Mobile MVP Screens

Recommended initial screens:

1. Splash
2. Onboarding
3. Select city/area
4. Login / registration
5. Home
6. Search
7. Categories
8. Provider list
9. Provider details
10. Ratings and reviews
11. Add provider
12. Suggest edit
13. Report incorrect data
14. Prices list
15. Add price
16. Confirm price
17. Qena Now feed
18. Add alert
19. Alert details
20. Notifications
21. Favorites
22. Profile
23. Contribution history
24. Settings
25. Privacy and account deletion

### Approved first-run experience

- Splash uses the animated Hena Qena logo, then falls back to the static logo when the animation is unavailable.
- The app has one welcome screen rather than a multi-page onboarding flow.
- The welcome screen includes a friendly greeting and the actions: create account, sign in, and continue as a guest.
- After the welcome screen, the lightweight setup sequence is ordered as: selected area, age and gender preferences, interests, then account creation/sign-in or continue as a guest.
- The setup should use a simple progress indicator and keep each step short.
- The area, age/gender, and interests steps should each offer a skip option where appropriate.
- Authentication is deliberately offered at the end of setup so the user can understand the app and personalize it before deciding to create an account.
- Users may select more than one area because they may regularly move between home, work, and other places.
- Users may save up to three areas.
- One selected area is marked as the active area for current recommendations, with quick switching available later from the home header and account settings.
- Users may optionally label saved areas, such as home or work, without exposing those labels publicly.
- The user can explicitly choose which saved area is the default active area; the first selected area may be suggested as the initial default.
- The app should offer the GPS option again on the area-selection step, even after the welcome flow, so the user can choose automatic detection there.
- Phone verification uses a WhatsApp message as the primary verification channel, with SMS as a fallback if delivery fails. The user does not need to receive both codes.
- Email remains optional. If provided, it receives a separate confirmation link or code and is useful for account recovery, but phone verification is sufficient to activate the account.
- Users may select interests freely up to a maximum of five.
- The onboarding shows progress such as **1 من 4**.
- Skipping remains clearly available on every optional setup step.
- The welcome visual uses the animated logo only, without an additional illustration.
- There is no final onboarding review/edit screen; choices can be changed later from account settings.
- Area selection is primarily manual.
- Current location through GPS is optional and requires explicit user permission.
- If the user skips area selection, the app treats the selected scope as Qena City as a whole.
- Search is the most prominent action on the home screen.
- The home hero/header can change for time, season, holidays, and approved local occasions while the underlying navigation and brand system remain stable.
- The first-run welcome flow may optionally collect interests, age range, and gender preference to personalize the six quick categories shown on the home screen and improve recommendations.
- The collection step must include a clear note that these answers are optional and are used to improve in-app recommendations.
- Users must be able to skip the personalization step and continue with the standard, non-personalized home presentation.
- Age should be collected as a range rather than an exact birth date unless a later approved feature genuinely requires more precision.
- Gender should include a clear **أفضل عدم الإفصاح** option and must not be exposed publicly or used to unfairly limit ordinary services.
- Personalization answers must be editable and removable from account settings, and must not be sold or displayed to advertisers.
- The six quick categories should be selected from the user's interests when available. If interests are skipped, show a stable default set based on useful Qena coverage.
- Location recommendations use the manually selected area as the primary scope. Optional GPS may refine results to the user's current position only after permission.
- If the selected area is not yet covered or the user skips area selection, show Qena-wide results using the normal ranking order and clearly communicate the broader scope.
- Map and list ordering should prioritize proximity within the selected scope, then verification, freshness, completeness, and organic relevance.
- The **مين؟** landing screen shows the six personalized or default categories first, followed by the section search field.
- The six categories use the user's selected interests when available; otherwise they use a stable default set.
- The default welcome tone should be Egyptian Arabic and friendly, with the working direction **أهلًا بيك.. قنا كلها هنا**.
- The visual direction for the welcome screen is a balanced midpoint between the calm Version 1 and the more energetic Version 2.
- The default home hero copy starts from **كل ما تحتاجه.. قريب منك** and may be changed by administration for approved occasions.
- The home screen should not duplicate the four primary sections as large cards because they are already present in the bottom navigation.
- After the dominant search field, the home screen uses a dynamic administration-controlled content slot.
- Dynamic home content may include an important local notice, a seasonal/editorial feature, a clearly labeled sponsored placement, or a featured service.
- If a higher-priority slot is empty, the next eligible slot appears automatically, followed by direct service/category content.
- Sponsored content must be clearly labeled, limited in frequency, and never displace an urgent public-interest notice or compromise organic trust.
- A global search can route users to the most relevant module: **مين؟**, **بكام؟**, **دلوقتي**, or **عندك؟**.

### Approved home-administration advertising direction

The administration platform must include a dedicated **Homepage Advertisements** area. Each advertisement may store:

- Internal system name.
- Public advertiser/place name.
- Image.
- Short title.
- Description shown below or beside the image according to the approved card layout.
- Optional call-to-action and contact destination.
- Start date and end date.
- Target scope: all Qena City or selected areas.
- Active, paused, scheduled, expired, and archived states.
- Impression and click counters for later reporting.

Administrators can choose one of two delivery modes:

1. **Manual order:** administrators set first, second, third, and so on.
2. **Weighted distribution:** administrators assign percentage rates to active ads. The system validates that the total equals 100%, calculates the remaining amount while editing, and prevents publishing when the final total is invalid.

Weighted rates represent an approximate share over many eligible impressions, not a guarantee that every short sequence will match the percentages exactly. The system should record the selected advertisement per impression so delivery can be audited.

Additional controls:

- Rotation interval configured at the campaign or placement level.
- Display duration is configurable from the administration platform rather than fixed in the app. It may be set per advertisement, with an optional placement-level default.
- One visible ad card at a time on the home screen.
- Automatic transition follows the configured display duration, with manual swipe/next interaction always available.
- Area targeting takes precedence over generic city-wide ads when both are eligible.
- Urgent public-interest notices must be able to override sponsored content.
- Sponsored cards must be visibly labeled as **إعلان**.

Each advertisement has a configurable destination type. Supported destination types include:

- Internal provider or business page.
- Internal advertisement detail page.
- Phone call.
- WhatsApp conversation.
- Map or location page.
- Validated external HTTPS link.
- Social or media link such as Facebook, TikTok, YouTube, or a video page.

The administration form must show only the fields relevant to the selected destination, validate the destination before publishing, provide a preview/test action, and safely open external links without accepting arbitrary unsupported URL schemes.

### Animated logo delivery direction

The preferred delivery format for the splash logo animation is a vector Lottie JSON exported from After Effects/Bodymovin or a compatible motion tool. A Rive `.riv` file is an alternative when the animation needs interactive state control. GIF, MP4, and MOV are not preferred for the app splash because of size, quality, and playback-control limitations.

Animation handoff requirements:

- Transparent background.
- 1–2 seconds.
- Plays once, then resolves to the static logo.
- No embedded text that needs localization.
- No unsupported raster effects where possible.
- Keep the file lightweight and test it on iPhone and Android.

Do not make registration mandatory for basic browsing.

Require login only for contributions, reviews, favorites, and account-specific actions.

### Approved account and public-identity direction

- Guest browsing must be available without registration.
- Registration should be lightweight.
- Phone number and password are supported as the basic account direction.
- Email can be optional, with a clear explanation that it can help with account recovery.
- Google sign-in and Sign in with Apple should be supported when practical and compliant with store requirements.
- Account registration collects the user's real name and supports Arabic and English names.
- The default public-name policy should use the registered name; any later public alias or privacy option must be explicitly designed and approved separately.
- Public anonymity must not make the account anonymous to platform administration.
- Moderators must retain access to account identity, verification state, contribution history, and abuse history.
- Egyptian phone numbers are the initial default, with the country code prefilled as `+20`.
- Standard accounts use a password; Google and Apple sign-in do not require a separate password.
- Account recovery uses WhatsApp first, with the verified email as a secondary option when one exists.
- Profile photo is optional; users may use initials or a default avatar.
- The verified phone number is visible inside the user's private account page but is never public by default.
- Favorites appear near the top of the account page.
- Notification preferences are grouped inside the general Settings area rather than shown as a separate primary account section.

---

## 17. First Release Non-Goals

Do not build these in the first release:

- Delivery management.
- Driver management.
- Ride bookings.
- Wallets.
- Payments.
- Complex subscriptions.
- In-app chat.
- Live tracking.
- Marketplace checkout.
- Microservices.
- Kubernetes.
- Advanced AI features.
- Nationwide expansion.
- Full governorate launch.
- Heavy business analytics.

---

## 18. Monetization Plan

### Phase 1: 0–6 months

- Free app.
- No commissions.
- No payment dependency.
- No intrusive ads.
- Focus on data and trust.

Professional business pages, sponsored visibility, richer service packages, and expanded contact options should be supported by future architecture but are not required for the initial public release.

Sponsored placement must be clearly labeled and must not affect the integrity of organic rankings.

### Phase 2: 6–12 months

Possible revenue:

- Verified business profiles.
- Sponsored placement.
- Clearly labeled local ads.
- Sponsored offers.
- Category sponsorship.
- Business dashboard subscription.
- Basic analytics for businesses.

### Later

- Booking.
- Tickets.
- Coupons.
- Premium business accounts.
- Lead generation.
- Partner services.
- Payments through licensed providers only.

---

## 19. Privacy and Legal Principles

The project should:

- Collect minimum necessary data.
- Request location only when useful.
- Explain why location is requested.
- Allow account deletion.
- Protect phone numbers.
- Store passwords securely.
- Use role-based access.
- Keep audit logs.
- Avoid exposing private personal data.
- Moderate medical content.
- State that health information is informational, not medical advice.
- State that community alerts are not official government reports.
- Handle commercial revenue through MaalSoft correctly when monetization starts.

---

## 20. Product Metrics

Track:

- Downloads.
- Monthly active users.
- Daily active users.
- Retention.
- Searches.
- Searches with no result.
- Provider profile views.
- Calls and WhatsApp clicks.
- Contributions.
- Contribution approval rate.
- Review count.
- Report count.
- Data freshness.
- Duplicate rate.
- Category coverage.
- Area coverage.
- Alert confirmation rate.
- Price confirmation rate.
- Business claims.
- Notification open rate.

Most important early metrics:

1. Users returning.
2. Searches finding useful results.
3. Data accuracy.
4. Community contribution quality.
5. Coverage in Qena City.

### Approved price aggregation direction

Community-reported prices must not rely on a simple arithmetic average alone.

Where sufficient reports exist, show:

- A typical or median price.
- A price range.
- The number of reports.
- The last update date.
- A confidence indicator.

The system should detect or exclude suspicious outliers. Product prices are the main initial comparison use case. Service prices may be collected as optional user-reported experience data, but should not be presented as fixed or guaranteed prices. Structured service packages can be added later for professional business pages.

### Approved بكام؟ structure

The **بكام؟** section contains two internal tabs:

1. **العروض** — shown first to create an immediate reason to explore.
2. **الأسعار** — products and local service-price information.

The section supports both products and services. Product prices may show a typical price, range, unit, provider/area, freshness, and confidence. Service prices must be presented as reported ranges or experience-based estimates, with clear wording that the amount is not guaranteed and may vary by provider, scope, urgency, or materials.

The service-price model should support:

- Service name and category.
- Optional provider or area.
- Reported amount or range.
- What the price included.
- Date of service or report.
- Optional proof or note.
- Freshness and confidence state.

Offers may be submitted by:

- Hena Qena administration.
- Business/activity owners.
- Community users.

All offer submissions require administration review before publication. Published cards should identify the source using clear states such as **من الإدارة**, **من نشاط موثق**, or **مساهمة مستخدم**. Owner and user submissions must retain the submitter, review state, timestamps, edit history, and report history for audit and moderation.

### Approved دلوقتي content direction

The **دلوقتي** section is a time-sensitive, moderated local feed rather than a traditional news section. It may include:

- Local service interruptions.
- Road closures, traffic, and accidents affecting movement.
- Events and nearby activities.
- Missing and found items.
- Community help requests and urgent local notices.
- Important public-service updates.

Each item should show its publication time, affected area, source, verification state, and active/ended status. Every user-submitted item requires administration review before publication; trusted administration or approved partners may publish directly under the platform's audit rules. Items should expire automatically according to their type and support confirmation, correction, and report actions.

The default دلوقتي categories are **خدمات ومرافق**, **طرق ومواصلات**, **فعاليات**, **مفقودات وموجودات**, **مساعدة مجتمعية**, and **تنبيهات عامة**. Active items are ordered by relevance to the active area, verification, and recency.

---

## 21. Twelve-Month Direction

### Month 1
- Research.
- Surveys.
- Provider interviews.
- Brand validation.
- Data schema.
- Seed-data planning.

### Months 2–3
- Build MVP.
- Build admin dashboard.
- Prepare initial data.
- Closed beta.

### Month 4
- Qena City beta launch.

### Month 5
- Improve data quality and verification.

### Month 6
- Evaluate retention, data quality, and product-market fit.

### Month 7
- Expand to Nag Hammadi if Qena City is healthy.

### Month 8
- Add “متاح الآن”.

### Month 9
- Add events and opportunities.

### Month 10
- Test simple monetization.

### Month 11
- Expand to Qus and Dishna if operations can support it.

### Month 12
- Annual review and year-two plan.

### Approved development and release approach

- Development and hands-on testing start with iPhone/iOS because the primary development machine and test phone are Apple devices.
- Android testing follows using a real Android test device.
- The public launch target includes both iOS and Android.
- There is no fixed launch date.
- Release happens only after agreed quality, security, stability, data-readiness, and store-readiness checks pass.
- The intended outcome is a real public product, not only a prototype.

---

## 22. Immediate Coding Plan

### Phase A — Foundation

1. Create GitHub repository.
2. Create monorepo structure.
3. Add `PROJECT_MEMORY.md`.
4. Add `README.md`.
5. Add `.editorconfig`.
6. Add linting and formatting.
7. Add environment templates.
8. Add Docker Compose.
9. Add PostgreSQL.
10. Add Prisma.
11. Create initial schema.
12. Create seed scripts.
13. Add CI checks.

### Phase B — Backend

1. Authentication.
2. User roles.
3. Cities and areas.
4. Categories.
5. Providers.
6. Provider branches.
7. Provider contacts.
8. Provider hours.
9. Verification.
10. Reviews.
11. Reports.
12. Contributions.
13. Prices.
14. Alerts.
15. Audit logs.
16. Admin APIs.

### Phase C — Admin Dashboard

1. Login.
2. Roles and permissions.
3. Provider review queue.
4. Duplicate review.
5. Edit suggestions.
6. Price review.
7. Alert review.
8. Review moderation.
9. Verification.
10. Import/export.
11. Analytics.

### Phase D — Flutter App

1. Theme and design tokens.
2. Arabic and RTL.
3. App navigation.
4. Location selection.
5. Home.
6. Categories.
7. Search.
8. Provider list.
9. Provider details.
10. Reviews.
11. Contributions.
12. Prices.
13. Alerts.
14. Notifications.
15. Profile.
16. Error and empty states.

---

## 23. First Technical Tasks for Codex / Claude

Use this order.

### Task 1 — Repository bootstrap

Create the monorepo with:

- Flutter app in `apps/mobile`
- Next.js admin in `apps/admin`
- NestJS API in `apps/api`
- Shared TypeScript packages
- Docker Compose
- PostgreSQL
- Prisma
- pnpm workspace
- ESLint
- Prettier
- GitHub Actions

### Task 2 — Initial data model

Implement the first Prisma schema for:

- User
- Role
- City
- Area
- Category
- Provider
- ProviderBranch
- ProviderContact
- ProviderHours
- ProviderVerification
- Review
- Contribution
- Report
- AuditLog

Do not implement payments.

### Task 3 — Authentication and roles

Implement:

- Email/password or phone/password architecture.
- Secure password hashing.
- Refresh tokens.
- Access tokens.
- Role-based access.
- Admin, moderator, data-entry, business-owner, and user roles.

### Task 4 — Provider directory APIs

Implement:

- Create provider.
- Update provider.
- Review provider.
- Publish provider.
- Search provider.
- Filter by city, area, category, verification, and open status.
- Soft delete.
- Audit log.

### Task 5 — Admin review workflow

Implement the lifecycle:

- Collected
- Needs Review
- Contact Attempted
- Verified
- Published
- Needs Update
- Reported
- Suspended
- Closed
- Archived

Every transition must be logged.

---

## 24. Coding Rules

- Use TypeScript strict mode.
- Use Flutter null safety.
- Keep architecture modular.
- Do not over-engineer.
- Add tests for critical logic.
- Add validation at API boundaries.
- Use database transactions for critical multi-step writes.
- Store timestamps in UTC.
- Display time in local timezone.
- Use immutable audit records.
- Use soft delete for recoverable content.
- Never expose secrets.
- Never commit `.env`.
- Never commit production credentials.
- Keep migrations in Git.
- Keep seed data separate from production data.
- Use pagination.
- Add rate limiting.
- Add input sanitization.
- Add file upload limits.
- Add image compression.
- Add error logging.
- Add health checks.
- Add database backups before production.

---

## 25. Open Decisions

These decisions are not final yet:

1. NestJS vs Next.js API.
2. Exact phone verification, password-recovery, and social-sign-in implementation.
3. Firebase Auth vs custom auth.
4. Google Maps vs another map provider.
5. Object storage provider.
6. Whether to use one repository or multiple repositories.
7. Exact Arabic category tree.
8. Final validated Qena City area list and boundaries.
9. Exact moderation SLA.
10. Exact verification expiration periods.
11. Exact business monetization packages.
12. Final vector logo files.
13. Final Figma design system.

Do not silently decide these without documenting the decision.

---

## 26. Current Approved Decisions Summary

- Project name: **هنا قنا / Hena Qena**
- Parent company: **MaalSoft**
- Initial geography: **Qena City**
- Main product type: local services and community information
- MVP:
  - مين؟
  - بكام؟
  - دلوقتي
  - عندك؟
- Mobile framework: **Flutter**
- Primary database: **PostgreSQL**
- Admin dashboard: **Next.js**
- Backend: **Node.js + TypeScript**
- Community content: allowed with moderation
- Admin-only content: supported
- Basic browsing: available as a guest without forced registration
- Public identity: display names are allowed, while administration retains moderation-level account identity
- Initial provider seed target: at least 500 useful records
- Provider scope: fixed-location businesses and independent service professionals
- Main public subdomain: `henaqena.maalsoft.com`
- Development order: iOS first, then Android testing
- Public release target: iOS and Android together after release-readiness checks
- Location: optional and used only when useful
- Initial team: 1–3 people
- Growth path: dedicated MaalSoft department
- Revenue is not required at launch
- Brand colors approved
- Brand icon direction approved
- Data quality is the primary operational priority

---

## 27. Instruction to Any AI Coding Agent

Before writing code:

1. Read this file fully.
2. Do not expand the MVP without approval.
3. Do not add payment, delivery, or ride-hailing logic.
4. Prefer simple maintainable architecture.
5. Preserve Arabic and RTL requirements.
6. Document every major decision.
7. Update this memory file after approved changes.
8. Create small commits.
9. Never leave critical work only as uncommitted local edits.
10. Ask before making an irreversible architecture choice.

---

## 28. Next Recommended Action

Create the repository and bootstrap the monorepo.

The first implementation milestone should be:

> A working local environment where the API, PostgreSQL, Prisma, admin dashboard, and Flutter app can all start successfully, with one shared seed city: Qena.

After that, implement the provider-directory data model and admin review workflow before building complex mobile UI.

## 29. Approved UI Motion Direction (2026-07-17)

- Keep the interface compact and professional: categories appear in horizontal scroll rails instead of tall grids/wraps.
- Use a restrained motion system: short fade + small shared-axis slide between main tabs; no constant animation on every element.
- Use Hero/container-style transitions later when provider, ad, and review detail screens exist.
- Pull-to-refresh remains available with the brand teal indicator; future loading states should use short skeleton/shimmer motion.
- Respect reduced-motion/accessibility preferences when the production animation layer is added.
- Provider cards now open a first detail prototype using a shared Hero icon and a subtle scale-in; the same pattern will be reused for ads and reviews after their detail screens are implemented.
- Home now uses a compact swipeable promo rail with page indicators; production content will be driven by the admin-controlled ad/notice rotation rules.
- Welcome logo has a short entrance motion, and setup steps use a restrained fade/shared-axis transition keyed by step.
- Home hero now includes ambient in-interface motion: slowly shifting gradient, floating circles, and a subtle logo lift; motion remains low-frequency and non-blocking.
- The `دلوقتي` section now has a subtle pulsing `مباشر` status indicator to communicate live updates.

## 30. Initial Technical Foundation (2026-07-17)

- Brand and image asset slots are prepared under `apps/mobile/assets/brand` and `apps/mobile/assets/images`; final logo files are still pending from the owner.
- Flutter theme/motion primitives live under `apps/mobile/lib/core/theme`, and the first API client lives under `apps/mobile/lib/core/network`.
- PostgreSQL local infrastructure is defined in `infra/docker-compose.yml`.
- Prisma schema covers users, areas, providers, provider images, categories, listings, ads, reviews, replies, and notifications.
- Initial API lives under `apps/api` with health, areas, providers, listings, ads, and review endpoints.
- The production web and admin dashboard live under `apps/web`, use Next.js, authenticated server sessions, and the live API/PostgreSQL data.
- The old static `apps/admin` preview was removed after its functionality was replaced by the authenticated Next.js platform.
- The mobile directory uses API data only and shows a clear retry state when the server is unavailable.

---

## 31. Shared Activity Log (2026-07-18)

- Every implementation step must be recorded in `PROJECT_ACTIVITY_LOG.md` with the executor name (`Codex` or `Claude`), status, and commit hash.
- Before starting parallel work, read the latest log entry and mark the new step as `قيد التنفيذ`.
- After testing, update the same entry to `مكتملة` or `متوقفة` with a clear reason.

## 32. Architecture Correction: Next.js Web Platform (2026-07-18)

- The mobile client remains Flutter for the iOS/Android launch.
- The public/admin web platform must be Next.js + TypeScript to align with MaalSoft's architecture and interaction model.
- The old static `apps/admin` prototype has been retired and removed.
- `apps/web` is the final Next.js app location and reuses the existing PostgreSQL/Prisma model.
- The current Express API may remain as a compatibility layer while web routes are migrated; do not delete it during the migration.

## 33. Page Transition Motion References (2026-07-18)

- When the owner says «موشن جرافيك تنقل الصفحات», use the Pinterest references documented in `docs/MOTION_REFERENCES.md`.
- These are visual references only; implementation must remain original and respect Hena Qena's teal/gold identity.

## 34. Deferred Web Repository (2026-07-18)

- The owner created a separate private GitHub repository for the web platform: `aarheemfrj/henaqenawebapp`.
- Keep this repository as a deferred destination only. Do not change the current repository remote or push/migrate the web platform into it until the owner explicitly requests that action.

---

**Last updated:** 2026-07-18
