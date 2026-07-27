CREATE TABLE "PriceHistory" (
  "id" TEXT NOT NULL,
  "priceGuideId" TEXT NOT NULL,
  "changedBy" TEXT,
  "snapshot" JSONB NOT NULL,
  "reason" TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "PriceHistory_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "PriceHistory_priceGuideId_createdAt_idx" ON "PriceHistory"("priceGuideId", "createdAt");
ALTER TABLE "PriceHistory" ADD CONSTRAINT "PriceHistory_priceGuideId_fkey" FOREIGN KEY ("priceGuideId") REFERENCES "PriceGuide"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE "NotificationCampaign" (
  "id" TEXT NOT NULL,
  "title" TEXT NOT NULL,
  "body" TEXT NOT NULL,
  "targetAreaId" TEXT,
  "targetRole" TEXT,
  "scheduledAt" TIMESTAMP(3),
  "sentAt" TIMESTAMP(3),
  "status" TEXT NOT NULL DEFAULT 'PENDING',
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "NotificationCampaign_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "NotificationCampaign_status_scheduledAt_idx" ON "NotificationCampaign"("status", "scheduledAt");
ALTER TABLE "NotificationCampaign" ADD CONSTRAINT "NotificationCampaign_targetAreaId_fkey" FOREIGN KEY ("targetAreaId") REFERENCES "Area"("id") ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "PlatformSettings" ADD COLUMN "priceDefaultValidityDays" INTEGER NOT NULL DEFAULT 30;
ALTER TABLE "PlatformSettings" ADD COLUMN "priceOutlierRatio" DOUBLE PRECISION NOT NULL DEFAULT 2.5;
