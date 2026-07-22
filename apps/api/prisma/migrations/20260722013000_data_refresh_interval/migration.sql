-- Admin-configurable interval (seconds) the mobile app uses to auto-refresh
-- home page listings/categories, so content updates without a manual reopen.
ALTER TABLE "PlatformSettings" ADD COLUMN "dataRefreshSeconds" INTEGER NOT NULL DEFAULT 60;
