-- DropForeignKey
ALTER TABLE "CollectedBusiness" DROP CONSTRAINT "CollectedBusiness_jobId_fkey";

-- DropForeignKey
ALTER TABLE "CollectedBusiness" DROP CONSTRAINT "CollectedBusiness_providerId_fkey";

-- DropForeignKey
ALTER TABLE "CollectedBusiness" DROP CONSTRAINT "CollectedBusiness_sourceId_fkey";

-- DropForeignKey
ALTER TABLE "CollectionJob" DROP CONSTRAINT "CollectionJob_sourceId_fkey";

-- DropForeignKey
ALTER TABLE "DuplicateCandidate" DROP CONSTRAINT "DuplicateCandidate_leftId_fkey";

-- DropForeignKey
ALTER TABLE "DuplicateCandidate" DROP CONSTRAINT "DuplicateCandidate_rightId_fkey";

-- DropIndex
DROP INDEX "CollectedBusiness_normalizedName_trgm_idx";

-- DropIndex
DROP INDEX "CollectedBusiness_status_quality_idx";

-- DropIndex
DROP INDEX "CollectionJob_status_createdAt_idx";

-- DropIndex
DROP INDEX "DuplicateCandidate_unresolved_score_idx";

-- DropIndex
DROP INDEX "Notification_targetType_targetId_idx";

-- AlterTable
ALTER TABLE "CollectedBusiness" ALTER COLUMN "reviewedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "updatedAt" DROP DEFAULT,
ALTER COLUMN "updatedAt" SET DATA TYPE TIMESTAMP(3);

-- AlterTable
ALTER TABLE "CollectionJob" ALTER COLUMN "startedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "finishedAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "updatedAt" DROP DEFAULT,
ALTER COLUMN "updatedAt" SET DATA TYPE TIMESTAMP(3);

-- AlterTable
ALTER TABLE "DataSource" ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "updatedAt" DROP DEFAULT,
ALTER COLUMN "updatedAt" SET DATA TYPE TIMESTAMP(3);

-- AlterTable
ALTER TABLE "DuplicateCandidate" ALTER COLUMN "createdAt" SET DATA TYPE TIMESTAMP(3),
ALTER COLUMN "resolvedAt" SET DATA TYPE TIMESTAMP(3);

-- CreateTable
CREATE TABLE "MinShaterRequest" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "categoryId" TEXT NOT NULL,
    "areaId" TEXT,
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "moderationStatus" "ReviewStatus" NOT NULL DEFAULT 'PENDING',
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "closedAt" TIMESTAMP(3),
    "archivedAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "MinShaterRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MinShaterRecommendation" (
    "id" TEXT NOT NULL,
    "requestId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "providerId" TEXT,
    "recommendedName" TEXT,
    "phone" TEXT,
    "description" TEXT,
    "moderationStatus" "ReviewStatus" NOT NULL DEFAULT 'PENDING',
    "rejectionReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "archivedAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "MinShaterRecommendation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MinShaterHelpful" (
    "recommendationId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MinShaterHelpful_pkey" PRIMARY KEY ("recommendationId","userId")
);

-- CreateTable
CREATE TABLE "MinShaterReport" (
    "id" TEXT NOT NULL,
    "reporterUserId" TEXT NOT NULL,
    "requestId" TEXT,
    "recommendationId" TEXT,
    "reason" TEXT NOT NULL,
    "description" TEXT,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "reviewedByAdminId" TEXT,
    "reviewedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MinShaterReport_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "MinShaterRequest_moderationStatus_status_createdAt_idx" ON "MinShaterRequest"("moderationStatus", "status", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRequest_categoryId_createdAt_idx" ON "MinShaterRequest"("categoryId", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRequest_areaId_createdAt_idx" ON "MinShaterRequest"("areaId", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRequest_userId_createdAt_idx" ON "MinShaterRequest"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRequest_archivedAt_deletedAt_idx" ON "MinShaterRequest"("archivedAt", "deletedAt");

-- CreateIndex
CREATE INDEX "MinShaterRecommendation_requestId_moderationStatus_createdA_idx" ON "MinShaterRecommendation"("requestId", "moderationStatus", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRecommendation_providerId_moderationStatus_idx" ON "MinShaterRecommendation"("providerId", "moderationStatus");

-- CreateIndex
CREATE INDEX "MinShaterRecommendation_userId_createdAt_idx" ON "MinShaterRecommendation"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterRecommendation_archivedAt_deletedAt_idx" ON "MinShaterRecommendation"("archivedAt", "deletedAt");

-- CreateIndex
CREATE INDEX "MinShaterHelpful_recommendationId_idx" ON "MinShaterHelpful"("recommendationId");

-- CreateIndex
CREATE INDEX "MinShaterReport_requestId_status_createdAt_idx" ON "MinShaterReport"("requestId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterReport_recommendationId_status_createdAt_idx" ON "MinShaterReport"("recommendationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "MinShaterReport_reporterUserId_createdAt_idx" ON "MinShaterReport"("reporterUserId", "createdAt");

-- CreateIndex
CREATE INDEX "CollectionJob_status_createdAt_idx" ON "CollectionJob"("status", "createdAt");

-- AddForeignKey
ALTER TABLE "MinShaterRequest" ADD CONSTRAINT "MinShaterRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterRequest" ADD CONSTRAINT "MinShaterRequest_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterRequest" ADD CONSTRAINT "MinShaterRequest_areaId_fkey" FOREIGN KEY ("areaId") REFERENCES "Area"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterRecommendation" ADD CONSTRAINT "MinShaterRecommendation_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "MinShaterRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterRecommendation" ADD CONSTRAINT "MinShaterRecommendation_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterRecommendation" ADD CONSTRAINT "MinShaterRecommendation_providerId_fkey" FOREIGN KEY ("providerId") REFERENCES "Provider"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterHelpful" ADD CONSTRAINT "MinShaterHelpful_recommendationId_fkey" FOREIGN KEY ("recommendationId") REFERENCES "MinShaterRecommendation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterHelpful" ADD CONSTRAINT "MinShaterHelpful_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterReport" ADD CONSTRAINT "MinShaterReport_reporterUserId_fkey" FOREIGN KEY ("reporterUserId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterReport" ADD CONSTRAINT "MinShaterReport_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "MinShaterRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MinShaterReport" ADD CONSTRAINT "MinShaterReport_recommendationId_fkey" FOREIGN KEY ("recommendationId") REFERENCES "MinShaterRecommendation"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CollectionJob" ADD CONSTRAINT "CollectionJob_sourceId_fkey" FOREIGN KEY ("sourceId") REFERENCES "DataSource"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CollectedBusiness" ADD CONSTRAINT "CollectedBusiness_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES "CollectionJob"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CollectedBusiness" ADD CONSTRAINT "CollectedBusiness_sourceId_fkey" FOREIGN KEY ("sourceId") REFERENCES "DataSource"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DuplicateCandidate" ADD CONSTRAINT "DuplicateCandidate_leftId_fkey" FOREIGN KEY ("leftId") REFERENCES "CollectedBusiness"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "DuplicateCandidate" ADD CONSTRAINT "DuplicateCandidate_rightId_fkey" FOREIGN KEY ("rightId") REFERENCES "CollectedBusiness"("id") ON DELETE CASCADE ON UPDATE CASCADE;
