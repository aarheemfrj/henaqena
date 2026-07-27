ALTER TABLE "MinShaterRecommendation" ADD COLUMN "isSelected" BOOLEAN NOT NULL DEFAULT false;
CREATE INDEX "MinShaterRecommendation_requestId_isSelected_idx" ON "MinShaterRecommendation"("requestId", "isSelected");
