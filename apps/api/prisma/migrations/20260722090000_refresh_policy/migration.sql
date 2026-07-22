ALTER TABLE "PlatformSettings"
  ALTER COLUMN "dataRefreshSeconds" SET DEFAULT 900;

UPDATE "PlatformSettings"
SET "dataRefreshSeconds" = 900
WHERE "id" = 'default' AND "dataRefreshSeconds" = 60;
