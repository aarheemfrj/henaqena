// Shared helpers used by every source-specific job runner (google-maps-job-runner.ts,
// osm-job-runner.ts, ...) so the progress/enrichment/completion logic only lives once.
import type { PrismaClient } from '@prisma/client';
import { enrichRecordSocialLinks } from './social-enrichment';

// Defense-in-depth only — the authoritative guard against a double-run is the
// atomic PENDING->RUNNING UPDATE done by the /jobs/:id/run route handler
// before any runner function is ever called.
const runningJobIds = new Set<string>();
export const isCollectionJobRunningInProcess = (jobId: string): boolean => runningJobIds.has(jobId);
export const markJobStartedInProcess = (jobId: string): void => { runningJobIds.add(jobId); };
export const markJobStoppedInProcess = (jobId: string): void => { runningJobIds.delete(jobId); };

export type JobCounts = { found: number; saved: number; duplicates: number; failed: number; enriched: number; processed: number };

export type CollectionJobRow = {
  id: string;
  sourceId: string | null;
  category: string | null;
  area: string | null;
  query: string | null;
  metadata: unknown;
};

export async function saveJobProgress(
  prisma: PrismaClient,
  jobId: string,
  baseMetadata: Record<string, unknown>,
  counts: JobCounts,
): Promise<void> {
  const metadata = {
    ...baseMetadata,
    progress: { processed: counts.processed, total: counts.found, enrichedCount: counts.enriched },
  };
  await prisma.$executeRawUnsafe(
    `UPDATE "CollectionJob"
     SET "foundCount" = $2, "savedCount" = $3, "duplicateCount" = $4, "failedCount" = $5, "metadata" = $6::jsonb, "updatedAt" = NOW()
     WHERE "id" = $1`,
    jobId, counts.found, counts.saved, counts.duplicates, counts.failed, JSON.stringify(metadata),
  );
}

export async function markJobCompleted(prisma: PrismaClient, jobId: string): Promise<void> {
  await prisma.$executeRawUnsafe(
    `UPDATE "CollectionJob" SET "status" = 'COMPLETED', "finishedAt" = NOW(), "updatedAt" = NOW() WHERE "id" = $1`,
    jobId,
  );
}

export async function markJobFailed(prisma: PrismaClient, jobId: string, message: string): Promise<void> {
  await prisma.$executeRawUnsafe(
    `UPDATE "CollectionJob" SET "status" = 'FAILED', "finishedAt" = NOW(), "error" = $2, "updatedAt" = NOW() WHERE "id" = $1`,
    jobId, message.slice(0, 500),
  );
}

/** Runs social-link enrichment for one saved record and persists the outcome. Source-agnostic. */
export async function enrichSingleRecord(prisma: PrismaClient, id: string): Promise<boolean> {
  const rows = await prisma.$queryRawUnsafe<Array<{ id: string; name: string; area: string | null; phone: string | null; website: string | null }>>(
    `SELECT "id", "name", "area", "phone", "website" FROM "CollectedBusiness" WHERE "id" = $1`,
    id,
  );
  const record = rows[0];
  if (!record) return false;

  const outcome = await enrichRecordSocialLinks(record);

  await prisma.$executeRawUnsafe(
    `UPDATE "CollectedBusiness" SET
       "facebook" = COALESCE($2, "facebook"),
       "instagram" = COALESCE($3, "instagram"),
       "tiktok" = COALESCE($4, "tiktok"),
       "whatsapp" = COALESCE("whatsapp", $5),
       "socialEnrichment" = $6::jsonb,
       "socialCandidates" = $7::jsonb,
       "socialEnrichmentStatus" = $8::"SocialEnrichmentStatus",
       "socialEnrichmentError" = $9,
       "socialEnrichedAt" = NOW(),
       "updatedAt" = NOW()
     WHERE "id" = $1`,
    id,
    outcome.accepted.facebook?.url ?? null,
    outcome.accepted.instagram?.url ?? null,
    outcome.accepted.tiktok?.url ?? null,
    outcome.whatsapp,
    JSON.stringify(outcome.accepted),
    JSON.stringify(outcome.candidates),
    outcome.status,
    outcome.error ?? null,
  );

  return outcome.status === 'COMPLETED';
}
