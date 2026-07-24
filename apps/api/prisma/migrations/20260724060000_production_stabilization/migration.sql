-- Sprint 1: allow administration to disable a user without deleting their
-- account or contribution history. Existing users remain active by default.
ALTER TABLE "User"
  ADD COLUMN "isBlocked" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN "blockedAt" TIMESTAMP(3),
  ADD COLUMN "blockedReason" TEXT;
