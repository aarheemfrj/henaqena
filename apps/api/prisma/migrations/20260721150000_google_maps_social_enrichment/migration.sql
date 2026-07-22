-- Google Maps collection + social links enrichment support.
-- Adds Google Place identity, structured social-link evidence/candidates,
-- and enrichment lifecycle tracking to CollectedBusiness. Does not touch
-- any previous migration.

CREATE TYPE "SocialEnrichmentStatus" AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'SKIPPED');

ALTER TABLE "CollectedBusiness"
  ADD COLUMN "googlePlaceId" TEXT,
  ADD COLUMN "socialEnrichment" JSONB,
  ADD COLUMN "socialCandidates" JSONB,
  ADD COLUMN "socialEnrichmentStatus" "SocialEnrichmentStatus" NOT NULL DEFAULT 'PENDING',
  ADD COLUMN "socialEnrichmentError" TEXT,
  ADD COLUMN "socialEnrichedAt" TIMESTAMP(3);

-- Unique per place (Postgres treats multiple NULLs as distinct, so
-- non-Google-Maps records are unaffected).
CREATE UNIQUE INDEX "CollectedBusiness_googlePlaceId_key" ON "CollectedBusiness"("googlePlaceId");

-- Used by /records filtering-by-source and by the job runner's dedup lookups.
CREATE INDEX "CollectedBusiness_sourceId_idx" ON "CollectedBusiness"("sourceId");

-- Used to find records still pending/failed enrichment.
CREATE INDEX "CollectedBusiness_socialEnrichmentStatus_idx" ON "CollectedBusiness"("socialEnrichmentStatus");
