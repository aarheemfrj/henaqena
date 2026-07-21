CREATE EXTENSION IF NOT EXISTS pg_trgm;

DO $$ BEGIN
  CREATE TYPE "CollectionJobStatus" AS ENUM ('PENDING', 'RUNNING', 'COMPLETED', 'FAILED', 'CANCELLED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE "CollectedRecordStatus" AS ENUM ('NEW', 'NEEDS_REVIEW', 'APPROVED', 'REJECTED', 'MERGED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS "DataSource" (
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "kind" TEXT NOT NULL,
  "baseUrl" TEXT,
  "isActive" BOOLEAN NOT NULL DEFAULT TRUE,
  "metadata" JSONB,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS "DataSource_name_key" ON "DataSource" ("name");

CREATE TABLE IF NOT EXISTS "CollectionJob" (
  "id" TEXT PRIMARY KEY,
  "sourceId" TEXT REFERENCES "DataSource"("id") ON DELETE SET NULL,
  "category" TEXT,
  "area" TEXT,
  "query" TEXT,
  "status" "CollectionJobStatus" NOT NULL DEFAULT 'PENDING',
  "startedAt" TIMESTAMPTZ,
  "finishedAt" TIMESTAMPTZ,
  "foundCount" INTEGER NOT NULL DEFAULT 0,
  "savedCount" INTEGER NOT NULL DEFAULT 0,
  "duplicateCount" INTEGER NOT NULL DEFAULT 0,
  "failedCount" INTEGER NOT NULL DEFAULT 0,
  "error" TEXT,
  "metadata" JSONB,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "CollectionJob_status_createdAt_idx"
  ON "CollectionJob" ("status", "createdAt" DESC);

CREATE TABLE IF NOT EXISTS "CollectedBusiness" (
  "id" TEXT PRIMARY KEY,
  "jobId" TEXT REFERENCES "CollectionJob"("id") ON DELETE SET NULL,
  "sourceId" TEXT REFERENCES "DataSource"("id") ON DELETE SET NULL,
  "externalId" TEXT,
  "name" TEXT NOT NULL,
  "normalizedName" TEXT NOT NULL,
  "category" TEXT,
  "subcategory" TEXT,
  "city" TEXT NOT NULL DEFAULT 'قنا',
  "area" TEXT,
  "village" TEXT,
  "address" TEXT,
  "latitude" DOUBLE PRECISION,
  "longitude" DOUBLE PRECISION,
  "phone" TEXT,
  "normalizedPhone" TEXT,
  "whatsapp" TEXT,
  "email" TEXT,
  "website" TEXT,
  "facebook" TEXT,
  "instagram" TEXT,
  "tiktok" TEXT,
  "googleMapsUrl" TEXT,
  "rating" DOUBLE PRECISION,
  "reviewCount" INTEGER,
  "openingHours" JSONB,
  "rawData" JSONB,
  "fingerprint" TEXT NOT NULL,
  "qualityScore" INTEGER NOT NULL DEFAULT 0,
  "status" "CollectedRecordStatus" NOT NULL DEFAULT 'NEW',
  "reviewNote" TEXT,
  "reviewedAt" TIMESTAMPTZ,
  "reviewedBy" TEXT,
  "providerId" TEXT REFERENCES "Provider"("id") ON DELETE SET NULL,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "updatedAt" TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS "CollectedBusiness_fingerprint_key"
  ON "CollectedBusiness" ("fingerprint");

CREATE INDEX IF NOT EXISTS "CollectedBusiness_status_quality_idx"
  ON "CollectedBusiness" ("status", "qualityScore" DESC);

CREATE INDEX IF NOT EXISTS "CollectedBusiness_normalizedName_trgm_idx"
  ON "CollectedBusiness" USING GIN ("normalizedName" gin_trgm_ops);

CREATE INDEX IF NOT EXISTS "CollectedBusiness_normalizedPhone_idx"
  ON "CollectedBusiness" ("normalizedPhone");

CREATE TABLE IF NOT EXISTS "DuplicateCandidate" (
  "id" TEXT PRIMARY KEY,
  "leftId" TEXT NOT NULL REFERENCES "CollectedBusiness"("id") ON DELETE CASCADE,
  "rightId" TEXT NOT NULL REFERENCES "CollectedBusiness"("id") ON DELETE CASCADE,
  "score" DOUBLE PRECISION NOT NULL,
  "reason" TEXT NOT NULL,
  "resolved" BOOLEAN NOT NULL DEFAULT FALSE,
  "resolution" TEXT,
  "createdAt" TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  "resolvedAt" TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS "DuplicateCandidate_pair_key"
  ON "DuplicateCandidate" (
    LEAST("leftId", "rightId"),
    GREATEST("leftId", "rightId")
  );

CREATE INDEX IF NOT EXISTS "DuplicateCandidate_unresolved_score_idx"
  ON "DuplicateCandidate" ("resolved", "score" DESC);

INSERT INTO "DataSource" ("id", "name", "kind", "isActive")
VALUES
  ('manual-csv', 'Manual CSV Import', 'CSV', TRUE),
  ('google-maps', 'Google Maps', 'MAPS', FALSE),
  ('facebook', 'Facebook', 'SOCIAL', FALSE),
  ('instagram', 'Instagram', 'SOCIAL', FALSE),
  ('tiktok', 'TikTok', 'SOCIAL', FALSE)
ON CONFLICT ("name") DO NOTHING;
