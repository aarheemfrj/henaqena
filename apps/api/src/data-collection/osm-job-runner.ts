import { randomUUID } from 'node:crypto';
import type { PrismaClient } from '@prisma/client';
import {
  buildOsmId,
  categoryToOsmTags,
  geocodeArea,
  osmElementCoordinates,
  OsmProviderError,
  searchOsmPlaces,
  type OsmElement,
} from './osm-provider';
import { isSocialEnrichmentConfigured } from './social-enrichment';
import {
  calculateQualityScore,
  fingerprintBusiness,
  normalizeArabicText,
  normalizeEgyptianPhone,
  normalizeUrl,
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

const DEFAULT_SEARCH_RADIUS_METERS = 8000; // covers a Qena-sized market-town center

async function upsertOsmRecord(
  prisma: PrismaClient,
  job: CollectionJobRow,
  element: OsmElement,
): Promise<{ id: string; created: boolean }> {
  const tags = element.tags ?? {};
  const name = tags.name || tags['name:ar'] || UNNAMED_BUSINESS_PLACEHOLDER;
  const hasRealName = name !== UNNAMED_BUSINESS_PLACEHOLDER;
  const phone = tags.phone || tags['contact:phone'] || null;
  const normalizedPhone = normalizeEgyptianPhone(phone);
  const normalizedName = normalizeArabicText(name);
  const { latitude, longitude } = osmElementCoordinates(element);
  const address = [tags['addr:street'], tags['addr:housenumber']].filter(Boolean).join(' ') || null;
  const website = normalizeUrl(tags.website || tags['contact:website']);
  const osmId = buildOsmId(element);
  const fingerprint = fingerprintBusiness({ name, phone, area: job.area, address, latitude, longitude });

  const qualityScore = calculateQualityScore({ phone, address, latitude, longitude, category: job.category, website });

  // Dedup priority: same osmId > same normalizedPhone > strong name+area match.
  // The name+area check is skipped for unnamed elements — every unnamed OSM node in the
  // same area would otherwise share the exact same placeholder name and falsely "match".
  const existing = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
    `SELECT "id" FROM "CollectedBusiness"
     WHERE "osmId" = $1
        OR ($2::text IS NOT NULL AND "normalizedPhone" = $2)
        OR ($3 AND $4::text IS NOT NULL AND "area" = $4 AND similarity("normalizedName", $5) >= 0.8)
     LIMIT 1`,
    osmId,
    normalizedPhone,
    hasRealName,
    job.area,
    normalizedName,
  );

  if (existing.length) {
    const id = existing[0].id;
    await prisma.$executeRawUnsafe(
      `UPDATE "CollectedBusiness" SET
         "name" = COALESCE(NULLIF($2, ''), "name"),
         "address" = COALESCE($3, "address"),
         "latitude" = COALESCE($4, "latitude"),
         "longitude" = COALESCE($5, "longitude"),
         "phone" = COALESCE("phone", $6),
         "normalizedPhone" = COALESCE("normalizedPhone", $7),
         "website" = COALESCE("website", $8),
         "osmId" = COALESCE("osmId", $9),
         "qualityScore" = GREATEST("qualityScore", $10),
         "updatedAt" = NOW()
       WHERE "id" = $1`,
      id, name, address, latitude, longitude, phone, normalizedPhone, website, osmId, qualityScore,
    );
    return { id, created: false };
  }

  const id = randomUUID();
  await prisma.$executeRawUnsafe(
    `INSERT INTO "CollectedBusiness" (
       "id", "jobId", "sourceId", "externalId", "name", "normalizedName", "category", "city", "area", "address",
       "latitude", "longitude", "phone", "normalizedPhone", "website", "osmId",
       "rawData", "fingerprint", "qualityScore", "status"
     ) VALUES (
       $1,$2,'osm',$3,$4,$5,$6,'قنا',$7,$8,
       $9,$10,$11,$12,$13,$14,
       $15::jsonb,$16,$17,'NEW'
     )`,
    id, job.id, osmId, name, normalizedName, job.category, job.area, address,
    latitude, longitude, phone, normalizedPhone, website, osmId,
    JSON.stringify(element), fingerprint, qualityScore,
  );
  return { id, created: true };
}

export async function runOsmJob(prisma: PrismaClient, job: CollectionJobRow): Promise<void> {
  markJobStartedInProcess(job.id);
  const baseMetadata = (job.metadata as Record<string, unknown>) ?? {};
  const limit = typeof baseMetadata.limit === 'number' ? baseMetadata.limit : 50;

  const counts: JobCounts = { found: 0, saved: 0, duplicates: 0, failed: 0, enriched: 0, processed: 0 };

  try {
    const tags = categoryToOsmTags(job.category ?? '');
    if (!tags.length) {
      throw new OsmProviderError(`الفئة "${job.category ?? ''}" غير مدعومة حاليًا في OpenStreetMap`);
    }

    const geocoded = await geocodeArea({ area: job.area ?? '', city: 'قنا' });
    if (!geocoded) {
      throw new OsmProviderError(`تعذر تحديد موقع "${job.area ?? ''}" على الخريطة`);
    }

    const elements = await searchOsmPlaces({
      lat: geocoded.lat,
      lon: geocoded.lon,
      radiusMeters: DEFAULT_SEARCH_RADIUS_METERS,
      tags,
      limit,
    });
    counts.found = elements.length;
    await saveJobProgress(prisma, job.id, baseMetadata, counts);

    for (const element of elements) {
      try {
        const { id, created } = await upsertOsmRecord(prisma, job, element);
        if (created) counts.saved += 1;
        else counts.duplicates += 1;

        const hasWebsite = Boolean(element.tags?.website || element.tags?.['contact:website']);
        if (isSocialEnrichmentConfigured() || hasWebsite) {
          const ok = await enrichSingleRecord(prisma, id);
          if (ok) counts.enriched += 1;
        }
      } catch {
        counts.failed += 1;
      } finally {
        counts.processed += 1;
        await saveJobProgress(prisma, job.id, baseMetadata, counts);
      }
    }

    await markJobCompleted(prisma, job.id);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'فشل غير معروف أثناء تشغيل مهمة OpenStreetMap';
    await markJobFailed(prisma, job.id, message);
  } finally {
    markJobStoppedInProcess(job.id);
  }
}
