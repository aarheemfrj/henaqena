-- Optional per-item logo, shown instead of the generic category icon when set.
ALTER TABLE "Provider" ADD COLUMN "logoUrl" TEXT;
ALTER TABLE "Listing" ADD COLUMN "logoUrl" TEXT;
ALTER TABLE "ProviderService" ADD COLUMN "logoUrl" TEXT;

-- Single-row table holding admin-configurable platform settings.
CREATE TABLE "PlatformSettings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "adRotationSeconds" INTEGER NOT NULL DEFAULT 6,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlatformSettings_pkey" PRIMARY KEY ("id")
);

INSERT INTO "PlatformSettings" ("id", "adRotationSeconds", "updatedAt")
VALUES ('default', 6, NOW());
