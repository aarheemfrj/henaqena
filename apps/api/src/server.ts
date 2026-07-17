import 'dotenv/config';
import cors from 'cors';
import express from 'express';
import { PrismaClient, ReviewStatus } from '@prisma/client';
import { z } from 'zod';

const prisma = new PrismaClient();
const app = express();
const port = Number(process.env.PORT ?? 4000);

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'hena-qena-api' }));

app.get('/api/areas', async (_req, res, next) => {
  try {
    const areas = await prisma.area.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } });
    res.json(areas);
  } catch (error) {
    next(error);
  }
});

app.get('/api/providers', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const providers = await prisma.provider.findMany({
      where: {
        status: ReviewStatus.APPROVED,
        ...(areaId ? { areaId } : {}),
        ...(category ? { categories: { some: { category: { slug: category } } } } : {}),
      },
      include: { area: true, images: { orderBy: { sortOrder: 'asc' } }, categories: { include: { category: true } } },
      orderBy: [{ isVerified: 'desc' }, { name: 'asc' }],
    });
    res.json(providers);
  } catch (error) {
    next(error);
  }
});

app.get('/api/providers/:id', async (req, res, next) => {
  try {
    const provider = await prisma.provider.findUnique({
      where: { id: req.params.id },
      include: {
        area: true,
        images: { orderBy: { sortOrder: 'asc' } },
        categories: { include: { category: true } },
        reviews: { where: { status: ReviewStatus.APPROVED }, include: { author: true, replies: { include: { author: true } } }, orderBy: { createdAt: 'desc' } },
      },
    });
    if (!provider) return res.status(404).json({ message: 'Provider not found' });
    res.json(provider);
  } catch (error) {
    next(error);
  }
});

app.get('/api/listings', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const listings = await prisma.listing.findMany({ where: { status: 'ACTIVE', ...(areaId ? { areaId } : {}) }, include: { area: true, images: { orderBy: { sortOrder: 'asc' } } }, orderBy: { createdAt: 'desc' } });
    res.json(listings);
  } catch (error) {
    next(error);
  }
});

app.get('/api/ads', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const now = new Date();
    const ads = await prisma.ad.findMany({ where: { status: ReviewStatus.APPROVED, startsAt: { lte: now }, endsAt: { gte: now }, OR: [{ areaId: null }, ...(areaId ? [{ areaId }] : [])] }, orderBy: [{ weight: 'desc' }, { createdAt: 'desc' }] });
    res.json(ads);
  } catch (error) {
    next(error);
  }
});

const reviewSchema = z.object({ providerId: z.string().min(1), authorId: z.string().min(1), quality: z.number().int().min(1).max(5), commitment: z.number().int().min(1).max(5), value: z.number().int().min(1).max(5), comment: z.string().trim().max(1000).optional() });

app.post('/api/reviews', async (req, res, next) => {
  try {
    const input = reviewSchema.parse(req.body);
    const review = await prisma.review.create({ data: { ...input, status: ReviewStatus.PENDING } });
    res.status(201).json(review);
  } catch (error) {
    next(error);
  }
});

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  if (error instanceof z.ZodError) return res.status(400).json({ message: 'Invalid request', issues: error.issues });
  console.error(error);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(port, () => console.log(`Hena Qena API listening on http://localhost:${port}`));
