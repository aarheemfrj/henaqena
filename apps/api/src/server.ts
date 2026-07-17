import 'dotenv/config';
import { createHash, randomBytes, randomInt, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';
import cors from 'cors';
import express from 'express';
import { PrismaClient, ReviewStatus, ListingStatus } from '@prisma/client';
import { z } from 'zod';

const prisma = new PrismaClient();
const app = express();
const port = Number(process.env.PORT ?? 4000);
const scrypt = promisify(scryptCallback);
const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const passwordHash = async (password: string) => `${randomBytes(16).toString('hex')}:${(await scrypt(password, 'hena-qena-password-salt', 64) as Buffer).toString('hex')}`;
const verifyPassword = async (password: string, stored: string) => stored.split(':')[1] === (await scrypt(password, 'hena-qena-password-salt', 64) as Buffer).toString('hex');
const issueSession = async (userId: string) => { const token = randomBytes(32).toString('hex'); await prisma.session.create({ data: { userId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } }); return token; };

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => res.json({ ok: true, service: 'hena-qena-api' }));

const registerSchema = z.object({ name: z.string().trim().min(2).max(80), phone: z.string().regex(/^01[0125][0-9]{8}$/), email: z.string().email().optional(), password: z.string().min(8).max(128) });
app.post('/api/auth/register', async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const user = await prisma.user.create({ data: { name: input.name, phone: input.phone, email: input.email, passwordHash: await passwordHash(input.password), authProvider: 'password' } });
    const token = await issueSession(user.id);
    res.status(201).json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: false, emailVerified: false } });
  } catch (error) { next(error); }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const input = z.object({ phone: z.string().regex(/^01[0125][0-9]{8}$/), password: z.string().min(1) }).parse(req.body);
    const user = await prisma.user.findUnique({ where: { phone: input.phone } });
    if (!user?.passwordHash || !(await verifyPassword(input.password, user.passwordHash))) return res.status(401).json({ message: 'رقم الهاتف أو كلمة المرور غير صحيحة' });
    const token = await issueSession(user.id);
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: Boolean(user.phoneVerifiedAt), emailVerified: Boolean(user.emailVerifiedAt) } });
  } catch (error) { next(error); }
});

const verificationSchema = z.object({ channel: z.enum(['whatsapp', 'sms', 'email']) });
app.post('/api/auth/verification/request', async (req, res, next) => {
  try {
    const input = verificationSchema.parse(req.body);
    const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : '';
    const session = await prisma.session.findUnique({ where: { tokenHash: hash(token) }, include: { user: true } });
    if (!session || session.expiresAt < new Date()) return res.status(401).json({ message: 'انتهت الجلسة' });
    const target = input.channel === 'email' ? session.user.email : session.user.phone;
    if (!target) return res.status(400).json({ message: 'أضف وسيلة التواصل أولاً' });
    const code = String(randomInt(100000, 1000000));
    await prisma.verificationCode.create({ data: { userId: session.userId, channel: input.channel, target, codeHash: hash(code), expiresAt: new Date(Date.now() + 10 * 60 * 1000) } });
    if (process.env.NODE_ENV !== 'production') console.log(`[verification:${input.channel}] ${target}: ${code}`);
    res.json({ sent: true, channel: input.channel, targetMasked: `${target.slice(0, 3)}***${target.slice(-2)}` });
  } catch (error) { next(error); }
});

app.post('/api/auth/verification/confirm', async (req, res, next) => {
  try {
    const input = verificationSchema.extend({ code: z.string().regex(/^\d{6}$/) }).parse(req.body);
    const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : '';
    const session = await prisma.session.findUnique({ where: { tokenHash: hash(token) } });
    if (!session || session.expiresAt < new Date()) return res.status(401).json({ message: 'انتهت الجلسة' });
    const record = await prisma.verificationCode.findFirst({ where: { userId: session.userId, channel: input.channel, codeHash: hash(input.code), consumedAt: null, expiresAt: { gt: new Date() } }, orderBy: { createdAt: 'desc' } });
    if (!record) return res.status(400).json({ message: 'رمز التأكيد غير صحيح أو منتهي' });
    await prisma.$transaction([prisma.verificationCode.update({ where: { id: record.id }, data: { consumedAt: new Date() } }), prisma.user.update({ where: { id: session.userId }, data: input.channel === 'email' ? { emailVerifiedAt: new Date() } : { phoneVerifiedAt: new Date() } })]);
    res.json({ verified: true, channel: input.channel });
  } catch (error) { next(error); }
});

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

const providerCreateSchema = z.object({ name: z.string().trim().min(2).max(120), description: z.string().trim().max(1000).optional(), phone: z.string().regex(/^01[0125][0-9]{8}$/).optional(), whatsapp: z.string().regex(/^01[0125][0-9]{8}$/).optional(), address: z.string().trim().max(240).optional(), areaId: z.string().min(1), categoryIds: z.array(z.string().min(1)).min(1).max(5), images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10) });
app.post('/api/providers', async (req, res, next) => {
  try {
    const input = providerCreateSchema.parse(req.body);
    const ownerId = typeof req.headers['x-user-id'] === 'string' ? req.headers['x-user-id'] : undefined;
    const provider = await prisma.provider.create({ data: { name: input.name, description: input.description, phone: input.phone, whatsapp: input.whatsapp, address: input.address, areaId: input.areaId, ownerId, status: ReviewStatus.PENDING, images: { create: input.images.map((image, index) => ({ url: image.url, kind: image.kind ?? 'work', sortOrder: index })) }, categories: { create: input.categoryIds.map((categoryId) => ({ categoryId })) } }, include: { area: true, images: true, categories: { include: { category: true } } } });
    res.status(201).json(provider);
  } catch (error) { next(error); }
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

const listingCreateSchema = z.object({ title: z.string().trim().min(3).max(120), description: z.string().trim().max(1200).optional(), price: z.number().positive().max(999999999), ownerId: z.string().min(1), areaId: z.string().min(1), images: z.array(z.string().url()).min(1).max(5) });
app.post('/api/listings', async (req, res, next) => {
  try {
    const input = listingCreateSchema.parse(req.body);
    const listing = await prisma.listing.create({ data: { title: input.title, description: input.description, price: input.price, ownerId: input.ownerId, areaId: input.areaId, status: ListingStatus.PENDING, images: { create: input.images.map((url, index) => ({ url, sortOrder: index })) } }, include: { area: true, images: true } });
    res.status(201).json(listing);
  } catch (error) { next(error); }
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

const adCreateSchema = z.object({ name: z.string().trim().min(2).max(120), imageUrl: z.string().url(), description: z.string().trim().max(600).optional(), targetUrl: z.string().url().optional(), weight: z.number().int().min(1).max(100).default(100), areaId: z.string().min(1).nullable().optional(), startsAt: z.coerce.date(), endsAt: z.coerce.date() });
app.post('/api/ads', async (req, res, next) => {
  try {
    const input = adCreateSchema.parse(req.body);
    if (input.endsAt <= input.startsAt) return res.status(400).json({ message: 'تاريخ الانتهاء يجب أن يكون بعد البداية' });
    const ad = await prisma.ad.create({ data: { ...input, areaId: input.areaId ?? null, status: ReviewStatus.PENDING } });
    res.status(201).json(ad);
  } catch (error) { next(error); }
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

app.post('/api/reviews/:id/replies', async (req, res, next) => {
  try {
    const input = z.object({ authorId: z.string().min(1), text: z.string().trim().min(1).max(1000) }).parse(req.body);
    const reply = await prisma.reviewReply.create({ data: { reviewId: req.params.id, authorId: input.authorId, text: input.text }, include: { author: true } });
    res.status(201).json(reply);
  } catch (error) { next(error); }
});

// Admin read/moderation endpoints. Authentication is added in the next security step.
app.get('/api/admin/overview', async (_req, res, next) => {
  try {
    const [providers, pending, listings, reviews] = await Promise.all([
      prisma.provider.count({ where: { status: ReviewStatus.APPROVED } }),
      Promise.all([prisma.review.count({ where: { status: ReviewStatus.PENDING } }), prisma.listing.count({ where: { status: ListingStatus.PENDING } })]).then(([reviewsPending, listingsPending]) => reviewsPending + listingsPending),
      prisma.ad.count({ where: { status: ReviewStatus.APPROVED } }),
      prisma.review.count({ where: { createdAt: { gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1) } } }),
    ]);
    res.json({ providers, pending, listings, reviews });
  } catch (error) { next(error); }
});

app.get('/api/admin/reviews', async (req, res, next) => {
  try {
    const status = typeof req.query.status === 'string' && Object.values(ReviewStatus).includes(req.query.status as ReviewStatus)
      ? req.query.status as ReviewStatus : undefined;
    const reviews = await prisma.review.findMany({ where: status ? { status } : {}, include: { author: true, provider: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(reviews);
  } catch (error) { next(error); }
});

app.get('/api/admin/providers', async (_req, res, next) => {
  try {
    const providers = await prisma.provider.findMany({ include: { area: true, categories: { include: { category: true } } }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(providers);
  } catch (error) { next(error); }
});

app.get('/api/admin/listings', async (_req, res, next) => {
  try {
    const listings = await prisma.listing.findMany({ include: { area: true, owner: true, images: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(listings);
  } catch (error) { next(error); }
});

app.get('/api/admin/ads', async (_req, res, next) => {
  try {
    const ads = await prisma.ad.findMany({ include: { area: true }, orderBy: [{ weight: 'desc' }, { createdAt: 'desc' }] });
    res.json(ads);
  } catch (error) { next(error); }
});

const moderationSchema = z.object({ status: z.enum([ReviewStatus.APPROVED, ReviewStatus.REJECTED]) });
app.patch('/api/admin/reviews/:id', async (req, res, next) => {
  try {
    const { status } = moderationSchema.parse(req.body);
    const review = await prisma.review.update({ where: { id: req.params.id }, data: { status } });
    res.json(review);
  } catch (error) { next(error); }
});

app.patch('/api/admin/listings/:id', async (req, res, next) => {
  try {
    const status = z.enum([ListingStatus.ACTIVE, ListingStatus.REJECTED, ListingStatus.ARCHIVED]).parse(req.body.status);
    const listing = await prisma.listing.update({ where: { id: req.params.id }, data: { status } });
    res.json(listing);
  } catch (error) { next(error); }
});

app.patch('/api/admin/ads/:id', async (req, res, next) => {
  try {
    const { status } = moderationSchema.parse(req.body);
    const ad = await prisma.ad.update({ where: { id: req.params.id }, data: { status } });
    res.json(ad);
  } catch (error) { next(error); }
});

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  if (error instanceof z.ZodError) return res.status(400).json({ message: 'Invalid request', issues: error.issues });
  console.error(error);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(port, () => console.log(`Hena Qena API listening on http://localhost:${port}`));
