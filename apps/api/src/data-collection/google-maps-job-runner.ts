import { randomUUID } from 'node:crypto';
import type { PrismaClient } from '@prisma/client';
import {
  buildGoogleMapsUrl,
  composeSearchQuery,
  GoogleMapsQuotaError,
  iterateGooglePlaces,
  type GooglePlaceResult,
} from './google-maps-provider';
import { isSocialEnrichmentConfigured } from './social-enrichment';
import {
  calculateQualityScore,
  fingerprintBusiness,
  normalizeArabicText,
  normalizeEgyptianPhone,
  UNNAMED_BUSINESS_PLACEHOLDER,
} from './normalize';
import {
  enrichSingleRecord,
  markJobCompleted,
  markJobFailed,
  markJobStartedInProcess,
  markJobStoppedInProcess,
  saveJobProgress,
  type CollectionJobRow,
  type JobCounts,
} from './collection-job-shared';

export type { CollectionJobRow };

async function upsertGooglePlaceRecord(
  prisma: PrismaClient,
  job: CollectionJobRow,
  place: GooglePlaceResult,
): Promise<{ id: string; created: boolean }> {
  const name = place.displayName?.text?.trim() || UNNAMED_BUSINESS_PLACEHOLDER;
  const hasRealName = name !== UNNAMED_BUSINESS_PLACEHOLDER;
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
  // The name+area check is skipped for unnamed places — every unnamed place in the same
  // area would otherwise share the exact same placeholder name and falsely "match".
  const existing = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
    `SELECT "id" FROM "CollectedBusiness"
     WHERE "googlePlaceId" = $1
        OR ($2::text IS NOT NULL AND "normalizedPhone" = $2)
        OR "googleMapsUrl" = $3
        OR ($4 AND $5::text IS NOT NULL AND "area" = $5 AND similarity("normalizedName", $6) >= 0.8)
     LIMIT 1`,
    place.id,
    normalizedPhone,
    googleMapsUrl,
    hasRealName,
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

export async function runGoogleMapsJob(prisma: PrismaClient, job: CollectionJobRow): Promise<void> {
  markJobStartedInProcess(job.id);
  const baseMetadata = (job.metadata as Record<string, unknown>) ?? {};
  const limit = typeof baseMetadata.limit === 'number' ? baseMetadata.limit : 50;

  const counts: JobCounts = { found: 0, saved: 0, duplicates: 0, failed: 0, enriched: 0, processed: 0 };

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

      await saveJobProgress(prisma, job.id, baseMetadata, counts);
    }

    await markJobCompleted(prisma, job.id);
  } catch (error) {
    const message = error instanceof GoogleMapsQuotaError
      ? 'تم إيقاف المهمة: تم تجاوز الحد المسموح (quota) لطلبات Google Places API. التقدم المحفوظ حتى الآن لم يُفقد.'
      : error instanceof Error ? error.message : 'فشل غير معروف أثناء تشغيل المهمة';
    await markJobFailed(prisma, job.id, message);
  } finally {
    markJobStoppedInProcess(job.id);
  }
}
