import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { PrismaClient } from '@prisma/client';
import { parseCsv } from './csv';
import {
  calculateQualityScore,
  fingerprintBusiness,
  normalizeArabicText,
  normalizeEgyptianPhone,
  normalizeUrl,
  similarityScore,
} from './normalize';

const prisma = new PrismaClient();

const getArg = (name: string): string | undefined => {
  const prefixed = `--${name}=`;
  return process.argv.find((arg) => arg.startsWith(prefixed))?.slice(prefixed.length);
};

const required = (name: string): string => {
  const value = getArg(name);
  if (!value) throw new Error(`Missing --${name}=...`);
  return value;
};

const nullable = (value?: string): string | null => value?.trim() || null;
const numberOrNull = (value?: string): number | null => {
  if (!value?.trim()) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const main = async () => {
  const file = required('file');
  const sourceId = getArg('source') ?? 'manual-csv';
  const defaultCategory = getArg('category') ?? null;
  const defaultArea = getArg('area') ?? null;

  const rows = parseCsv(await readFile(file, 'utf8'));
  const jobId = randomUUID();

  await prisma.$executeRawUnsafe(
    `INSERT INTO "CollectionJob"
      ("id", "sourceId", "category", "area", "query", "status", "startedAt", "foundCount")
     VALUES ($1, $2, $3, $4, $5, 'RUNNING', NOW(), $6)`,
    jobId,
    sourceId,
    defaultCategory,
    defaultArea,
    `csv:${file}`,
    rows.length,
  );

  let saved = 0;
  let duplicates = 0;
  let failed = 0;

  for (const row of rows) {
    try {
      const name = (row.name || row.business_name || row['الاسم'] || '').trim();
      if (!name) {
        failed += 1;
        continue;
      }

      const phone = nullable(row.phone || row.mobile || row['التليفون'] || row['الهاتف']);
      const normalizedPhone = normalizeEgyptianPhone(phone);
      const latitude = numberOrNull(row.latitude || row.lat);
      const longitude = numberOrNull(row.longitude || row.lng || row.lon);
      const area = nullable(row.area || row.center || row['المنطقة'] || row['المركز']) ?? defaultArea;
      const address = nullable(row.address || row['العنوان']);
      const category = nullable(row.category || row['التصنيف']) ?? defaultCategory;
      const normalizedName = normalizeArabicText(name);
      const fingerprint = fingerprintBusiness({ name, phone, area, address, latitude, longitude });

      const record = {
        name,
        normalizedName,
        category,
        subcategory: nullable(row.subcategory || row['التصنيف الفرعي']),
        city: nullable(row.city || row['المدينة']) ?? 'قنا',
        area,
        village: nullable(row.village || row['القرية']),
        address,
        latitude,
        longitude,
        phone,
        normalizedPhone,
        whatsapp: normalizeEgyptianPhone(row.whatsapp || row['واتساب']),
        email: nullable(row.email || row['البريد']),
        website: normalizeUrl(row.website || row['الموقع']),
        facebook: normalizeUrl(row.facebook),
        instagram: normalizeUrl(row.instagram),
        tiktok: normalizeUrl(row.tiktok),
        googleMapsUrl: normalizeUrl(row.google_maps_url || row.maps || row['خرائط جوجل']),
        rating: numberOrNull(row.rating || row['التقييم']),
        reviewCount: numberOrNull(row.review_count || row.reviews || row['عدد التقييمات']),
        fingerprint,
      };

      const qualityScore = calculateQualityScore(record);

      const inserted = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
        `INSERT INTO "CollectedBusiness" (
          "id", "jobId", "sourceId", "externalId", "name", "normalizedName",
          "category", "subcategory", "city", "area", "village", "address",
          "latitude", "longitude", "phone", "normalizedPhone", "whatsapp",
          "email", "website", "facebook", "instagram", "tiktok", "googleMapsUrl",
          "rating", "reviewCount", "rawData", "fingerprint", "qualityScore", "status"
        ) VALUES (
          $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,
          $18,$19,$20,$21,$22,$23,$24,$25,$26::jsonb,$27,$28,'NEW'
        )
        ON CONFLICT ("fingerprint") DO NOTHING
        RETURNING "id"`,
        randomUUID(),
        jobId,
        sourceId,
        nullable(row.external_id || row.place_id),
        record.name,
        record.normalizedName,
        record.category,
        record.subcategory,
        record.city,
        record.area,
        record.village,
        record.address,
        record.latitude,
        record.longitude,
        record.phone,
        record.normalizedPhone,
        record.whatsapp,
        record.email,
        record.website,
        record.facebook,
        record.instagram,
        record.tiktok,
        record.googleMapsUrl,
        record.rating,
        record.reviewCount,
        JSON.stringify(row),
        record.fingerprint,
        qualityScore,
      );

      if (!inserted.length) {
        duplicates += 1;
        continue;
      }

      saved += 1;
      const id = inserted[0].id;

      const candidates = await prisma.$queryRawUnsafe<
        Array<{ id: string; name: string; normalizedPhone: string | null }>
      >(
        `SELECT "id", "name", "normalizedPhone"
         FROM "CollectedBusiness"
         WHERE "id" <> $1
           AND (
             ($2::text IS NOT NULL AND "normalizedPhone" = $2)
             OR similarity("normalizedName", $3) >= 0.55
           )
         ORDER BY similarity("normalizedName", $3) DESC
         LIMIT 10`,
        id,
        normalizedPhone,
        normalizedName,
      );

      for (const candidate of candidates) {
        const samePhone = Boolean(normalizedPhone && candidate.normalizedPhone === normalizedPhone);
        const score = samePhone ? 1 : similarityScore(name, candidate.name);
        if (score < 0.55) continue;

        await prisma.$executeRawUnsafe(
          `INSERT INTO "DuplicateCandidate"
            ("id", "leftId", "rightId", "score", "reason")
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT DO NOTHING`,
          randomUUID(),
          id,
          candidate.id,
          score,
          samePhone ? 'same_phone' : 'similar_name',
        );

        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness"
           SET "status" = 'NEEDS_REVIEW', "updatedAt" = NOW()
           WHERE "id" IN ($1, $2) AND "status" = 'NEW'`,
          id,
          candidate.id,
        );
      }
    } catch (error) {
      failed += 1;
      console.error('Failed row:', row, error);
    }
  }

  await prisma.$executeRawUnsafe(
    `UPDATE "CollectionJob"
     SET "status" = 'COMPLETED',
         "finishedAt" = NOW(),
         "savedCount" = $2,
         "duplicateCount" = $3,
         "failedCount" = $4,
         "updatedAt" = NOW()
     WHERE "id" = $1`,
    jobId,
    saved,
    duplicates,
    failed,
  );

  console.log(JSON.stringify({ jobId, found: rows.length, saved, duplicates, failed }, null, 2));
};

main()
  .catch(async (error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
