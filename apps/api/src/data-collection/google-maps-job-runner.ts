import { randomUUID } from 'node:crypto';
import type { PrismaClient } from '@prisma/client';
import {
  buildGoogleMapsUrl,
  composeSearchQuery,
  GoogleMapsQuotaError,
  iterateGooglePlaces,
  type GooglePlaceResult,
} from './google-maps-provider';
import { enrichRecordSocialLinks, isSocialEnrichmentConfigured } from './social-enrichment';
import { calculateQualityScore, fingerprintBusiness, normalizeArabicText, normalizeEgyptianPhone } from './normalize';

export type CollectionJobRow = {
  id: string;
  sourceId: string | null;
  category: string | null;
  area: string | null;
  query: string | null;
  metadata: unknown;
};

// Defense-in-depth only — the authoritative guard against a double-run is the
// atomic PENDING->RUNNING UPDATE done by the /jobs/:id/run route handler
// before this function is ever called.
const runningJobIds = new Set<string>();
export const isGoogleMapsJobRunningInProcess = (jobId: string): boolean => runningJobIds.has(jobId);

async function saveProgress(
  prisma: PrismaClient,
  jobId: string,
  baseMetadata: Record<string, unknown>,
  counts: { found: number; saved: number; duplicates: number; failed: number; enriched: number; processed: number },
) {
  const metadata = {
    ...baseMetadata,
    progress: {
      processed: counts.processed,
      total: counts.found,
      enrichedCount: counts.enriched,
    },
  };
  await prisma.$executeRawUnsafe(
    `UPDATE "CollectionJob"
     SET "foundCount" = $2, "savedCount" = $3, "duplicateCount" = $4, "failedCount" = $5, "metadata" = $6::jsonb, "updatedAt" = NOW()
     WHERE "id" = $1`,
    jobId,
    counts.found,
    counts.saved,
    counts.duplicates,
    counts.failed,
    JSON.stringify(metadata),
  );
}

async function upsertGooglePlaceRecord(
  prisma: PrismaClient,
  job: CollectionJobRow,
  place: GooglePlaceResult,
): Promise<{ id: string; created: boolean }> {
  const name = place.displayName?.text?.trim() || 'نشاط بدون اسم';
  const phone = place.internationalPhoneNumber ?? place.nationalPhoneNumber ?? null;
  const normalizedPhone = normalizeEgyptianPhone(phone);
  const normalizedName = normalizeArabicText(name);
  const latitude = place.location?.latitude ?? null;
  const longitude = place.location?.longitude ?? null;
  const address = place.formattedAddress ?? null;
  const googleMapsUrl = buildGoogleMapsUrl(place);
  const website = place.websiteUri ?? null;
  const openingHoursJson = place.regularOpeningHours ? JSON.stringify(place.regularOpeningHours) : null;
  const fingerprint = fingerprintBusiness({ name, phone, area: job.area, address, latitude, longitude });

  const qualityScore = calculateQualityScore({
    phone, address, latitude, longitude, category: job.category, website, googleMapsUrl,
    rating: place.rating, reviewCount: place.userRatingCount,
  });

  // Dedup priority: same googlePlaceId > same normalizedPhone > same googleMapsUrl > strong name+area match.
  const existing = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
    `SELECT "id" FROM "CollectedBusiness"
     WHERE "googlePlaceId" = $1
        OR ($2::text IS NOT NULL AND "normalizedPhone" = $2)
        OR "googleMapsUrl" = $3
        OR ($4::text IS NOT NULL AND "area" = $4 AND similarity("normalizedName", $5) >= 0.8)
     LIMIT 1`,
    place.id,
    normalizedPhone,
    googleMapsUrl,
    job.area,
    normalizedName,
  );

  if (existing.length) {
    const id = existing[0].id;
    // Fill in whatever the existing record is missing, and take the fresher
    // rating/coordinates/name/address — while keeping its original source lineage.
    await prisma.$executeRawUnsafe(
      `UPDATE "CollectedBusiness" SET
         "name" = COALESCE(NULLIF($2, ''), "name"),
         "address" = COALESCE($3, "address"),
         "latitude" = COALESCE($4, "latitude"),
         "longitude" = COALESCE($5, "longitude"),
         "phone" = COALESCE("phone", $6),
         "normalizedPhone" = COALESCE("normalizedPhone", $7),
         "website" = COALESCE("website", $8),
         "googleMapsUrl" = COALESCE("googleMapsUrl", $9),
         "googlePlaceId" = COALESCE("googlePlaceId", $10),
         "rating" = COALESCE($11, "rating"),
         "reviewCount" = COALESCE($12, "reviewCount"),
         "openingHours" = COALESCE($13::jsonb, "openingHours"),
         "qualityScore" = GREATEST("qualityScore", $14),
         "updatedAt" = NOW()
       WHERE "id" = $1`,
      id, name, address, latitude, longitude, phone, normalizedPhone, website, googleMapsUrl, place.id,
      place.rating ?? null, place.userRatingCount ?? null, openingHoursJson, qualityScore,
    );
    return { id, created: false };
  }

  const id = randomUUID();
  await prisma.$executeRawUnsafe(
    `INSERT INTO "CollectedBusiness" (
       "id", "jobId", "sourceId", "externalId", "name", "normalizedName", "category", "city", "area", "address",
       "latitude", "longitude", "phone", "normalizedPhone", "website", "googleMapsUrl", "googlePlaceId",
       "rating", "reviewCount", "openingHours", "rawData", "fingerprint", "qualityScore", "status"
     ) VALUES (
       $1,$2,'google-maps',$3,$4,$5,$6,'قنا',$7,$8,
       $9,$10,$11,$12,$13,$14,$15,
       $16,$17,$18::jsonb,$19::jsonb,$20,$21,'NEW'
     )`,
    id, job.id, place.id, name, normalizedName, job.category, job.area, address,
    latitude, longitude, phone, normalizedPhone, website, googleMapsUrl, place.id,
    place.rating ?? null, place.userRatingCount ?? null, openingHoursJson, JSON.stringify(place), fingerprint, qualityScore,
  );
  return { id, created: true };
}

async function enrichSingleRecord(prisma: PrismaClient, id: string): Promise<boolean> {
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

export async function runGoogleMapsJob(prisma: PrismaClient, job: CollectionJobRow): Promise<void> {
  runningJobIds.add(job.id);
  const baseMetadata = (job.metadata as Record<string, unknown>) ?? {};
  const limit = typeof baseMetadata.limit === 'number' ? baseMetadata.limit : 50;

  const counts = { found: 0, saved: 0, duplicates: 0, failed: 0, enriched: 0, processed: 0 };

  try {
    const textQuery = composeSearchQuery({ category: job.category ?? '', area: job.area ?? '', query: job.query });

    for await (const page of iterateGooglePlaces({ textQuery, limit })) {
      counts.found += page.length;

      for (const place of page) {
        try {
          const { id, created } = await upsertGooglePlaceRecord(prisma, job, place);
          if (created) counts.saved += 1;
          else counts.duplicates += 1;

          if (isSocialEnrichmentConfigured() || place.websiteUri) {
            const ok = await enrichSingleRecord(prisma, id);
            if (ok) counts.enriched += 1;
          }
        } catch {
          counts.failed += 1;
        } finally {
          counts.processed += 1;
        }
      }

      await saveProgress(prisma, job.id, baseMetadata, counts);
    }

    await prisma.$executeRawUnsafe(
      `UPDATE "CollectionJob" SET "status" = 'COMPLETED', "finishedAt" = NOW(), "updatedAt" = NOW() WHERE "id" = $1`,
      job.id,
    );
  } catch (error) {
    const message = error instanceof GoogleMapsQuotaError
      ? 'تم إيقاف المهمة: تم تجاوز الحد المسموح (quota) لطلبات Google Places API. التقدم المحفوظ حتى الآن لم يُفقد.'
      : error instanceof Error ? error.message : 'فشل غير معروف أثناء تشغيل المهمة';

    await prisma.$executeRawUnsafe(
      `UPDATE "CollectionJob" SET "status" = 'FAILED', "finishedAt" = NOW(), "error" = $2, "updatedAt" = NOW() WHERE "id" = $1`,
      job.id,
      message.slice(0, 500),
    );
  } finally {
    runningJobIds.delete(job.id);
  }
}
