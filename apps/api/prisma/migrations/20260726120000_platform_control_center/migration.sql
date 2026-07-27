ALTER TABLE "PlatformSettings"
  ADD COLUMN "maintenanceMode" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "maintenanceMessage" TEXT NOT NULL DEFAULT 'نعود إليكم قريبًا. التطبيق تحت الصيانة المؤقتة.',
  ADD COLUMN "appName" TEXT NOT NULL DEFAULT 'هنا قنا',
  ADD COLUMN "appTagline" TEXT NOT NULL DEFAULT 'كل ما تحتاجه.. قريب منك',
  ADD COLUMN "supportPhone" TEXT,
  ADD COLUMN "supportWhatsapp" TEXT,
  ADD COLUMN "supportEmail" TEXT,
  ADD COLUMN "facebookUrl" TEXT,
  ADD COLUMN "instagramUrl" TEXT,
  ADD COLUMN "homeSections" JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN "enabledModules" JSONB NOT NULL DEFAULT '{}',
  ADD COLUMN "privacyPolicy" TEXT NOT NULL DEFAULT '',
  ADD COLUMN "termsOfUse" TEXT NOT NULL DEFAULT '';

CREATE TABLE "PlatformConstant" (
  "id" TEXT NOT NULL,
  "type" TEXT NOT NULL,
  "name" TEXT NOT NULL,
  "slug" TEXT NOT NULL,
  "isActive" BOOLEAN NOT NULL DEFAULT true,
  "sortOrder" INTEGER NOT NULL DEFAULT 0,
  "metadata" JSONB,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "PlatformConstant_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "PlatformConstant_type_name_key" ON "PlatformConstant"("type", "name");
CREATE UNIQUE INDEX "PlatformConstant_type_slug_key" ON "PlatformConstant"("type", "slug");
CREATE INDEX "PlatformConstant_type_isActive_sortOrder_idx" ON "PlatformConstant"("type", "isActive", "sortOrder");

INSERT INTO "PlatformConstant" ("id", "type", "name", "slug", "sortOrder", "updatedAt") VALUES
  ('seed-listing-sale', 'listing-types', 'للبيع', 'for-sale', 10, CURRENT_TIMESTAMP),
  ('seed-listing-rent', 'listing-types', 'للإيجار', 'for-rent', 20, CURRENT_TIMESTAMP),
  ('seed-listing-jobs', 'listing-types', 'وظائف', 'jobs', 30, CURRENT_TIMESTAMP),
  ('seed-listing-cars', 'listing-types', 'سيارات', 'cars', 40, CURRENT_TIMESTAMP),
  ('seed-listing-property', 'listing-types', 'عقارات', 'property', 50, CURRENT_TIMESTAMP),
  ('seed-news-general', 'news-types', 'عام', 'general', 10, CURRENT_TIMESTAMP),
  ('seed-news-road', 'news-types', 'طرق ومواصلات', 'roads', 20, CURRENT_TIMESTAMP),
  ('seed-news-services', 'news-types', 'خدمات ومرافق', 'services', 30, CURRENT_TIMESTAMP),
  ('seed-news-events', 'news-types', 'فعاليات', 'events', 40, CURRENT_TIMESTAMP),
  ('seed-service-general', 'service-types', 'خدمة عامة', 'general', 10, CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
