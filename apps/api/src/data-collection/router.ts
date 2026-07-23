import { randomUUID } from 'node:crypto';
import { readFile, unlink } from 'node:fs/promises';
import os from 'node:os';
import { Router, type Request, type Response, type NextFunction } from 'express';
import multer from 'multer';
import type { PrismaClient } from '@prisma/client';
import { z } from 'zod';
import { runCsvImportForJob } from './import-runner';
import { isGoogleMapsConfigured } from './google-maps-provider';
import { runGoogleMapsJob } from './google-maps-job-runner';
import { runOsmJob } from './osm-job-runner';
import { isSafeExternalUrl } from './social-enrichment';

const RUNNABLE_SOURCES = new Set(['google-maps', 'osm']);

const defaultDataSources = [
  { id: 'manual-csv', name: 'Manual CSV Import', kind: 'CSV', isActive: true },
  { id: 'google-maps', name: 'Google Maps', kind: 'MAPS', isActive: false },
  { id: 'facebook', name: 'Facebook', kind: 'SOCIAL', isActive: false },
  { id: 'instagram', name: 'Instagram', kind: 'SOCIAL', isActive: false },
  { id: 'tiktok', name: 'TikTok', kind: 'SOCIAL', isActive: false },
] as const;

// Production uses `prisma db push`, which creates the table but does not run
// INSERT statements from the migration. Keep the source catalog self-healing
// so a fresh deployment never renders an empty source selector.
const ensureDefaultDataSources = async (prisma: PrismaClient) => {
  for (const source of defaultDataSources) {
    await prisma.$executeRawUnsafe(
      `INSERT INTO "DataSource" ("id", "name", "kind", "isActive")
       VALUES ($1, $2, $3, $4)
       ON CONFLICT ("id") DO UPDATE
       SET "name" = EXCLUDED."name", "kind" = EXCLUDED."kind", "isActive" = EXCLUDED."isActive", "updatedAt" = NOW()`,
      source.id,
      source.name,
      source.kind,
      source.isActive,
    );
  }
};

const csvUpload = multer({
  dest: os.tmpdir(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, callback) => {
    const isCsv = file.originalname.toLowerCase().endsWith('.csv')
      || file.mimetype === 'text/csv'
      || file.mimetype === 'application/vnd.ms-excel';
    if (!isCsv) return callback(new Error('CSV_ONLY'));
    callback(null, true);
  },
});

export const createDataCollectionRouter = (prisma: PrismaClient): Router => {
  const router = Router();

  router.get('/sources', async (_req, res, next) => {
    try {
      await ensureDefaultDataSources(prisma);
      const sources = await prisma.$queryRawUnsafe<Array<{ id: string; name: string; kind: string; isActive: boolean }>>(
        `SELECT "id", "name", "kind", "isActive" FROM "DataSource" ORDER BY "name" ASC`,
      );
      // google-maps' real activation depends on env configuration, not the stored flag —
      // this keeps it honest even if the seeded DataSource row says isActive=true.
      const items = sources.map((source) => (
        source.id === 'google-maps' ? { ...source, isActive: isGoogleMapsConfigured() } : source
      ));
      res.json({ items });
    } catch (error) {
      next(error);
    }
  });

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

  const sortColumns = {
    quality: '"qualityScore"',
    newest: '"createdAt"',
    oldest: '"createdAt"',
    name: '"name"',
  } as const;

  const defaultSortDirection: Record<keyof typeof sortColumns, 'ASC' | 'DESC'> = {
    quality: 'DESC',
    newest: 'DESC',
    oldest: 'ASC',
    name: 'ASC',
  };

  router.get('/records', async (req, res, next) => {
    try {
      const input = z.object({
        status: z.enum(['NEW', 'NEEDS_REVIEW', 'APPROVED', 'REJECTED', 'MERGED']).optional(),
        search: z.string().max(120).optional(),
        category: z.string().max(120).optional(),
        area: z.string().max(120).optional(),
        sourceId: z.string().max(120).optional(),
        sortBy: z.enum(['quality', 'newest', 'oldest', 'name']).default('quality'),
        sortDirection: z.enum(['asc', 'desc']).optional(),
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
      if (input.category) conditions.push(`"category" = ${addParam(input.category)}`);
      if (input.area) conditions.push(`"area" = ${addParam(input.area)}`);
      if (input.sourceId) conditions.push(`"sourceId" = ${addParam(input.sourceId)}`);
      if (input.search) {
        const token = addParam(input.search);
        conditions.push(`(
          "name" ILIKE '%' || ${token} || '%'
          OR COALESCE("phone", '') ILIKE '%' || ${token} || '%'
          OR COALESCE("address", '') ILIKE '%' || ${token} || '%'
        )`);
      }

      const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

      // sortBy/sortDirection are only ever read from the fixed maps above — never interpolated from user input directly.
      const sortColumn = sortColumns[input.sortBy];
      const sortDirection = (input.sortDirection?.toUpperCase() as 'ASC' | 'DESC' | undefined) ?? defaultSortDirection[input.sortBy];
      const tiebreaker = sortColumn === '"createdAt"' ? '' : ', "createdAt" DESC';
      const orderBy = `ORDER BY ${sortColumn} ${sortDirection}${tiebreaker}`;

      const countRows = await prisma.$queryRawUnsafe<Array<{ count: bigint }>>(
        `SELECT COUNT(*)::bigint AS count FROM "CollectedBusiness" ${where}`,
        ...params,
      );
      const total = Number(countRows[0]?.count ?? 0);

      const limitParam = addParam(input.limit);
      const offsetParam = addParam(input.offset);

      const records = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT *
         FROM "CollectedBusiness"
         ${where}
         ${orderBy}
         LIMIT ${limitParam} OFFSET ${offsetParam}`,
        ...params,
      );

      res.json({
        items: records,
        pagination: {
          total,
          limit: input.limit,
          offset: input.offset,
          hasMore: input.offset + records.length < total,
        },
      });
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

  router.post('/jobs', async (req, res, next) => {
    try {
      await ensureDefaultDataSources(prisma);
      const input = z.object({
        sourceId: z.string().min(1, 'مصدر البيانات مطلوب'),
        category: z.string().min(1, 'الفئة مطلوبة'),
        area: z.string().min(1, 'المركز أو المنطقة مطلوب'),
        query: z.string().max(200).optional(),
        limit: z.coerce.number().int().min(1).max(500).default(50),
      }).parse(req.body);

      const sources = await prisma.$queryRawUnsafe<Array<{ id: string; name: string; isActive: boolean }>>(
        `SELECT "id", "name", "isActive" FROM "DataSource" WHERE "id" = $1`,
        input.sourceId,
      );
      const source = sources[0];
      if (!source) return res.status(404).json({ message: 'مصدر البيانات غير موجود' });
      // google-maps jobs are always creatable and stay PENDING — actual execution (and its
      // config check) happens separately at POST /jobs/:id/run, not at creation time.
      if (!source.isActive && source.id !== 'google-maps') {
        return res.status(400).json({ message: `مصدر البيانات "${source.name}" غير مفعّل حاليًا` });
      }

      const metadata = { limit: input.limit, requestedFromAdmin: true };

      const rows = await prisma.$queryRawUnsafe<Array<{
        id: string; sourceId: string; category: string | null; area: string | null; query: string | null; status: string; metadata: unknown;
      }>>(
        `INSERT INTO "CollectionJob"
          ("id", "sourceId", "category", "area", "query", "status", "metadata")
         VALUES ($1, $2, $3, $4, $5, 'PENDING', $6::jsonb)
         RETURNING "id", "sourceId", "category", "area", "query", "status", "metadata"`,
        randomUUID(),
        input.sourceId,
        input.category,
        input.area,
        input.query ?? null,
        JSON.stringify(metadata),
      );

      res.status(201).json({ job: rows[0] });
    } catch (error) {
      next(error);
    }
  });

  const handleCsvUpload = (req: Request, res: Response, next: NextFunction) => {
    csvUpload.single('file')(req, res, (error: unknown) => {
      if (!error) return next();
      if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
        return res.status(400).json({ message: 'الحد الأقصى لحجم الملف 5MB' });
      }
      if (error instanceof Error && error.message === 'CSV_ONLY') {
        return res.status(400).json({ message: 'يُسمح فقط بملفات CSV' });
      }
      next(error);
    });
  };

  router.post('/jobs/:id/import-csv', handleCsvUpload, async (req, res, next) => {
    const file = req.file;
    try {
      const jobs = await prisma.$queryRawUnsafe<Array<{ id: string; sourceId: string | null; category: string | null; area: string | null; status: string }>>(
        `SELECT "id", "sourceId", "category", "area", "status" FROM "CollectionJob" WHERE "id" = $1`,
        req.params.id,
      );
      const job = jobs[0];
      if (!job) return res.status(404).json({ message: 'مهمة التجميع غير موجودة' });
      if (job.status === 'COMPLETED' || job.status === 'CANCELLED') {
        return res.status(400).json({ message: 'لا يمكن رفع ملف لمهمة مكتملة أو ملغاة' });
      }
      if (!file) return res.status(400).json({ message: 'ملف CSV مطلوب' });

      const csvContent = await readFile(file.path, 'utf8');
      const result = await runCsvImportForJob(prisma, {
        jobId: job.id,
        sourceId: job.sourceId ?? 'manual-csv',
        defaultCategory: job.category,
        defaultArea: job.area,
        csvContent,
      });

      res.json({ jobId: job.id, ...result });
    } catch (error) {
      next(error);
    } finally {
      if (file) await unlink(file.path).catch(() => undefined);
    }
  });

  router.post('/jobs/:id/run', async (req, res, next) => {
    try {
      const jobs = await prisma.$queryRawUnsafe<Array<{
        id: string; sourceId: string | null; category: string | null; area: string | null; query: string | null; status: string; metadata: unknown;
      }>>(
        `SELECT "id", "sourceId", "category", "area", "query", "status", "metadata" FROM "CollectionJob" WHERE "id" = $1`,
        req.params.id,
      );
      const job = jobs[0];
      if (!job) return res.status(404).json({ message: 'مهمة التجميع غير موجودة' });
      if (!job.sourceId || !RUNNABLE_SOURCES.has(job.sourceId)) {
        return res.status(400).json({ message: 'هذه المهمة ليست من مصدر يدعم التشغيل التلقائي' });
      }
      if (job.status === 'COMPLETED' || job.status === 'RUNNING') {
        return res.status(400).json({ message: job.status === 'RUNNING' ? 'المهمة قيد التشغيل بالفعل' : 'المهمة مكتملة بالفعل' });
      }
      if (job.sourceId === 'google-maps' && !isGoogleMapsConfigured()) {
        return res.status(400).json({ message: 'إعدادات Google Maps غير مكتملة (GOOGLE_MAPS_API_KEY / GOOGLE_MAPS_PROVIDER_ENABLED)' });
      }

      // Atomic PENDING -> RUNNING transition: the authoritative guard against running the same job twice in parallel.
      const claimed = await prisma.$queryRawUnsafe<Array<{ id: string }>>(
        `UPDATE "CollectionJob" SET "status" = 'RUNNING', "startedAt" = COALESCE("startedAt", NOW()), "updatedAt" = NOW()
         WHERE "id" = $1 AND "status" = 'PENDING'
         RETURNING "id"`,
        job.id,
      );
      if (!claimed.length) return res.status(409).json({ message: 'تعذر بدء التشغيل — قد تكون المهمة بدأت للتو من مكان آخر' });

      res.status(202).json({ jobId: job.id, status: 'RUNNING' });

      // Runs detached from the HTTP request/response cycle — see the source-specific
      // job runner modules for the documented limitations of this single-process worker.
      if (job.sourceId === 'google-maps') void runGoogleMapsJob(prisma, job);
      else void runOsmJob(prisma, job);
    } catch (error) {
      next(error);
    }
  });

  router.patch('/records/:id/social-links', async (req, res, next) => {
    try {
      const input = z.object({
        platform: z.enum(['facebook', 'instagram', 'tiktok']),
        action: z.enum(['approve', 'reject', 'edit']),
        url: z.string().max(500).optional(),
      }).parse(req.body);

      const rows = await prisma.$queryRawUnsafe<Array<{ id: string; socialEnrichment: unknown; socialCandidates: unknown }>>(
        `SELECT "id", "socialEnrichment", "socialCandidates" FROM "CollectedBusiness" WHERE "id" = $1`,
        req.params.id,
      );
      const record = rows[0];
      if (!record) return res.status(404).json({ message: 'السجل غير موجود' });

      const candidates = (record.socialCandidates as Record<string, { url: string; confidence: number; evidence: string[]; source: string }>) ?? {};
      const enrichment = (record.socialEnrichment as Record<string, unknown>) ?? {};
      const candidate = candidates[input.platform];

      if (input.action === 'edit') {
        if (!input.url) return res.status(400).json({ message: 'الرابط مطلوب' });
        const hostsByPlatform: Record<string, string[]> = {
          facebook: ['facebook.com', 'm.facebook.com', 'fb.com', 'fb.watch'],
          instagram: ['instagram.com', 'instagr.am'],
          tiktok: ['tiktok.com', 'vm.tiktok.com'],
        };
        if (!isSafeExternalUrl(input.url, hostsByPlatform[input.platform])) {
          return res.status(400).json({ message: 'الرابط لا يطابق نطاق المنصة المتوقع' });
        }
        const nextEnrichment = { ...enrichment, [input.platform]: { url: input.url, confidence: 1, evidence: ['manual_review'], source: 'manual' } };
        const nextCandidates = { ...candidates };
        delete nextCandidates[input.platform];
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness" SET "${input.platform}" = $2, "socialEnrichment" = $3::jsonb, "socialCandidates" = $4::jsonb, "updatedAt" = NOW() WHERE "id" = $1`,
          record.id, input.url, JSON.stringify(nextEnrichment), JSON.stringify(nextCandidates),
        );
      } else if (input.action === 'approve') {
        if (!candidate) return res.status(404).json({ message: 'لا يوجد رابط مقترح لهذه المنصة' });
        const nextEnrichment = { ...enrichment, [input.platform]: candidate };
        const nextCandidates = { ...candidates };
        delete nextCandidates[input.platform];
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness" SET "${input.platform}" = $2, "socialEnrichment" = $3::jsonb, "socialCandidates" = $4::jsonb, "updatedAt" = NOW() WHERE "id" = $1`,
          record.id, candidate.url, JSON.stringify(nextEnrichment), JSON.stringify(nextCandidates),
        );
      } else {
        const nextCandidates = { ...candidates };
        delete nextCandidates[input.platform];
        await prisma.$executeRawUnsafe(
          `UPDATE "CollectedBusiness" SET "socialCandidates" = $2::jsonb, "updatedAt" = NOW() WHERE "id" = $1`,
          record.id, JSON.stringify(nextCandidates),
        );
      }

      const updated = await prisma.$queryRawUnsafe<Array<Record<string, unknown>>>(
        `SELECT * FROM "CollectedBusiness" WHERE "id" = $1`,
        record.id,
      );
      res.json(updated[0]);
    } catch (error) {
      next(error);
    }
  });

  router.post('/jobs/manual', async (req, res, next) => {
    try {
      await ensureDefaultDataSources(prisma);
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
