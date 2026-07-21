import { randomUUID } from 'node:crypto';
import { Router } from 'express';
import type { PrismaClient } from '@prisma/client';
import { z } from 'zod';

export const createDataCollectionRouter = (prisma: PrismaClient): Router => {
  const router = Router();

  router.get('/overview', async (_req, res, next) => {
    try {
      const [statuses, unresolvedDuplicates, latestJobs] = await Promise.all([
        prisma.$queryRawUnsafe<Array<{ status: string; count: bigint }>>(
          `SELECT "status"::text, COUNT(*)::bigint AS count
           FROM "CollectedBusiness"
           GROUP BY "status"`,
        ),
        prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
          `SELECT COUNT(*)::bigint AS count
           FROM "DuplicateCandidate"
           WHERE "resolved" = FALSE`,
        ),
        prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
          `SELECT *
           FROM "CollectionJob"
           ORDER BY "createdAt" DESC
           LIMIT 10`,
        ),
      ]);

      res.json({
        statuses: Object.fromEntries(statuses.map((item) => [item.status, Number(item.count)])),
        unresolvedDuplicates: Number(unresolvedDuplicates[0]?.count ?? 0),
        latestJobs,
      });
    } catch (error) {
      next(error);
    }
  });

  router.get('/records', async (req, res, next) => {
    try {
      const input = z.object({
        status: z.enum(['NEW', 'NEEDS_REVIEW', 'APPROVED', 'REJECTED', 'MERGED']).optional(),
        search: z.string().max(120).optional(),
        limit: z.coerce.number().int().min(1).max(100).default(50),
        offset: z.coerce.number().int().min(0).default(0),
      }).parse(req.query);

      const conditions: string[] = [];
      const params: unknown[] = [];
      const addParam = (value: unknown): string => {
        params.push(value);
        return `$${params.length}`;
      };

      if (input.status) conditions.push(`"status" = ${addParam(input.status)}::"CollectedRecordStatus"`);
      if (input.search) {
        const token = addParam(input.search);
        conditions.push(`(
          "name" ILIKE '%' || ${token} || '%'
          OR COALESCE("phone", '') ILIKE '%' || ${token} || '%'
          OR COALESCE("address", '') ILIKE '%' || ${token} || '%'
        )`);
      }

      const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';
      const limitParam = addParam(input.limit);
      const offsetParam = addParam(input.offset);

      const records = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT *
         FROM "CollectedBusiness"
         ${where}
         ORDER BY "qualityScore" DESC, "createdAt" DESC
         LIMIT ${limitParam} OFFSET ${offsetParam}`,
        ...params,
      );

      res.json(records);
    } catch (error) {
      next(error);
    }
  });

  router.get('/duplicates', async (_req, res, next) => {
    try {
      const rows = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT
           d.*,
           row_to_json(l.*) AS "left",
           row_to_json(r.*) AS "right"
         FROM "DuplicateCandidate" d
         JOIN "CollectedBusiness" l ON l."id" = d."leftId"
         JOIN "CollectedBusiness" r ON r."id" = d."rightId"
         WHERE d."resolved" = FALSE
         ORDER BY d."score" DESC, d."createdAt" ASC
         LIMIT 100`,
      );
      res.json(rows);
    } catch (error) {
      next(error);
    }
  });

  router.patch('/records/:id', async (req, res, next) => {
    try {
      const input = z.object({
        status: z.enum(['NEW', 'NEEDS_REVIEW', 'APPROVED', 'REJECTED', 'MERGED']),
        reviewNote: z.string().max(1000).nullable().optional(),
        reviewedBy: z.string().max(120).nullable().optional(),
      }).parse(req.body);

      const rows = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `UPDATE "CollectedBusiness"
         SET "status" = $2::"CollectedRecordStatus",
             "reviewNote" = $3,
             "reviewedBy" = $4,
             "reviewedAt" = CASE
               WHEN $2 IN ('APPROVED', 'REJECTED', 'MERGED') THEN NOW()
               ELSE NULL
             END,
             "updatedAt" = NOW()
         WHERE "id" = $1
         RETURNING *`,
        req.params.id,
        input.status,
        input.reviewNote ?? null,
        input.reviewedBy ?? null,
      );

      if (!rows.length) return res.status(404).json({ message: 'السجل غير موجود' });
      res.json(rows[0]);
    } catch (error) {
      next(error);
    }
  });

  router.patch('/duplicates/:id', async (req, res, next) => {
    try {
      const input = z.object({
        resolution: z.enum(['MERGE_LEFT', 'MERGE_RIGHT', 'NOT_DUPLICATE']),
      }).parse(req.body);

      const rows = await prisma.$queryRawUnsafe<
        Array<{ id: string; leftId: string; rightId: string }>
      >(
        `UPDATE "DuplicateCandidate"
         SET "resolved" = TRUE, "resolution" = $2, "resolvedAt" = NOW()
         WHERE "id" = $1 AND "resolved" = FALSE
         RETURNING "id", "leftId", "rightId"`,
        req.params.id,
        input.resolution,
      );

      if (!rows.length) return res.status(404).json({ message: 'حالة التكرار غير موجودة أو تمت مراجعتها' });

      const duplicate = rows[0];
      if (input.resolution === 'MERGE_LEFT') {
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness" SET "status" = 'MERGED', "updatedAt" = NOW() WHERE "id" = $1`,
          duplicate.rightId,
        );
      } else if (input.resolution === 'MERGE_RIGHT') {
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness" SET "status" = 'MERGED', "updatedAt" = NOW() WHERE "id" = $1`,
          duplicate.leftId,
        );
      } else {
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness"
           SET "status" = 'NEW', "updatedAt" = NOW()
           WHERE "id" IN ($1, $2) AND "status" = 'NEEDS_REVIEW'`,
          duplicate.leftId,
          duplicate.rightId,
        );
      }

      res.json({ resolved: true, id: duplicate.id, resolution: input.resolution });
    } catch (error) {
      next(error);
    }
  });

  router.post('/jobs/manual', async (req, res, next) => {
    try {
      const input = z.object({
        sourceId: z.string().default('manual-csv'),
        category: z.string().nullable().optional(),
        area: z.string().nullable().optional(),
        query: z.string().nullable().optional(),
      }).parse(req.body);

      const id = randomUUID();
      const rows = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `INSERT INTO "CollectionJob"
          ("id", "sourceId", "category", "area", "query", "status")
         VALUES ($1, $2, $3, $4, $5, 'PENDING')
         RETURNING *`,
        id,
        input.sourceId,
        input.category ?? null,
        input.area ?? null,
        input.query ?? null,
      );

      res.status(201).json(rows[0]);
    } catch (error) {
      next(error);
    }
  });

  return router;
};
