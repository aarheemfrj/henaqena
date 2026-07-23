ALTER TABLE "Notification"
ADD COLUMN "targetType" TEXT,
ADD COLUMN "targetId" TEXT;

CREATE INDEX "Notification_targetType_targetId_idx"
ON "Notification"("targetType", "targetId");
