-- Align the deployed database with the current Prisma schema.
-- Earlier admin/archive work changed the schema before a migration was
-- recorded. All additions are nullable or have safe defaults so existing
-- rows are preserved. The unique externalId index intentionally fails when
-- duplicate imported IDs exist; those rows must be reviewed before deploy.

ALTER TABLE "Ad"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "Listing"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "NowUpdate"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "PriceGuide"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "Provider"
  ADD COLUMN IF NOT EXISTS "email" TEXT,
  ADD COLUMN IF NOT EXISTS "website" TEXT,
  ADD COLUMN IF NOT EXISTS "facebookUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "instagramUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "tiktokUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "openingHours" JSONB,
  ADD COLUMN IF NOT EXISTS "externalId" TEXT,
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "ProviderOffer"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "ProviderService"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

ALTER TABLE "ReviewReply"
  ADD COLUMN IF NOT EXISTS "archivedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "deletedAt" TIMESTAMP(3),
  ADD COLUMN IF NOT EXISTS "archiveReason" TEXT;

CREATE INDEX IF NOT EXISTS "CollectedBusiness_status_qualityScore_idx"
  ON "CollectedBusiness" ("status", "qualityScore");
CREATE INDEX IF NOT EXISTS "DuplicateCandidate_resolved_score_idx"
  ON "DuplicateCandidate" ("resolved", "score");

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM "Provider"
    WHERE "externalId" IS NOT NULL
    GROUP BY "externalId"
    HAVING COUNT(*) > 1
  ) THEN
    RAISE EXCEPTION 'Provider.externalId contains duplicates; review imported records before applying the unique index';
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS "Provider_externalId_key" ON "Provider" ("externalId");

