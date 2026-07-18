import 'dotenv/config';
import { createHash, randomBytes, randomInt, scrypt as scryptCallback } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { promisify } from 'node:util';
import cors from 'cors';
import express from 'express';
import { PrismaClient, ReviewStatus, ListingStatus } from '@prisma/client';
import { z } from 'zod';

type RateLimitStore = Map<string, { count: number; resetAt: number }>;
const createRateLimiter = (maxRequests: number, windowMs: number) => {
  const store: RateLimitStore = new Map();
  return (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const key = req.ip || 'unknown';
    const now = Date.now();
    const record = store.get(key) || { count: 0, resetAt: now + windowMs };
    if (now > record.resetAt) { record.count = 0; record.resetAt = now + windowMs; }
    record.count++;
    store.set(key, record);
    res.set('X-RateLimit-Limit', String(maxRequests));
    res.set('X-RateLimit-Remaining', String(Math.max(0, maxRequests - record.count)));
    if (record.count > maxRequests) return res.status(429).json({ message: 'عدد المحاولات زائد - حاول لاحقاً' });
    next();
  };
};

const prisma = new PrismaClient();
const app = express();
const port = Number(process.env.PORT ?? 4000);
const uploadRoot = process.env.UPLOADS_DIR ?? path.join(process.cwd(), 'uploads');
const publicApiBaseUrl = (process.env.PUBLIC_API_BASE_URL ?? `http://127.0.0.1:${port}`).replace(/\/$/, '');
const scrypt = promisify(scryptCallback);
const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const passwordHash = async (password: string) => { const salt = randomBytes(16); const derived = await scrypt(password, salt, 64) as Buffer; return `${salt.toString('hex')}:${derived.toString('hex')}`; };
const verifyPassword = async (password: string, stored: string) => { const [saltHex, storedHash] = stored.split(':'); const salt = Buffer.from(saltHex, 'hex'); const derived = await scrypt(password, salt, 64) as Buffer; return derived.toString('hex') === storedHash; };
const issueSession = async (userId: string) => { const token = randomBytes(32).toString('hex'); await prisma.session.create({ data: { userId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } }); return token; };
const sessionFromRequest = async (req: express.Request) => { const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : ''; if (!token) return null; const session = await prisma.session.findUnique({ where: { tokenHash: hash(token) }, include: { user: true } }); return session && session.expiresAt > new Date() ? session : null; };
const requireAdmin = (req: express.Request, res: express.Response, next: express.NextFunction) => { const expected = process.env.ADMIN_API_KEY ?? (process.env.NODE_ENV !== 'production' ? 'dev-henaqena-admin' : undefined); const provided = typeof req.headers['x-admin-key'] === 'string' ? req.headers['x-admin-key'] : ''; if (!expected || provided !== expected) return res.status(403).json({ message: 'صلاحيات الإدارة مطلوبة' }); next(); };
const audit = (action: string, entity: string, entityId: string, metadata?: Record<string, unknown>) => prisma.auditLog.create({ data: { action, entity, entityId, metadata: metadata as any } });
const publicAuthorSelect = { id: true, name: true, avatarUrl: true, isProfilePrivate: true, points: true, level: true } as const;

const allowedOrigins = (process.env.CORS_ORIGINS ?? '*').split(',').map((origin) => origin.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.includes('*') ? true : allowedOrigins }));
app.use(express.json({ limit: '16mb' }));
app.use('/uploads', express.static(uploadRoot, { maxAge: '7d', etag: true }));

const authLimiter = createRateLimiter(5, 15 * 60 * 1000); // 5 attempts per 15 minutes
const verificationLimiter = createRateLimiter(10, 60 * 60 * 1000); // 10 attempts per hour

app.get('/health', (_req, res) => res.json({ ok: true, service: 'hena-qena-api' }));
app.get('/ready', async (_req, res) => {
  try { await prisma.$queryRaw`SELECT 1`; res.json({ ok: true, database: 'ready' }); } catch { res.status(503).json({ ok: false, database: 'unavailable' }); }
});

app.get('/api/me', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); const { passwordHash, ...user } = session.user; res.json(user); } catch (error) { next(error); }
});

app.patch('/api/me/preferences', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = z.object({ preferredAreaIds: z.array(z.string()).max(3).optional(), interests: z.array(z.string()).max(5).optional(), notificationScope: z.enum(['all', 'area']).optional(), notificationDigest: z.boolean().optional(), isProfilePrivate: z.boolean().optional() }).parse(req.body);
    const user = await prisma.user.update({ where: { id: session.userId }, data: input });
    res.json({ preferredAreaIds: user.preferredAreaIds, interests: user.interests, notificationScope: user.notificationScope, notificationDigest: user.notificationDigest });
  } catch (error) { next(error); }
});

app.post('/api/auth/logout', async (req, res, next) => {
  try {
    const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : '';
    if (token) await prisma.session.deleteMany({ where: { tokenHash: hash(token) } });
    res.json({ loggedOut: true });
  } catch (error) { next(error); }
});

app.post('/api/auth/logout-all', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); await prisma.session.deleteMany({ where: { userId: session.userId } }); res.json({ loggedOut: true }); } catch (error) { next(error); }
});

app.patch('/api/me/password', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = z.object({ currentPassword: z.string().min(1), newPassword: z.string().min(8).max(128) }).parse(req.body);
    if (!session.user.passwordHash || !(await verifyPassword(input.currentPassword, session.user.passwordHash))) return res.status(400).json({ message: 'كلمة المرور الحالية غير صحيحة' });
    await prisma.user.update({ where: { id: session.userId }, data: { passwordHash: await passwordHash(input.newPassword) } });
    await prisma.session.deleteMany({ where: { userId: session.userId, NOT: { id: session.id } } });
    res.json({ changed: true });
  } catch (error) { next(error); }
});

app.delete('/api/me', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    await prisma.$transaction(async (tx) => {
      await tx.reviewReply.deleteMany({ where: { authorId: session.userId } });
      await tx.review.deleteMany({ where: { authorId: session.userId } });
      const listings = await tx.listing.findMany({ where: { ownerId: session.userId }, select: { id: true } });
      if (listings.length) { await tx.listingImage.deleteMany({ where: { listingId: { in: listings.map((item) => item.id) } } }); await tx.listing.deleteMany({ where: { ownerId: session.userId } }); }
      await tx.provider.updateMany({ where: { ownerId: session.userId }, data: { ownerId: null } });
      await tx.notification.deleteMany({ where: { userId: session.userId } });
      await tx.verificationCode.deleteMany({ where: { userId: session.userId } });
      await tx.session.deleteMany({ where: { userId: session.userId } });
      await tx.auditLog.updateMany({ where: { actorId: session.userId }, data: { actorId: null } });
      await tx.user.delete({ where: { id: session.userId } });
    });
    res.json({ deleted: true });
  } catch (error) { next(error); }
});

app.get('/api/notifications', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); const notifications = await prisma.notification.findMany({ where: { userId: session.userId }, orderBy: { createdAt: 'desc' }, take: 50 }); res.json(notifications); } catch (error) { next(error); }
});

app.patch('/api/notifications/:id/read', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); const notification = await prisma.notification.updateMany({ where: { id: req.params.id, userId: session.userId }, data: { readAt: new Date() } }); res.json({ updated: notification.count === 1 }); } catch (error) { next(error); }
});

app.post('/api/notifications/read-all', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); const result = await prisma.notification.updateMany({ where: { userId: session.userId, readAt: null }, data: { readAt: new Date() } }); res.json({ updated: result.count }); } catch (error) { next(error); }
});

const registerSchema = z.object({ name: z.string().trim().min(2).max(80), phone: z.string().regex(/^01[0125][0-9]{8}$/), email: z.string().email().optional(), password: z.string().min(8).max(128) });
app.post('/api/auth/register', authLimiter, async (req, res, next) => {
  try {
    const input = registerSchema.parse(req.body);
    const user = await prisma.user.create({ data: { name: input.name, phone: input.phone, email: input.email, passwordHash: await passwordHash(input.password), authProvider: 'password' } });
    const token = await issueSession(user.id);
    res.status(201).json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: false, emailVerified: false } });
  } catch (error) { next(error); }
});

app.post('/api/auth/login', authLimiter, async (req, res, next) => {
  try {
    const input = z.object({ phone: z.string().regex(/^01[0125][0-9]{8}$/), password: z.string().min(1) }).parse(req.body);
    const user = await prisma.user.findUnique({ where: { phone: input.phone } });
    if (!user?.passwordHash || !(await verifyPassword(input.password, user.passwordHash))) return res.status(401).json({ message: 'رقم الهاتف أو كلمة المرور غير صحيحة' });
    const token = await issueSession(user.id);
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: Boolean(user.phoneVerifiedAt), emailVerified: Boolean(user.emailVerifiedAt) } });
  } catch (error) { next(error); }
});

const verificationSchema = z.object({ channel: z.enum(['whatsapp', 'sms', 'email']) });
app.post('/api/auth/verification/request', verificationLimiter, async (req, res, next) => {
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

app.post('/api/auth/verification/confirm', verificationLimiter, async (req, res, next) => {
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

app.post('/api/auth/password-reset/request', verificationLimiter, async (req, res, next) => {
  try {
    const input = z.object({ identifier: z.string().trim().min(3), channel: z.enum(['whatsapp', 'sms', 'email']) }).parse(req.body);
    const user = input.channel === 'email' ? await prisma.user.findUnique({ where: { email: input.identifier } }) : await prisma.user.findUnique({ where: { phone: input.identifier } });
    // Always return the same response to avoid leaking whether an account exists.
    if (user) { const code = String(randomInt(100000, 1000000)); await prisma.verificationCode.create({ data: { userId: user.id, channel: `reset_${input.channel}`, target: input.identifier, codeHash: hash(code), expiresAt: new Date(Date.now() + 10 * 60 * 1000) } }); if (process.env.NODE_ENV !== 'production') console.log(`[password-reset:${input.channel}] ${input.identifier}: ${code}`); }
    res.json({ sent: true, channel: input.channel });
  } catch (error) { next(error); }
});

app.post('/api/auth/password-reset/confirm', verificationLimiter, async (req, res, next) => {
  try {
    const input = z.object({ identifier: z.string().trim().min(3), channel: z.enum(['whatsapp', 'sms', 'email']), code: z.string().regex(/^\d{6}$/), newPassword: z.string().min(8).max(128) }).parse(req.body);
    const user = input.channel === 'email' ? await prisma.user.findUnique({ where: { email: input.identifier } }) : await prisma.user.findUnique({ where: { phone: input.identifier } });
    if (!user) return res.status(400).json({ message: 'رمز التأكيد غير صحيح أو منتهي' });
    const record = await prisma.verificationCode.findFirst({ where: { userId: user.id, channel: `reset_${input.channel}`, codeHash: hash(input.code), consumedAt: null, expiresAt: { gt: new Date() } }, orderBy: { createdAt: 'desc' } });
    if (!record) return res.status(400).json({ message: 'رمز التأكيد غير صحيح أو منتهي' });
    await prisma.$transaction([prisma.verificationCode.update({ where: { id: record.id }, data: { consumedAt: new Date() } }), prisma.user.update({ where: { id: user.id }, data: { passwordHash: await passwordHash(input.newPassword) } }), prisma.session.deleteMany({ where: { userId: user.id } })]);
    res.json({ reset: true });
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

app.get('/api/categories', async (_req, res, next) => {
  try { res.json(await prisma.category.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } })); } catch (error) { next(error); }
});

app.get('/api/providers', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const q = typeof req.query.q === 'string' ? req.query.q.trim() : undefined;
    const page = Math.max(1, Number(req.query.page ?? 1));
    const pageSize = Math.min(50, Math.max(1, Number(req.query.pageSize ?? 20)));
    const providers = await prisma.provider.findMany({
      where: {
        status: ReviewStatus.APPROVED,
        ...(areaId ? { areaId } : {}),
        ...(category ? { categories: { some: { category: { slug: category } } } } : {}),
        ...(q ? { OR: [{ name: { contains: q, mode: 'insensitive' } }, { description: { contains: q, mode: 'insensitive' } }, { address: { contains: q, mode: 'insensitive' } }, { categories: { some: { category: { name: { contains: q, mode: 'insensitive' } } } } }] } : {}),
      },
      include: { area: true, images: { orderBy: { sortOrder: 'asc' } }, categories: { include: { category: true } } },
      orderBy: [{ isVerified: 'desc' }, { name: 'asc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
    res.json(providers);
  } catch (error) {
    next(error);
  }
});

const uploadedImageSchema = z.object({
  base64: z.string().min(32),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']),
});

app.post('/api/uploads/provider-images', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لرفع الصور' });
    const input = z.object({ images: z.array(uploadedImageSchema).min(1).max(10) }).parse(req.body);
    const folder = path.join(uploadRoot, 'providers');
    await mkdir(folder, { recursive: true });
    const images = await Promise.all(input.images.map(async (image) => {
      const bytes = Buffer.from(image.base64, 'base64');
      if (bytes.length === 0 || bytes.length > 2 * 1024 * 1024) throw new Error('حجم الصورة يجب ألا يزيد عن 2 ميجابايت');
      const extension = image.mimeType === 'image/png' ? 'png' : image.mimeType === 'image/webp' ? 'webp' : 'jpg';
      const filename = `${Date.now()}-${randomBytes(10).toString('hex')}.${extension}`;
      await writeFile(path.join(folder, filename), bytes, { flag: 'wx' });
      return { url: `${publicApiBaseUrl}/uploads/providers/${filename}`, kind: 'work' };
    }));
    res.status(201).json({ images });
  } catch (error) { next(error); }
});

const providerCreateSchema = z.object({ name: z.string().trim().min(2).max(120), description: z.string().trim().max(1000).optional(), phone: z.string().regex(/^01[0125][0-9]{8}$/).optional(), whatsapp: z.string().regex(/^01[0125][0-9]{8}$/).optional(), phoneType: z.enum(['BUSINESS', 'PERSONAL']).default('BUSINESS'), address: z.string().trim().max(240).optional(), areaId: z.string().min(1), serviceMode: z.enum(['LOCAL', 'ONLINE']).default('LOCAL'), openingTime: z.string().max(10).optional(), closingTime: z.string().max(10).optional(), categoryIds: z.array(z.string().min(1)).min(1).max(5), images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10) });
app.post('/api/providers', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لإضافة نشاط' });
    const input = providerCreateSchema.parse(req.body);
    const duplicate = await prisma.provider.findFirst({ where: { areaId: input.areaId, status: { not: ReviewStatus.REJECTED }, OR: [{ name: { equals: input.name, mode: 'insensitive' } }, ...(input.phone ? [{ phone: input.phone }] : [])] } });
    if (duplicate) return res.status(409).json({ message: 'يوجد نشاط مشابه بالفعل في هذه المنطقة' });
    const provider = await prisma.provider.create({ data: { name: input.name, description: input.description, phone: input.phone, whatsapp: input.whatsapp, phoneType: input.phoneType, address: input.address, areaId: input.areaId, serviceMode: input.serviceMode, openingTime: input.openingTime, closingTime: input.closingTime, ownerId: session.userId, communityAdded: true, status: ReviewStatus.PENDING, images: { create: input.images.map((image, index) => ({ url: image.url, kind: image.kind ?? 'work', sortOrder: index })) }, categories: { create: input.categoryIds.map((categoryId) => ({ categoryId })) } }, include: { area: true, images: true, categories: { include: { category: true } } } });
    res.status(201).json(provider);
  } catch (error) { next(error); }
});

const providerEditSchema = providerCreateSchema.partial().omit({ categoryIds: true, images: true }).extend({ categoryIds: z.array(z.string().min(1)).min(1).max(5).optional(), images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10).optional() });
app.patch('/api/providers/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لتعديل النشاط' });
    const input = providerEditSchema.parse(req.body);
    const existing = await prisma.provider.findUnique({ where: { id: String(req.params.id) } });
    if (!existing) return res.status(404).json({ message: 'النشاط غير موجود' });
    if (existing.ownerId !== session.userId) return res.status(403).json({ message: 'لا تملك صلاحية تعديل النشاط' });
    const { categoryIds, images, ...fields } = input;
    const provider = await prisma.$transaction(async (tx) => {
      if (images) await tx.providerImage.deleteMany({ where: { providerId: existing.id } });
      if (categoryIds) await tx.providerCategory.deleteMany({ where: { providerId: existing.id } });
      return tx.provider.update({ where: { id: existing.id }, data: { ...fields, status: ReviewStatus.PENDING, isVerified: false, ...(images ? { images: { create: images.map((image, index) => ({ url: image.url, kind: image.kind ?? 'work', sortOrder: index })) } } : {}), ...(categoryIds ? { categories: { create: categoryIds.map((categoryId) => ({ categoryId })) } } : {}) }, include: { area: true, images: true, categories: { include: { category: true } } } });
    });
    res.json(provider);
  } catch (error) { next(error); }
});

app.post('/api/provider-reports', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لإرسال طلب' });
    const input = z.object({ kind: z.enum(['CLAIM', 'REPORT']), name: z.string().trim().min(2).max(120), phone: z.string().regex(/^01[0125][0-9]{8}$/).optional(), note: z.string().trim().max(1000).optional(), providerId: z.string().optional() }).parse(req.body);
    const report = await prisma.providerReport.create({ data: { ...input, reporterId: session.userId, status: ReviewStatus.PENDING } });
    res.status(201).json({ id: report.id, status: report.status, message: input.kind === 'CLAIM' ? 'تم إرسال طلب إثبات ملكية النشاط' : 'تم إرسال بلاغ النشاط للمراجعة' });
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
        reviews: { where: { status: ReviewStatus.APPROVED }, include: { author: { select: publicAuthorSelect }, replies: { include: { author: { select: publicAuthorSelect } } } }, orderBy: { createdAt: 'desc' } },
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

const listingCreateSchema = z.object({ title: z.string().trim().min(3).max(120), description: z.string().trim().max(1200).optional(), price: z.number().positive().max(999999999), areaId: z.string().min(1), images: z.array(z.string().url()).min(1).max(5) });
app.post('/api/listings', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لإضافة إعلان' });
    const input = listingCreateSchema.parse(req.body);
    const listing = await prisma.listing.create({ data: { title: input.title, description: input.description, price: input.price, ownerId: session.userId, areaId: input.areaId, status: ListingStatus.PENDING, images: { create: input.images.map((url, index) => ({ url, sortOrder: index })) } }, include: { area: true, images: true } });
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
app.post('/api/ads', requireAdmin, async (req, res, next) => {
  try {
    const input = adCreateSchema.parse(req.body);
    if (input.endsAt <= input.startsAt) return res.status(400).json({ message: 'تاريخ الانتهاء يجب أن يكون بعد البداية' });
    const ad = await prisma.ad.create({ data: { ...input, areaId: input.areaId ?? null, status: ReviewStatus.PENDING } });
    res.status(201).json(ad);
  } catch (error) { next(error); }
});

app.get('/api/prices', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const prices = await prisma.priceGuide.findMany({ where: { status: ReviewStatus.APPROVED, ...(category ? { category } : {}), ...(areaId ? { OR: [{ areaId: null }, { areaId }] } : {}) }, include: { area: true }, orderBy: { updatedAt: 'desc' }, take: 100 });
    res.json(prices);
  } catch (error) { next(error); }
});

const priceCreateSchema = z.object({ name: z.string().trim().min(2).max(120), category: z.string().trim().max(80).optional(), minPrice: z.number().nonnegative().max(999999999), maxPrice: z.number().nonnegative().max(999999999), unit: z.string().trim().max(40).optional(), sourceNote: z.string().trim().max(300).optional(), areaId: z.string().min(1).nullable().optional() }).refine((value) => value.maxPrice >= value.minPrice, { message: 'الحد الأقصى يجب أن يكون أكبر من أو يساوي الحد الأدنى' });
app.get('/api/admin/prices', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.priceGuide.findMany({ include: { area: true }, orderBy: { updatedAt: 'desc' } })); } catch (error) { next(error); }
});
app.post('/api/admin/prices', requireAdmin, async (req, res, next) => {
  try { const input = priceCreateSchema.parse(req.body); const price = await prisma.priceGuide.create({ data: { ...input, areaId: input.areaId ?? null, minPrice: input.minPrice, maxPrice: input.maxPrice, status: ReviewStatus.APPROVED } }); res.status(201).json(price); } catch (error) { next(error); }
});
app.patch('/api/admin/prices/:id', requireAdmin, async (req, res, next) => {
  try { const input = z.object({ status: moderationSchema.shape.status }).parse(req.body); res.json(await prisma.priceGuide.update({ where: { id: String(req.params.id) }, data: { status: input.status } })); } catch (error) { next(error); }
});

app.get('/api/now', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const now = new Date();
    const updates = await prisma.nowUpdate.findMany({ where: { status: ReviewStatus.APPROVED, startsAt: { lte: now }, ...(areaId ? { OR: [{ areaId: null }, { areaId }] } : {}), AND: [{ OR: [{ endsAt: null }, { endsAt: { gte: now } }] }] }, include: { area: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(updates);
  } catch (error) { next(error); }
});
const nowCreateSchema = z.object({ title: z.string().trim().min(2).max(120), body: z.string().trim().max(600).optional(), category: z.string().trim().max(80).default('عام'), areaId: z.string().min(1).nullable().optional(), startsAt: z.coerce.date().optional(), endsAt: z.coerce.date().nullable().optional() });
app.get('/api/admin/now', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.nowUpdate.findMany({ include: { area: true }, orderBy: { createdAt: 'desc' } })); } catch (error) { next(error); }
});
app.post('/api/admin/now', requireAdmin, async (req, res, next) => {
  try { const input = nowCreateSchema.parse(req.body); const update = await prisma.nowUpdate.create({ data: { ...input, areaId: input.areaId ?? null, startsAt: input.startsAt ?? new Date(), status: ReviewStatus.APPROVED } }); res.status(201).json(update); } catch (error) { next(error); }
});
app.patch('/api/admin/now/:id', requireAdmin, async (req, res, next) => {
  try { const input = z.object({ status: moderationSchema.shape.status }).parse(req.body); res.json(await prisma.nowUpdate.update({ where: { id: String(req.params.id) }, data: { status: input.status } })); } catch (error) { next(error); }
});

const reviewSchema = z.object({ providerId: z.string().min(1), quality: z.number().int().min(1).max(5), commitment: z.number().int().min(1).max(5), value: z.number().int().min(1).max(5), comment: z.string().trim().max(1000).optional() });

app.post('/api/reviews', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = reviewSchema.parse(req.body);
    const existing = await prisma.review.findFirst({ where: { providerId: input.providerId, authorId: session.userId } });
    if (existing) return res.status(409).json({ message: 'سبق لك تقييم هذا المكان' });
    const review = await prisma.$transaction(async (tx) => {
      const author = await tx.user.findUniqueOrThrow({ where: { id: session.userId }, select: { points: true } });
      const points = author.points + 1;
      const level = points >= 100 ? 'QENAWY_ASIL' : points >= 50 ? 'QENAWY_RAYEQ' : 'QENAWY';
      await tx.user.update({ where: { id: session.userId }, data: { points, level } });
      return tx.review.create({ data: { ...input, authorId: session.userId, status: ReviewStatus.APPROVED } });
    });
    res.status(201).json(review);
  } catch (error) {
    next(error);
  }
});

app.post('/api/reviews/:id/replies', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = z.object({ text: z.string().trim().min(1).max(1000) }).parse(req.body);
    const reply = await prisma.reviewReply.create({ data: { reviewId: req.params.id, authorId: session.userId, text: input.text }, include: { author: { select: publicAuthorSelect } } });
    res.status(201).json(reply);
  } catch (error) { next(error); }
});

// Admin read/moderation endpoints. Authentication is added in the next security step.
app.get('/api/admin/overview', requireAdmin, async (_req, res, next) => {
  try {
    const [providers, unreadReviews, unreadReplies, listingsPending, listings, reviews] = await Promise.all([
      prisma.provider.count({ where: { status: ReviewStatus.APPROVED } }),
      prisma.review.count({ where: { moderatedAt: null } }),
      prisma.reviewReply.count({ where: { moderatedAt: null } }),
      prisma.listing.count({ where: { status: ListingStatus.PENDING } }),
      prisma.ad.count({ where: { status: ReviewStatus.APPROVED } }),
      prisma.review.count({ where: { createdAt: { gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1) } } }),
    ]);
    res.json({ providers, pending: unreadReviews + unreadReplies + listingsPending, reviewActivity: unreadReviews + unreadReplies, listings, reviews });
  } catch (error) { next(error); }
});

app.get('/api/admin/team', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.adminAccount.findMany({ select: { id: true, name: true, email: true, role: true, isActive: true, lastLoginAt: true, createdAt: true }, orderBy: { createdAt: 'desc' } })); } catch (error) { next(error); }
});
const adminAccountSchema = z.object({ name: z.string().trim().min(2).max(80), email: z.string().email(), password: z.string().min(10).max(128), role: z.enum(['OWNER', 'REVIEWER', 'CONTENT_EDITOR', 'MODERATOR']).default('REVIEWER') });
app.post('/api/admin/team', requireAdmin, async (req, res, next) => {
  try { const input = adminAccountSchema.parse(req.body); const member = await prisma.adminAccount.create({ data: { name: input.name, email: input.email.toLowerCase(), passwordHash: await passwordHash(input.password), role: input.role } }); res.status(201).json({ id: member.id, name: member.name, email: member.email, role: member.role, isActive: member.isActive }); } catch (error) { next(error); }
});
app.patch('/api/admin/team/:id', requireAdmin, async (req, res, next) => {
  try { const input = z.object({ role: z.enum(['OWNER', 'REVIEWER', 'CONTENT_EDITOR', 'MODERATOR']).optional(), isActive: z.boolean().optional(), name: z.string().trim().min(2).max(80).optional() }).parse(req.body); const member = await prisma.adminAccount.update({ where: { id: String(req.params.id) }, data: input }); res.json({ id: member.id, name: member.name, email: member.email, role: member.role, isActive: member.isActive }); } catch (error) { next(error); }
});

app.get('/api/admin/users', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.user.findMany({ select: { id: true, name: true, phone: true, email: true, points: true, level: true, role: true, createdAt: true, _count: { select: { reviews: true, listings: true, providers: true } } }, orderBy: { createdAt: 'desc' }, take: 500 })); } catch (error) { next(error); }
});

const parseCsvLine = (line: string) => line.split(',').map((value) => value.trim().replace(/^"|"$/g, ''));
app.post('/api/admin/import/providers', requireAdmin, async (req, res, next) => {
  try {
    const csv = z.object({ csv: z.string().min(1).max(2_000_000) }).parse(req.body).csv.replace(/^\uFEFF/, '');
    const lines = csv.split(/\r?\n/).map((line) => line.trim()).filter(Boolean); if (lines.length < 2) return res.status(400).json({ message: 'ملف CSV يحتاج صف عناوين وصف بيانات واحد على الأقل' });
    const headers = parseCsvLine(lines[0]).map((header) => header.toLowerCase()); const index = (names: string[]) => names.map((name) => headers.indexOf(name)).find((value) => value >= 0) ?? -1;
    const nameIndex = index(['name', 'الاسم', 'اسم النشاط']); const areaIndex = index(['area', 'المنطقة']); const categoryIndex = index(['category', 'الفئة']); const descriptionIndex = index(['description', 'الوصف']); const phoneIndex = index(['phone', 'الهاتف', 'التليفون']);
    if (nameIndex < 0 || areaIndex < 0 || categoryIndex < 0) return res.status(400).json({ message: 'الأعمدة المطلوبة: name, area, category' });
    let created = 0; let duplicates = 0; const errors: string[] = [];
    for (let rowIndex = 1; rowIndex < lines.length; rowIndex++) {
      const row = parseCsvLine(lines[rowIndex]); const name = row[nameIndex] ?? ''; const areaName = row[areaIndex] ?? ''; const categoryName = row[categoryIndex] ?? ''; if (!name || !areaName || !categoryName) { errors.push(`السطر ${rowIndex + 1}: بيانات ناقصة`); continue; }
      const area = await prisma.area.findFirst({ where: { name: areaName } }) ?? await prisma.area.create({ data: { name: areaName, city: 'قنا' } });
      const category = await prisma.category.findFirst({ where: { OR: [{ name: categoryName }, { slug: categoryName.toLowerCase().replace(/\s+/g, '-') }] } }) ?? await prisma.category.create({ data: { name: categoryName, slug: `${categoryName.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${randomBytes(3).toString('hex')}` } });
      const phone = phoneIndex >= 0 ? row[phoneIndex] || undefined : undefined; const duplicate = await prisma.provider.findFirst({ where: { areaId: area.id, OR: [{ name: { equals: name, mode: 'insensitive' } }, ...(phone ? [{ phone }] : [])] } }); if (duplicate) { duplicates++; continue; }
      await prisma.provider.create({ data: { name, description: descriptionIndex >= 0 ? row[descriptionIndex] || undefined : undefined, phone, areaId: area.id, status: ReviewStatus.PENDING, communityAdded: false, submissionKind: 'IMPORT', images: { create: [{ url: '/assets/brand/temp-logo-mark.svg', kind: 'temporary', sortOrder: 0 }] }, categories: { create: { categoryId: category.id } } } }); created++;
    }
    res.status(201).json({ created, duplicates, errors });
  } catch (error) { next(error); }
});

app.get('/api/admin/reviews', requireAdmin, async (req, res, next) => {
  try {
    const status = typeof req.query.status === 'string' && Object.values(ReviewStatus).includes(req.query.status as ReviewStatus)
      ? req.query.status as ReviewStatus : undefined;
    const unreadOnly = req.query.unread === 'true';
    const reviews = await prisma.review.findMany({ where: { ...(status ? { status } : {}), ...(unreadOnly ? { moderatedAt: null } : {}) }, include: { author: { select: publicAuthorSelect }, provider: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(reviews);
  } catch (error) { next(error); }
});

app.get('/api/admin/replies', requireAdmin, async (req, res, next) => {
  try {
    const unreadOnly = req.query.unread === 'true';
    const replies = await prisma.reviewReply.findMany({ where: unreadOnly ? { moderatedAt: null } : {}, include: { author: { select: publicAuthorSelect }, review: { include: { author: { select: publicAuthorSelect }, provider: true } } }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(replies);
  } catch (error) { next(error); }
});

app.patch('/api/admin/reviews/:id/read', requireAdmin, async (req, res, next) => {
  try {
    const review = await prisma.review.update({ where: { id: String(req.params.id) }, data: { moderatedAt: new Date() } });
    res.json(review);
  } catch (error) { next(error); }
});

app.patch('/api/admin/replies/:id/read', requireAdmin, async (req, res, next) => {
  try {
    const reply = await prisma.reviewReply.update({ where: { id: String(req.params.id) }, data: { moderatedAt: new Date() } });
    res.json(reply);
  } catch (error) { next(error); }
});

app.get('/api/admin/providers', requireAdmin, async (_req, res, next) => {
  try {
    const providers = await prisma.provider.findMany({ include: { area: true, categories: { include: { category: true } } }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(providers);
  } catch (error) { next(error); }
});

app.get('/api/admin/provider-reports', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.providerReport.findMany({ include: { provider: true, reporter: true }, orderBy: { createdAt: 'desc' }, take: 100 })); } catch (error) { next(error); }
});
app.patch('/api/admin/provider-reports/:id', requireAdmin, async (req, res, next) => {
  try { const { status } = moderationSchema.parse(req.body); const report = await prisma.providerReport.update({ where: { id: String(req.params.id) }, data: { status } }); res.json(report); } catch (error) { next(error); }
});

app.get('/api/admin/listings', requireAdmin, async (_req, res, next) => {
  try {
    const listings = await prisma.listing.findMany({ include: { area: true, owner: true, images: true }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(listings);
  } catch (error) { next(error); }
});

app.get('/api/admin/ads', requireAdmin, async (_req, res, next) => {
  try {
    const ads = await prisma.ad.findMany({ include: { area: true }, orderBy: [{ weight: 'desc' }, { createdAt: 'desc' }] });
    res.json(ads);
  } catch (error) { next(error); }
});

const moderationSchema = z.object({ status: z.enum([ReviewStatus.APPROVED, ReviewStatus.REJECTED]) });
const moderationWithNoteSchema = moderationSchema.extend({ note: z.string().trim().max(500).optional() });
app.patch('/api/admin/providers/:id', requireAdmin, async (req, res, next) => {
  try {
    const input = moderationWithNoteSchema.parse(req.body);
    const provider = await prisma.provider.update({ where: { id: String(req.params.id) }, data: { status: input.status, isVerified: input.status === ReviewStatus.APPROVED } });
    if (provider.ownerId) await prisma.notification.create({ data: { userId: provider.ownerId, title: input.status === ReviewStatus.APPROVED ? 'تم اعتماد نشاطك' : 'تحتاج مراجعة بيانات نشاطك', body: input.status === ReviewStatus.APPROVED ? 'ظهر نشاطك الآن للمستخدمين مع شارة مضاف من المجتمع.' : `سبب المراجعة: ${input.note ?? 'يرجى تحديث البيانات والصور.'}` } });
    await audit(`provider.${input.status.toLowerCase()}`, 'provider', provider.id, { status: input.status, note: input.note });
    res.json(provider);
  } catch (error) { next(error); }
});
app.patch('/api/admin/reviews/:id', requireAdmin, async (req, res, next) => {
  try {
    const { status, note } = moderationWithNoteSchema.parse(req.body);
    const review = await prisma.review.update({ where: { id: String(req.params.id) }, data: { status, moderatedAt: new Date() } });
    await prisma.notification.create({ data: { userId: review.authorId, title: status === ReviewStatus.APPROVED ? 'تم اعتماد تقييمك' : 'لم يتم اعتماد تقييمك', body: status === ReviewStatus.APPROVED ? 'شكراً لمساهمتك في تحسين هنا قنا.' : `سبب الرفض: ${note ?? 'يرجى مراجعة محتوى التقييم.'}` } });
    await audit(`review.${status.toLowerCase()}`, 'review', review.id, { status, note });
    res.json(review);
  } catch (error) { next(error); }
});

app.patch('/api/admin/listings/:id', requireAdmin, async (req, res, next) => {
  try {
    const status = z.enum([ListingStatus.ACTIVE, ListingStatus.REJECTED, ListingStatus.ARCHIVED]).parse(req.body.status);
    const note = typeof req.body.note === 'string' ? req.body.note : undefined;
    const listing = await prisma.listing.update({ where: { id: String(req.params.id) }, data: { status } });
    await prisma.notification.create({ data: { userId: listing.ownerId, title: status === ListingStatus.ACTIVE ? 'تم اعتماد إعلانك' : 'تحديث على إعلانك', body: status === ListingStatus.ACTIVE ? 'إعلانك أصبح ظاهراً للمستخدمين.' : `سبب القرار: ${note ?? 'يرجى مراجعة بيانات الإعلان.'}` } });
    await audit(`listing.${status.toLowerCase()}`, 'listing', listing.id, { status, note });
    res.json(listing);
  } catch (error) { next(error); }
});

app.patch('/api/admin/ads/:id', requireAdmin, async (req, res, next) => {
  try {
    const { status } = moderationSchema.parse(req.body);
    const ad = await prisma.ad.update({ where: { id: String(req.params.id) }, data: { status } });
    await audit(`ad.${status.toLowerCase()}`, 'ad', ad.id, { status });
    res.json(ad);
  } catch (error) { next(error); }
});

app.use((_req: express.Request, res: express.Response) => {
  res.status(404).json({ message: 'المسار غير موجود' });
});

app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  if (error instanceof z.ZodError) {
    const formatted = error.issues.map(issue => ({ path: issue.path.join('.'), message: issue.message }));
    return res.status(400).json({ message: 'بيانات المدخلات غير صحيحة', errors: formatted });
  }
  if (error instanceof Error && error.message.includes('Unique constraint')) {
    return res.status(409).json({ message: 'البيانات موجودة بالفعل' });
  }
  if (error instanceof Error && error.message.includes('NotFound')) {
    return res.status(404).json({ message: 'العنصر غير موجود' });
  }
  console.error('[API Error]', error);
  res.status(500).json({ message: 'خطأ في الخادم - يرجى المحاولة لاحقاً' });
});

app.listen(port, () => console.log(`Hena Qena API listening on http://localhost:${port}`));
