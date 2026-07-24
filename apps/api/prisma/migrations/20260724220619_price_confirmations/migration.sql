-- CreateTable
CREATE TABLE "PriceConfirmation" (
    "id" TEXT NOT NULL,
    "priceGuideId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "stillValid" BOOLEAN NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PriceConfirmation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PriceConfirmation_priceGuideId_createdAt_idx" ON "PriceConfirmation"("priceGuideId", "createdAt");

-- CreateIndex
CREATE INDEX "PriceConfirmation_userId_createdAt_idx" ON "PriceConfirmation"("userId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "PriceConfirmation_priceGuideId_userId_key" ON "PriceConfirmation"("priceGuideId", "userId");

-- AddForeignKey
ALTER TABLE "PriceConfirmation" ADD CONSTRAINT "PriceConfirmation_priceGuideId_fkey" FOREIGN KEY ("priceGuideId") REFERENCES "PriceGuide"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PriceConfirmation" ADD CONSTRAINT "PriceConfirmation_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
