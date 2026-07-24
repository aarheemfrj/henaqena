-- DropIndex
DROP INDEX "PriceGuide_status_updatedAt_idx";

-- AlterTable
ALTER TABLE "PriceGuide" ADD COLUMN     "confidenceScore" INTEGER NOT NULL DEFAULT 50,
ADD COLUMN     "lastReviewedAt" TIMESTAMP(3),
ADD COLUMN     "sourceType" TEXT NOT NULL DEFAULT 'COMMUNITY',
ADD COLUMN     "validUntil" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "PriceGuide_status_validUntil_updatedAt_idx" ON "PriceGuide"("status", "validUntil", "updatedAt");
