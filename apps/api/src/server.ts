import 'dotenv/config';
import { createHash, randomBytes, randomInt, scrypt as scryptCallback } from 'node:crypto';
import { mkdir, unlink, writeFile, readdir, stat, readFile, rm } from 'node:fs/promises';
import { execFile as execFileCallback } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';
import cors from 'cors';
import express from 'express';
import { PrismaClient, ReviewStatus, ListingStatus } from '@prisma/client';
import { createRemoteJWKSet, jwtVerify } from 'jose';
import { z } from 'zod';
import { createDataCollectionRouter } from './data-collection/router';

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
app.set('trust proxy', 1);
const port = Number(process.env.PORT ?? 4000);
const host = process.env.API_HOST ?? '127.0.0.1';
const uploadRoot = process.env.UPLOADS_DIR ?? path.join(process.cwd(), 'uploads');
const backupRoot = process.env.BACKUP_DIR ?? path.join(process.cwd(), 'backups');
const backupConfigPath = path.join(backupRoot, 'schedule.json');
const publicApiBaseUrl = (process.env.PUBLIC_API_BASE_URL ?? `http://127.0.0.1:${port}`).replace(/\/$/, '');
const scrypt = promisify(scryptCallback);
const execFile = promisify(execFileCallback);
const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const passwordHash = async (password: string) => { const salt = randomBytes(16); const derived = await scrypt(password, salt, 64) as Buffer; return `${salt.toString('hex')}:${derived.toString('hex')}`; };
const verifyPassword = async (password: string, stored: string) => { const [saltHex, storedHash] = stored.split(':'); const salt = Buffer.from(saltHex, 'hex'); const derived = await scrypt(password, salt, 64) as Buffer; return derived.toString('hex') === storedHash; };
const issueSession = async (userId: string) => { const token = randomBytes(32).toString('hex'); await prisma.session.create({ data: { userId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } }); return token; };
const issueAdminSession = async (adminId: string) => { const token = randomBytes(32).toString('hex'); await prisma.adminSession.create({ data: { adminId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 12 * 60 * 60 * 1000) } }); return token; };
const sessionFromRequest = async (req: express.Request) => { const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : ''; if (!token) return null; const session = await prisma.session.findUnique({ where: { tokenHash: hash(token) }, include: { user: true } }); return session && session.expiresAt > new Date() ? session : null; };
const adminSessionFromRequest = async (req: express.Request) => { const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : ''; if (!token) return null; const session = await prisma.adminSession.findUnique({ where: { tokenHash: hash(token) }, include: { admin: true } }); return session && session.expiresAt > new Date() && session.admin.isActive ? session : null; };
const requireAdmin = async (req: express.Request, res: express.Response, next: express.NextFunction) => { const expected = process.env.ADMIN_API_KEY ?? (process.env.NODE_ENV !== 'production' ? 'dev-henaqena-admin' : undefined); const provided = typeof req.headers['x-admin-key'] === 'string' ? req.headers['x-admin-key'] : ''; if (expected && provided === expected) return next(); if (await adminSessionFromRequest(req)) return next(); return res.status(403).json({ message: 'صلاحيات الإدارة مطلوبة' }); };
const requireAdminRoles = (roles: string[]) => async (req: express.Request, res: express.Response, next: express.NextFunction) => { const expected = process.env.ADMIN_API_KEY ?? (process.env.NODE_ENV !== 'production' ? 'dev-henaqena-admin' : undefined); const provided = typeof req.headers['x-admin-key'] === 'string' ? req.headers['x-admin-key'] : ''; if (expected && provided === expected) return next(); const session = await adminSessionFromRequest(req); if (!session || !roles.includes(session.admin.role)) return res.status(403).json({ message: 'الدور الإداري لا يسمح بهذه العملية' }); next(); };
const audit = (action: string, entity: string, entityId: string, metadata?: Record<string, unknown>) => prisma.auditLog.create({ data: { action, entity, entityId, metadata: metadata as any } });
type BackupSchedule = { enabled: boolean; interval: '3d' | '6d' | 'week' | 'month'; nextRunAt: string | null; updatedAt: string };
const backupIntervals: Record<BackupSchedule['interval'], number> = { '3d': 3, '6d': 6, week: 7, month: 30 };
const defaultBackupSchedule = (): BackupSchedule => ({ enabled: false, interval: 'week', nextRunAt: null, updatedAt: new Date().toISOString() });
const readBackupSchedule = async (): Promise<BackupSchedule> => {
  try { return { ...defaultBackupSchedule(), ...JSON.parse(await readFile(backupConfigPath, 'utf8')) } as BackupSchedule; } catch { return defaultBackupSchedule(); }
};
const writeBackupSchedule = async (schedule: BackupSchedule) => { await mkdir(backupRoot, { recursive: true }); await writeFile(backupConfigPath, JSON.stringify(schedule, null, 2)); };
const createDatabaseBackup = async () => {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) throw new Error('DATABASE_URL غير مهيأ');
  await mkdir(backupRoot, { recursive: true });
  const filename = `henaqena-${new Date().toISOString().replace(/[:.]/g, '-')}.dump`;
  const target = path.join(backupRoot, filename);
  await execFile('pg_dump', ['--format=custom', '--no-owner', '--file', target, databaseUrl], { timeout: 10 * 60 * 1000 });
  return { filename, target };
};
const listDatabaseBackups = async () => {
  await mkdir(backupRoot, { recursive: true });
  const entries = await readdir(backupRoot);
  const files = await Promise.all(entries.filter((name) => name.endsWith('.dump')).map(async (filename) => ({ filename, size: (await stat(path.join(backupRoot, filename))).size })));
  return files.sort((a, b) => b.filename.localeCompare(a.filename));
};
let backupTimer: NodeJS.Timeout | undefined;
const startBackupScheduler = () => {
  if (backupTimer) clearInterval(backupTimer);
  backupTimer = setInterval(async () => {
    const schedule = await readBackupSchedule();
    if (!schedule.enabled || !schedule.nextRunAt || new Date(schedule.nextRunAt) > new Date()) return;
    try {
      await createDatabaseBackup();
      const next = new Date(Date.now() + backupIntervals[schedule.interval] * 24 * 60 * 60 * 1000);
      await writeBackupSchedule({ ...schedule, nextRunAt: next.toISOString(), updatedAt: new Date().toISOString() });
    } catch (error) { console.error('Automatic database backup failed', error); }
  }, 60 * 1000);
};
const publicAuthorSelect = { id: true, name: true, avatarUrl: true, isProfilePrivate: true, points: true, level: true } as const;
const verificationWebhooks: Record<string, string | undefined> = {
  whatsapp: process.env.WHATSAPP_OTP_WEBHOOK_URL,
  sms: process.env.SMS_OTP_WEBHOOK_URL,
  email: process.env.EMAIL_OTP_WEBHOOK_URL,
};
const deliverVerificationCode = async (channel: string, target: string, code: string, purpose: 'verify' | 'reset') => {
  const webhook = verificationWebhooks[channel];
  if (!webhook) {
    if (process.env.NODE_ENV !== 'production') { console.log(`[${purpose}:${channel}] ${target}: ${code}`); return; }
    throw new Error(`قناة إرسال ${channel} غير مهيأة`);
  }
  const response = await fetch(webhook, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...(process.env.OTP_WEBHOOK_TOKEN ? { authorization: `Bearer ${process.env.OTP_WEBHOOK_TOKEN}` } : {}) },
    body: JSON.stringify({ channel, target, code, purpose, app: 'henaqena' }),
  });
  if (!response.ok) throw new Error(`تعذر إرسال رمز ${channel}`);
};

const allowedOrigins = (process.env.CORS_ORIGINS ?? '*').split(',').map((origin) => origin.trim()).filter(Boolean);
app.use(cors({ origin: allowedOrigins.includes('*') ? true : allowedOrigins }));
app.use((_req, res, next) => { res.set({ 'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY', 'Referrer-Policy': 'strict-origin-when-cross-origin', 'Permissions-Policy': 'geolocation=(self)' }); next(); });
app.use(express.json({ limit: '16mb' }));
app.use('/uploads', express.static(uploadRoot, { maxAge: '7d', etag: true }));
app.use(
  '/api/admin/data-collection',
  requireAdmin,
  createDataCollectionRouter(prisma),
);

const authLimiter = createRateLimiter(5, 15 * 60 * 1000); // 5 attempts per 15 minutes
const verificationLimiter = createRateLimiter(10, 60 * 60 * 1000); // 10 attempts per hour

app.get('/health', (_req, res) => res.json({ ok: true, service: 'hena-qena-api' }));
app.get('/ready', async (_req, res) => {
  try { await prisma.$queryRaw`SELECT 1`; res.json({ ok: true, database: 'ready' }); } catch { res.status(503).json({ ok: false, database: 'unavailable' }); }
});

app.get('/api/me', async (req, res, next) => {
  try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' }); const { passwordHash, ...user } = session.user; res.json(user); } catch (error) { next(error); }
});

app.get('/api/users/:id', async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: String(req.params.id) },
      select: { id: true, name: true, avatarUrl: true, points: true, level: true, isProfilePrivate: true, createdAt: true, role: true },
    });
    if (!user || user.role === 'SYSTEM') return res.status(404).json({ message: 'المستخدم غير موجود' });
    const { role, ...publicUser } = user;
    if (publicUser.isProfilePrivate) return res.json({ ...publicUser, contributions: null });
    const [reviews, listings, providers] = await Promise.all([
      prisma.review.findMany({ where: { authorId: user.id, status: ReviewStatus.APPROVED }, include: { provider: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: 50 }),
      prisma.listing.findMany({ where: { ownerId: user.id, status: ListingStatus.ACTIVE, expiresAt: { gt: new Date() } }, include: { area: true, images: { orderBy: { sortOrder: 'asc' }, take: 1 } }, orderBy: { createdAt: 'desc' }, take: 50 }),
      prisma.provider.findMany({ where: { ownerId: user.id, status: ReviewStatus.APPROVED }, include: { area: true, images: { orderBy: { sortOrder: 'asc' }, take: 1 } }, orderBy: { createdAt: 'desc' }, take: 50 }),
    ]);
    res.json({ ...publicUser, contributions: { reviews, listings, providers } });
  } catch (error) { next(error); }
});

app.patch('/api/me/preferences', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = z.object({ preferredAreaIds: z.array(z.string()).max(3).optional(), interests: z.array(z.string()).max(5).optional(), ageRange: z.enum(['أقل من 18', '18–24', '25–34', '35–49', '50 أو أكثر', 'أفضل عدم الإفصاح']).nullable().optional(), gender: z.enum(['رجل', 'امرأة', 'أفضل عدم الإفصاح']).nullable().optional(), notificationScope: z.enum(['all', 'area']).optional(), notificationsEnabled: z.boolean().optional(), notificationDigest: z.boolean().optional(), isProfilePrivate: z.boolean().optional() }).parse(req.body);
    const user = await prisma.user.update({ where: { id: session.userId }, data: input });
    res.json({ preferredAreaIds: user.preferredAreaIds, interests: user.interests, ageRange: user.ageRange, gender: user.gender, notificationScope: user.notificationScope, notificationsEnabled: user.notificationsEnabled, notificationDigest: user.notificationDigest });
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
    const input = z.object({ identifier: z.string().trim().min(3), password: z.string().min(1) }).parse(req.body);
    const isEmail = input.identifier.includes('@');
    let user = isEmail
      ? await prisma.user.findUnique({ where: { email: input.identifier.toLowerCase() } })
      : await prisma.user.findUnique({ where: { phone: input.identifier } });
    const admin = isEmail
      ? await prisma.adminAccount.findUnique({ where: { email: input.identifier.toLowerCase() } })
      : null;
    const userPasswordValid = Boolean(user?.passwordHash && await verifyPassword(input.password, user.passwordHash));
    const adminPasswordValid = Boolean(admin?.isActive && await verifyPassword(input.password, admin.passwordHash));
    if (!userPasswordValid && !adminPasswordValid) return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    if (!user && admin && adminPasswordValid) {
      user = await prisma.user.create({ data: { name: admin.name, email: admin.email, passwordHash: admin.passwordHash, authProvider: 'password', role: 'ADMIN' } });
    } else if (user && adminPasswordValid && user.role !== 'ADMIN') {
      user = await prisma.user.update({ where: { id: user.id }, data: { role: 'ADMIN' } });
    }
    if (!user) return res.status(401).json({ message: 'بيانات الدخول غير صحيحة' });
    const token = await issueSession(user.id);
    const adminToken = adminPasswordValid && admin ? await issueAdminSession(admin.id) : null;
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: Boolean(user.phoneVerifiedAt), emailVerified: Boolean(user.emailVerifiedAt), role: user.role }, ...(adminToken && admin ? { admin: { token: adminToken, name: admin.name, role: admin.role } } : {}) });
  } catch (error) { next(error); }
});

const googleJwks = createRemoteJWKSet(new URL('https://www.googleapis.com/oauth2/v3/certs'));
const appleJwks = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
const configuredAudiences = (provider: 'google' | 'apple') =>
  (provider === 'google' ? process.env.GOOGLE_CLIENT_IDS : process.env.APPLE_CLIENT_IDS)
    ?.split(',').map((item) => item.trim()).filter(Boolean) ?? [];

app.post('/api/auth/federated', authLimiter, async (req, res, next) => {
  try {
    const input = z.object({
      provider: z.enum(['google', 'apple']),
      identityToken: z.string().min(100),
      authorizationCode: z.string().optional(),
      displayName: z.string().trim().min(2).max(80).optional(),
    }).parse(req.body);
    const audiences = configuredAudiences(input.provider);
    if (audiences.length === 0) return res.status(503).json({ message: `تسجيل ${input.provider} مجهز وينتظر Client ID الإنتاج` });
    const verified = input.provider === 'google'
      ? await jwtVerify(input.identityToken, googleJwks, { audience: audiences, issuer: ['https://accounts.google.com', 'accounts.google.com'] })
      : await jwtVerify(input.identityToken, appleJwks, { audience: audiences, issuer: 'https://appleid.apple.com' });
    const subject = verified.payload.sub;
    if (!subject) return res.status(401).json({ message: 'رمز الهوية لا يحتوي معرف مستخدم' });
    const email = typeof verified.payload.email === 'string' ? verified.payload.email.toLowerCase() : null;
    let user = await prisma.user.findUnique({ where: { authProvider_authSubject: { authProvider: input.provider, authSubject: subject } } });
    if (!user && email) {
      const existing = await prisma.user.findUnique({ where: { email } });
      if (existing) return res.status(409).json({ message: 'البريد مرتبط بحساب موجود. ادخل للحساب أولاً ثم اربط وسيلة الدخول من الإعدادات.' });
    }
    if (!user) {
      const fallbackName = input.displayName || email?.split('@')[0] || 'قناوي';
      user = await prisma.user.create({ data: { name: fallbackName, email, emailVerifiedAt: email ? new Date() : null, authProvider: input.provider, authSubject: subject } });
    }
    const token = await issueSession(user.id);
    res.json({ token, user: { id: user.id, name: user.name, phone: user.phone, email: user.email, phoneVerified: Boolean(user.phoneVerifiedAt), emailVerified: Boolean(user.emailVerifiedAt), role: user.role } });
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
    await deliverVerificationCode(input.channel, target, code, 'verify');
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
    if (user) { const code = String(randomInt(100000, 1000000)); await prisma.verificationCode.create({ data: { userId: user.id, channel: `reset_${input.channel}`, target: input.identifier, codeHash: hash(code), expiresAt: new Date(Date.now() + 10 * 60 * 1000) } }); await deliverVerificationCode(input.channel, input.identifier, code, 'reset'); }
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

app.post('/api/admin/auth/login', authLimiter, async (req, res, next) => {
  try { const input = z.object({ email: z.string().email(), password: z.string().min(1) }).parse(req.body); const admin = await prisma.adminAccount.findUnique({ where: { email: input.email.toLowerCase() } }); if (!admin || !admin.isActive || !(await verifyPassword(input.password, admin.passwordHash))) return res.status(401).json({ message: 'بيانات مدير الإدارة غير صحيحة' }); const token = await issueAdminSession(admin.id); await prisma.adminAccount.update({ where: { id: admin.id }, data: { lastLoginAt: new Date() } }); res.json({ token, admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role } }); } catch (error) { next(error); }
});
app.post('/api/admin/auth/logout', async (req, res, next) => {
  try { const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : ''; if (token) await prisma.adminSession.deleteMany({ where: { tokenHash: hash(token) } }); res.json({ loggedOut: true }); } catch (error) { next(error); }
});
app.get('/api/admin/auth/me', async (req, res, next) => {
  try { const session = await adminSessionFromRequest(req); if (!session) return res.status(401).json({ message: 'جلسة الإدارة منتهية' }); res.json({ id: session.admin.id, name: session.admin.name, email: session.admin.email, role: session.admin.role }); } catch (error) { next(error); }
});

app.get('/api/areas', async (req, res, next) => {
  try {
    const limit = Math.min(100, Math.max(1, Number(req.query.limit ?? 100)));
    const offset = Math.max(0, Number(req.query.offset ?? 0));
    const [areas, total] = await Promise.all([
      prisma.area.findMany({ where: { isActive: true }, orderBy: { name: 'asc' }, take: limit, skip: offset }),
      prisma.area.count({ where: { isActive: true } }),
    ]);
    res.json({ data: areas, total, limit, offset });
  } catch (error) {
    next(error);
  }
});

app.get('/api/categories', async (req, res, next) => {
  try {
    const limit = Math.min(100, Math.max(1, Number(req.query.limit ?? 100)));
    const offset = Math.max(0, Number(req.query.offset ?? 0));
    const [categories, total] = await Promise.all([
      prisma.category.findMany({ where: { isActive: true }, orderBy: { name: 'asc' }, take: limit, skip: offset }),
      prisma.category.count({ where: { isActive: true } }),
    ]);
    res.json({ data: categories, total, limit, offset });
  } catch (error) {
    next(error);
  }
});

app.get('/api/providers', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const q = typeof req.query.q === 'string' ? req.query.q.trim() : undefined;
    const verifiedOnly = req.query.verified === 'true';
    const openNow = req.query.openNow === 'true';
    const sort = typeof req.query.sort === 'string' ? req.query.sort : 'name';
    const page = Math.max(1, Number(req.query.page ?? 1));
    const pageSize = Math.min(50, Math.max(1, Number(req.query.pageSize ?? 20)));
    const attributeFilters = Object.fromEntries(
      Object.keys(providerAttributesFields)
        .filter((key) => req.query[key] === 'true')
        .map((key) => [key, true]),
    );
    let providers = await prisma.provider.findMany({
      where: {
        status: ReviewStatus.APPROVED,
        ...(verifiedOnly ? { isVerified: true } : {}),
        ...(areaId ? { areaId } : {}),
        ...(category ? { categories: { some: { category: { slug: category } } } } : {}),
        ...attributeFilters,
        ...(q ? { OR: [{ name: { contains: q, mode: 'insensitive' } }, { description: { contains: q, mode: 'insensitive' } }, { address: { contains: q, mode: 'insensitive' } }, { categories: { some: { category: { name: { contains: q, mode: 'insensitive' } } } } }] } : {}),
      },
      include: { area: true, images: { orderBy: { sortOrder: 'asc' } }, categories: { include: { category: true } }, reviews: { where: { status: ReviewStatus.APPROVED }, select: { quality: true, commitment: true, value: true } } },
      orderBy: sort === 'latest' ? { createdAt: 'desc' } : [{ isVerified: 'desc' }, { name: 'asc' }],
      skip: (page - 1) * pageSize,
      take: pageSize,
    });
    if (openNow) {
      const current = new Date();
      const currentMinutes = current.getHours() * 60 + current.getMinutes();
      const parseMinutes = (value: string | null) => { if (!value || !/^\d{2}:\d{2}$/.test(value)) return null; const [hours, minutes] = value.split(':').map(Number); return hours * 60 + minutes; };
      providers = providers.filter((provider) => { const opening = parseMinutes(provider.openingTime); const closing = parseMinutes(provider.closingTime); if (opening === null || closing === null) return false; return closing >= opening ? currentMinutes >= opening && currentMinutes <= closing : currentMinutes >= opening || currentMinutes <= closing; });
    }
    const withScores = providers.map((provider) => {
      const rating = provider.reviews.length === 0 ? 0 : provider.reviews.reduce((sum, review) => sum + (review.quality + review.commitment + review.value) / 3, 0) / provider.reviews.length;
      const { reviews, ...publicProvider } = provider;
      return { ...publicProvider, rating: Number(rating.toFixed(1)), reviewCount: reviews.length };
    });
    if (sort === 'rating') withScores.sort((left, right) => right.rating - left.rating || left.name.localeCompare(right.name, 'ar'));
    if (sort === 'reviews') withScores.sort((left, right) => right.reviewCount - left.reviewCount || left.name.localeCompare(right.name, 'ar'));
    res.json(withScores);
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
    const admin = session ? null : await adminSessionFromRequest(req);
    if (!session && !admin) return res.status(401).json({ message: 'سجّل الدخول أولاً لرفع الصور' });
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

app.post('/api/uploads/avatar', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const image = uploadedImageSchema.parse(req.body);
    const bytes = Buffer.from(image.base64, 'base64');
    if (bytes.length === 0 || bytes.length > 2 * 1024 * 1024) return res.status(400).json({ message: 'حجم الصورة يجب ألا يزيد عن 2 ميجابايت' });
    const extension = image.mimeType === 'image/png' ? 'png' : image.mimeType === 'image/webp' ? 'webp' : 'jpg';
    const folder = path.join(uploadRoot, 'avatars');
    await mkdir(folder, { recursive: true });
    const filename = `${session.userId}-${Date.now()}-${randomBytes(6).toString('hex')}.${extension}`;
    await writeFile(path.join(folder, filename), bytes, { flag: 'wx' });
    res.status(201).json({ url: `${publicApiBaseUrl}/uploads/avatars/${filename}` });
  } catch (error) { next(error); }
});

app.patch('/api/me/profile', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = z.object({ name: z.string().trim().min(2).max(80), email: z.union([z.string().email(), z.literal('')]).optional(), avatarUrl: z.string().url().nullable().optional() }).parse(req.body);
    const user = await prisma.user.update({ where: { id: session.userId }, data: { name: input.name, email: input.email ? input.email.toLowerCase() : null, ...(input.avatarUrl !== undefined ? { avatarUrl: input.avatarUrl } : {}) } });
    res.json({ id: user.id, name: user.name, email: user.email, avatarUrl: user.avatarUrl });
  } catch (error) { next(error); }
});

const socialPlatformSchema = z.enum(['facebook', 'instagram', 'x', 'tiktok', 'youtube']);
const requireSocialPlatformWithUrl = (value: { socialUrl?: string; socialPlatform?: string }) => !value.socialUrl || value.socialPlatform;
const requireSocialPlatformRefinement = { message: 'اختر نوع السوشيال ميديا', path: ['socialPlatform'] };
const providerAttributesFields = { kidFriendly: z.coerce.boolean().default(false), accessible: z.coerce.boolean().default(false), hasParking: z.coerce.boolean().default(false), acceptsCards: z.coerce.boolean().default(false), homeService: z.coerce.boolean().default(false), needsBooking: z.coerce.boolean().default(false), open24h: z.coerce.boolean().default(false), hasDelivery: z.coerce.boolean().default(false) };
const providerBaseSchema = z.object({ name: z.string().trim().min(2).max(120), description: z.string().trim().max(1000).optional(), logoUrl: z.string().trim().url().max(500).optional(), phone: z.string().regex(/^01[0125][0-9]{8}$/).optional(), whatsapp: z.string().regex(/^01[0125][0-9]{8}$/).optional(), socialPlatform: socialPlatformSchema.optional(), socialUrl: z.string().trim().url().max(300).optional(), phoneType: z.enum(['BUSINESS', 'PERSONAL']).default('BUSINESS'), address: z.string().trim().max(240).optional(), latitude: z.coerce.number().min(-90).max(90).optional(), longitude: z.coerce.number().min(-180).max(180).optional(), areaId: z.string().min(1), serviceMode: z.enum(['LOCAL', 'ONLINE']).default('LOCAL'), openingTime: z.string().max(10).optional(), closingTime: z.string().max(10).optional(), categoryIds: z.array(z.string().min(1)).min(1).max(5), images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10), ...providerAttributesFields });
const providerCreateSchema = providerBaseSchema.refine(requireSocialPlatformWithUrl, requireSocialPlatformRefinement);
app.post('/api/providers', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لإضافة نشاط' });
    const input = providerCreateSchema.parse(req.body);
    const duplicate = await prisma.provider.findFirst({ where: { areaId: input.areaId, status: { not: ReviewStatus.REJECTED }, OR: [{ name: { equals: input.name, mode: 'insensitive' } }, ...(input.phone ? [{ phone: input.phone }] : [])] } });
    if (duplicate) return res.status(409).json({ message: 'يوجد نشاط مشابه بالفعل في هذه المنطقة' });
    const provider = await prisma.provider.create({ data: { name: input.name, description: input.description, logoUrl: input.logoUrl, phone: input.phone, whatsapp: input.whatsapp, socialPlatform: input.socialPlatform, socialUrl: input.socialUrl, phoneType: input.phoneType, address: input.address, latitude: input.latitude, longitude: input.longitude, areaId: input.areaId, serviceMode: input.serviceMode, openingTime: input.openingTime, closingTime: input.closingTime, kidFriendly: input.kidFriendly, accessible: input.accessible, hasParking: input.hasParking, acceptsCards: input.acceptsCards, homeService: input.homeService, needsBooking: input.needsBooking, open24h: input.open24h, hasDelivery: input.hasDelivery, ownerId: session.userId, communityAdded: true, status: ReviewStatus.PENDING, images: { create: input.images.map((image, index) => ({ url: image.url, kind: image.kind ?? 'work', sortOrder: index })) }, categories: { create: input.categoryIds.map((categoryId) => ({ categoryId })) } }, include: { area: true, images: true, categories: { include: { category: true } } } });
    res.status(201).json(provider);
  } catch (error) { next(error); }
});

const providerEditSchema = providerBaseSchema.partial().omit({ categoryIds: true, images: true }).extend({ categoryIds: z.array(z.string().min(1)).min(1).max(5).optional(), images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10).optional() }).refine(requireSocialPlatformWithUrl, requireSocialPlatformRefinement);
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
    const session = await sessionFromRequest(req);
    const provider = await prisma.provider.findUnique({
      where: { id: req.params.id },
      include: {
        area: true,
        images: { orderBy: { sortOrder: 'asc' } },
        categories: { include: { category: true } },
        services: { where: { status: ReviewStatus.APPROVED }, orderBy: { createdAt: 'desc' } },
        offers: { where: { status: ReviewStatus.APPROVED, startsAt: { lte: new Date() }, endsAt: { gte: new Date() } }, orderBy: { endsAt: 'asc' } },
        reviews: { where: { status: ReviewStatus.APPROVED }, include: { author: { select: publicAuthorSelect }, replies: { where: { status: ReviewStatus.APPROVED }, include: { author: { select: publicAuthorSelect } } }, _count: { select: { helpfulVotes: true } } }, orderBy: { createdAt: 'desc' } },
        _count: { select: { favorites: true } },
      },
    });
    if (!provider) return res.status(404).json({ message: 'Provider not found' });
    // A provider is saved for the viewer whether it lives in the default
    // favorites bucket or in one of the viewer's named lists.
    const favorite = session ? await prisma.providerFavorite.findFirst({ where: { userId: session.userId, providerId: provider.id } }) : null;
    const helpful = session ? await prisma.reviewHelpful.findMany({ where: { userId: session.userId, reviewId: { in: provider.reviews.map((review) => review.id) } }, select: { reviewId: true } }) : [];
    const helpfulIds = new Set(helpful.map((item) => item.reviewId));
    res.json({ ...provider, reviews: provider.reviews.map((review) => ({ ...review, viewerHelpful: helpfulIds.has(review.id) })), viewer: { favorite: Boolean(favorite) } });
  } catch (error) {
    next(error);
  }
});

app.post('/api/providers/:id/favorite', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const providerId = String(req.params.id);
    const listId = typeof req.body?.listId === 'string' ? req.body.listId : null;
    const existing = await prisma.providerFavorite.findFirst({ where: { userId: session.userId, providerId, listId } });
    if (existing) await prisma.providerFavorite.delete({ where: { id: existing.id } });
    else await prisma.providerFavorite.create({ data: { userId: session.userId, providerId, listId } });
    const [count, saved] = await Promise.all([
      prisma.providerFavorite.count({ where: { providerId, listId: null } }),
      prisma.providerFavorite.findFirst({ where: { userId: session.userId, providerId } }),
    ]);
    res.json({ active: !existing, saved: Boolean(saved), count });
  } catch (error) { next(error); }
});

const serviceSchema = z.object({ name: z.string().trim().min(2).max(120), description: z.string().trim().max(600).optional(), logoUrl: z.string().trim().url().max(500).optional(), price: z.number().nonnegative().max(999999999).optional(), priceNote: z.string().trim().max(120).optional() });
app.post('/api/providers/:id/services', async (req, res, next) => { try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' }); const input = serviceSchema.parse(req.body); const provider = await prisma.provider.findUnique({ where: { id: String(req.params.id) } }); if (!provider || provider.ownerId !== session.userId) return res.status(403).json({ message: 'لا تملك النشاط' }); const service = await prisma.providerService.create({ data: { ...input, providerId: provider.id, status: ReviewStatus.PENDING } }); res.status(201).json(service); } catch (error) { next(error); } });
const offerSchema = z.object({ title: z.string().trim().min(2).max(120), description: z.string().trim().max(600).optional(), startsAt: z.coerce.date(), endsAt: z.coerce.date() }).refine((value) => value.endsAt > value.startsAt, { message: 'تاريخ العرض غير صحيح' });
app.post('/api/providers/:id/offers', async (req, res, next) => { try { const session = await sessionFromRequest(req); if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' }); const input = offerSchema.parse(req.body); const provider = await prisma.provider.findUnique({ where: { id: String(req.params.id) } }); if (!provider || provider.ownerId !== session.userId) return res.status(403).json({ message: 'لا تملك النشاط' }); const offer = await prisma.providerOffer.create({ data: { ...input, providerId: provider.id, status: ReviewStatus.PENDING } }); res.status(201).json(offer); } catch (error) { next(error); } });

app.get('/api/offers', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const now = new Date();
    const offers = await prisma.providerOffer.findMany({
      where: { status: ReviewStatus.APPROVED, startsAt: { lte: now }, endsAt: { gte: now }, ...(areaId ? { provider: { areaId, status: ReviewStatus.APPROVED } } : { provider: { status: ReviewStatus.APPROVED } }) },
      include: { provider: { select: { id: true, name: true, area: true } } },
      orderBy: { endsAt: 'asc' },
      take: 100,
    });
    res.json(offers);
  } catch (error) { next(error); }
});

app.get('/api/listings', async (req, res, next) => {
  try {
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const category = typeof req.query.category === 'string' ? req.query.category : undefined;
    const q = typeof req.query.q === 'string' ? req.query.q.trim() : undefined;
    const page = Math.max(1, Number(req.query.page ?? 1));
    const pageSize = Math.min(50, Math.max(1, Number(req.query.pageSize ?? 20)));
    const [listings, total] = await Promise.all([
      prisma.listing.findMany({
        where: {
          status: ListingStatus.ACTIVE,
          ...(areaId ? { areaId } : {}),
          ...(category ? { category } : {}),
          ...(q ? { OR: [{ title: { contains: q, mode: 'insensitive' } }, { description: { contains: q, mode: 'insensitive' } }] } : {}),
        },
        include: {
          area: true,
          images: { orderBy: { sortOrder: 'asc' } },
          owner: { select: { id: true, name: true, phone: true, avatarUrl: true } },
          _count: { select: { favorites: true, interests: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      prisma.listing.count({
        where: {
          status: ListingStatus.ACTIVE,
          ...(areaId ? { areaId } : {}),
          ...(category ? { category } : {}),
          ...(q ? { OR: [{ title: { contains: q, mode: 'insensitive' } }, { description: { contains: q, mode: 'insensitive' } }] } : {}),
        },
      }),
    ]);
    res.json({ data: listings, total, page, pageSize });
  } catch (error) {
    next(error);
  }
});

app.get('/api/listings/categories', async (req, res, next) => {
  try {
    const rows = await prisma.listing.findMany({ select: { category: true }, distinct: ['category'], orderBy: { category: 'asc' } });
    res.json({ data: rows.map((row) => row.category) });
  } catch (error) { next(error); }
});

app.get('/api/listings/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    const listingId = String(req.params.id);
    const listing = await prisma.listing.findFirst({
      where: { id: listingId, status: ListingStatus.ACTIVE },
      include: {
        area: true,
        images: { orderBy: { sortOrder: 'asc' } },
        owner: { select: { id: true, name: true, phone: true, avatarUrl: true } },
        _count: { select: { favorites: true, interests: true } },
      },
    });
    if (!listing) return res.status(404).json({ message: 'الإعلان غير موجود أو لم يعد متاحاً' });
    const [favorite, interested] = session ? await Promise.all([
      prisma.listingFavorite.findUnique({ where: { userId_listingId: { userId: session.userId, listingId } } }),
      prisma.listingInterest.findUnique({ where: { userId_listingId: { userId: session.userId, listingId } } }),
    ]) : [null, null];
    res.json({ ...listing, viewer: { favorite: Boolean(favorite), interested: Boolean(interested) } });
  } catch (error) { next(error); }
});

app.post('/api/listings/:id/favorite', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const listingId = String(req.params.id);
    const existing = await prisma.listingFavorite.findUnique({ where: { userId_listingId: { userId: session.userId, listingId } } });
    if (existing) await prisma.listingFavorite.delete({ where: { userId_listingId: { userId: session.userId, listingId } } });
    else await prisma.listingFavorite.create({ data: { userId: session.userId, listingId } });
    const count = await prisma.listingFavorite.count({ where: { listingId } });
    res.json({ active: !existing, count });
  } catch (error) { next(error); }
});

app.post('/api/listings/:id/interested', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const listingId = String(req.params.id);
    const existing = await prisma.listingInterest.findUnique({ where: { userId_listingId: { userId: session.userId, listingId } } });
    if (existing) await prisma.listingInterest.delete({ where: { userId_listingId: { userId: session.userId, listingId } } });
    else await prisma.listingInterest.create({ data: { userId: session.userId, listingId } });
    const count = await prisma.listingInterest.count({ where: { listingId } });
    res.json({ active: !existing, count });
  } catch (error) { next(error); }
});

app.post('/api/listings/:id/reports', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const input = z.object({ reason: z.string().trim().min(3).max(300) }).parse(req.body);
    const report = await prisma.listingReport.create({ data: { listingId: String(req.params.id), userId: session.userId, reason: input.reason } });
    res.status(201).json({ id: report.id, status: report.status });
  } catch (error) { next(error); }
});

app.get('/api/me/favorites', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 20)));
    const offset = Math.max(0, Number(req.query.offset ?? 0));
    const listId = typeof req.query.listId === 'string' ? req.query.listId : undefined;
    const [providers, listings, providerCount, listingCount] = await Promise.all([
      prisma.providerFavorite.findMany({ where: { userId: session.userId, ...(listId !== undefined ? { listId: listId || null } : {}) }, include: { provider: { include: { area: true, images: { orderBy: { sortOrder: 'asc' }, take: 1 } } }, list: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.listingFavorite.findMany({ where: { userId: session.userId }, include: { listing: { include: { area: true, images: { orderBy: { sortOrder: 'asc' }, take: 1 } } } }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.providerFavorite.count({ where: { userId: session.userId, ...(listId !== undefined ? { listId: listId || null } : {}) } }),
      prisma.listingFavorite.count({ where: { userId: session.userId } }),
    ]);
    res.json({ providers: { data: providers.map((item) => ({ ...item.provider, favoriteListId: item.listId, favoriteListName: item.list?.name ?? null })), total: providerCount }, listings: { data: listings.map((item) => item.listing), total: listingCount }, limit, offset });
  } catch (error) { next(error); }
});

app.get('/api/me/favorite-lists', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const lists = await prisma.favoriteList.findMany({ where: { userId: session.userId }, include: { _count: { select: { favorites: true } } }, orderBy: { createdAt: 'asc' } });
    res.json(lists.map((list) => ({ id: list.id, name: list.name, count: list._count.favorites, createdAt: list.createdAt })));
  } catch (error) { next(error); }
});

app.post('/api/me/favorite-lists', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const { name } = z.object({ name: z.string().trim().min(1).max(60) }).parse(req.body);
    const list = await prisma.favoriteList.create({ data: { userId: session.userId, name } });
    res.status(201).json({ id: list.id, name: list.name, count: 0, createdAt: list.createdAt });
  } catch (error) { next(error); }
});

app.patch('/api/me/favorite-lists/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const { name } = z.object({ name: z.string().trim().min(1).max(60) }).parse(req.body);
    const existing = await prisma.favoriteList.findUnique({ where: { id: String(req.params.id) } });
    if (!existing || existing.userId !== session.userId) return res.status(404).json({ message: 'القائمة غير موجودة' });
    const list = await prisma.favoriteList.update({ where: { id: existing.id }, data: { name } });
    res.json({ id: list.id, name: list.name });
  } catch (error) { next(error); }
});

app.delete('/api/me/favorite-lists/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const existing = await prisma.favoriteList.findUnique({ where: { id: String(req.params.id) } });
    if (!existing || existing.userId !== session.userId) return res.status(404).json({ message: 'القائمة غير موجودة' });
    await prisma.favoriteList.delete({ where: { id: existing.id } });
    res.json({ ok: true });
  } catch (error) { next(error); }
});

app.get('/api/me/saved-searches', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const searches = await prisma.savedSearch.findMany({ where: { userId: session.userId }, orderBy: { createdAt: 'desc' } });
    res.json(searches);
  } catch (error) { next(error); }
});

const savedSearchSchema = z.object({ label: z.string().trim().min(1).max(80), query: z.string().trim().max(120).optional(), areaId: z.string().min(1).optional(), category: z.string().trim().max(60).optional(), sort: z.string().max(20).default('name') });
app.post('/api/me/saved-searches', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = savedSearchSchema.parse(req.body);
    const search = await prisma.savedSearch.create({ data: { userId: session.userId, ...input } });
    res.status(201).json(search);
  } catch (error) { next(error); }
});

app.delete('/api/me/saved-searches/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const existing = await prisma.savedSearch.findUnique({ where: { id: String(req.params.id) } });
    if (!existing || existing.userId !== session.userId) return res.status(404).json({ message: 'البحث المحفوظ غير موجود' });
    await prisma.savedSearch.delete({ where: { id: existing.id } });
    res.json({ ok: true });
  } catch (error) { next(error); }
});

app.get('/api/me/contributions', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const limit = Math.min(50, Math.max(1, Number(req.query.limit ?? 20)));
    const offset = Math.max(0, Number(req.query.offset ?? 0));
    const [providers, listings, reviews, reports, providerCount, listingCount, reviewCount, reportCount] = await Promise.all([
      prisma.provider.findMany({ where: { ownerId: session.userId }, include: { area: true }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.listing.findMany({ where: { ownerId: session.userId }, include: { area: true, images: true }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.review.findMany({ where: { authorId: session.userId }, include: { provider: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.providerReport.findMany({ where: { reporterId: session.userId }, include: { provider: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: limit, skip: offset }),
      prisma.provider.count({ where: { ownerId: session.userId } }),
      prisma.listing.count({ where: { ownerId: session.userId } }),
      prisma.review.count({ where: { authorId: session.userId } }),
      prisma.providerReport.count({ where: { reporterId: session.userId } }),
    ]);
    res.json({ providers: { data: providers, total: providerCount }, listings: { data: listings, total: listingCount }, reviews: { data: reviews, total: reviewCount }, reports: { data: reports, total: reportCount }, limit, offset });
  } catch (error) { next(error); }
});

app.patch('/api/me/reviews/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const input = reviewSchema.omit({ providerId: true }).parse(req.body);
    const review = await prisma.review.findFirst({ where: { id: String(req.params.id), authorId: session.userId } });
    if (!review) return res.status(404).json({ message: 'التقييم غير موجود' });
    const updated = await prisma.review.update({ where: { id: review.id }, data: { ...input, status: ReviewStatus.PENDING, moderatedAt: null } });
    res.json({ ...updated, message: 'تم تحديث التقييم وإرساله للمراجعة' });
  } catch (error) { next(error); }
});

app.patch('/api/me/listings/:id/renew', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const existing = await prisma.listing.findFirst({ where: { id: String(req.params.id), ownerId: session.userId } });
    if (!existing) return res.status(404).json({ message: 'الإعلان غير موجود' });
    if (existing.status !== ListingStatus.EXPIRED && existing.status !== ListingStatus.ARCHIVED) return res.status(400).json({ message: 'الإعلان لا يحتاج إعادة نشر' });
    const listing = await prisma.listing.update({ where: { id: existing.id }, data: { status: ListingStatus.ACTIVE, createdAt: new Date(), expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000) } });
    res.json(listing);
  } catch (error) { next(error); }
});

app.delete('/api/me/listings/:id', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'غير مسجل الدخول' });
    const listing = await prisma.listing.findFirst({ where: { id: String(req.params.id), ownerId: session.userId }, include: { images: true } });
    if (!listing) return res.status(404).json({ message: 'الإعلان غير موجود' });
    await prisma.listing.delete({ where: { id: listing.id } });
    await Promise.all(listing.images.map(async (image) => {
      try {
        const pathname = new URL(image.url).pathname;
        if (!pathname.startsWith('/uploads/providers/')) return;
        await unlink(path.join(uploadRoot, 'providers', path.basename(pathname)));
      } catch { /* The database record is already removed; missing files are harmless. */ }
    }));
    res.json({ deleted: true });
  } catch (error) { next(error); }
});

app.post('/api/jobs/expire-listings', requireAdmin, async (_req, res, next) => {
  try { const result = await prisma.listing.updateMany({ where: { status: ListingStatus.ACTIVE, expiresAt: { lt: new Date() } }, data: { status: ListingStatus.EXPIRED } }); res.json({ expired: result.count }); } catch (error) { next(error); }
});

const listingCreateSchema = z.object({ title: z.string().trim().min(3).max(120), description: z.string().trim().max(1200).optional(), logoUrl: z.string().trim().url().max(500).optional(), category: z.string().trim().min(1).max(60), price: z.number().positive().max(999999999), areaId: z.string().min(1), images: z.array(z.string().url()).min(1).max(5) });
app.post('/api/listings', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً لإضافة إعلان' });
    const input = listingCreateSchema.parse(req.body);
    const listing = await prisma.listing.create({ data: { title: input.title, description: input.description, logoUrl: input.logoUrl, category: input.category, price: input.price, ownerId: session.userId, areaId: input.areaId, status: ListingStatus.PENDING, expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), images: { create: input.images.map((url, index) => ({ url, sortOrder: index })) } }, include: { area: true, images: true } });
    res.status(201).json(listing);
  } catch (error) { next(error); }
});

app.get('/api/ads', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    const areaId = typeof req.query.areaId === 'string' ? req.query.areaId : undefined;
    const now = new Date();
    const ads = await prisma.ad.findMany({ where: { status: ReviewStatus.APPROVED, startsAt: { lte: now }, endsAt: { gte: now }, OR: [{ areaId: null }, ...(areaId ? [{ areaId }] : [])] }, include: { _count: { select: { reactions: true } } }, orderBy: [{ weight: 'desc' }, { reactions: { _count: 'desc' } }, { createdAt: 'desc' }] });
    const reactions = session ? await prisma.adReaction.findMany({ where: { userId: session.userId, adId: { in: ads.map((ad) => ad.id) } }, select: { adId: true } }) : [];
    const reactedIds = new Set(reactions.map((item) => item.adId));
    res.json(ads.map((ad) => ({ ...ad, viewerReacted: reactedIds.has(ad.id) })));
  } catch (error) {
    next(error);
  }
});

app.post('/api/ads/:id/react', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const adId = String(req.params.id);
    const ad = await prisma.ad.findFirst({ where: { id: adId, status: ReviewStatus.APPROVED, startsAt: { lte: new Date() }, endsAt: { gte: new Date() } } });
    if (!ad) return res.status(404).json({ message: 'الإعلان غير متاح' });
    const existing = await prisma.adReaction.findUnique({ where: { userId_adId: { userId: session.userId, adId } } });
    if (existing) await prisma.adReaction.delete({ where: { userId_adId: { userId: session.userId, adId } } });
    else await prisma.adReaction.create({ data: { userId: session.userId, adId } });
    const count = await prisma.adReaction.count({ where: { adId } });
    res.json({ active: !existing, count });
  } catch (error) { next(error); }
});

const adCreateSchema = z.object({ name: z.string().trim().min(2).max(120), imageUrl: z.string().url(), description: z.string().trim().max(600).optional(), targetUrl: z.string().url().optional(), weight: z.number().int().min(1).max(100).default(100), areaId: z.string().min(1).nullable().optional(), startsAt: z.coerce.date(), endsAt: z.coerce.date() });
app.post('/api/ads', requireAdmin, async (req, res, next) => {
  try {
    const input = adCreateSchema.parse(req.body);
    if (input.endsAt <= input.startsAt) return res.status(400).json({ message: 'تاريخ الانتهاء يجب أن يكون بعد البداية' });
    const ad = await prisma.ad.create({ data: { ...input, areaId: input.areaId ?? null, status: ReviewStatus.APPROVED } });
    await audit('ad.created', 'ad', ad.id, { name: ad.name });
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

app.post('/api/prices', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const input = priceCreateSchema.parse(req.body);
    const price = await prisma.priceGuide.create({ data: { ...input, areaId: input.areaId ?? null, status: ReviewStatus.PENDING } });
    await audit('price.submitted', 'priceGuide', price.id, { userId: session.userId });
    res.status(201).json({ ...price, message: 'تم إرسال السعر للمراجعة' });
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
    const updates = await prisma.nowUpdate.findMany({ where: { status: ReviewStatus.APPROVED, startsAt: { lte: now }, ...(areaId ? { OR: [{ areaId: null }, { areaId }] } : {}), AND: [{ OR: [{ endsAt: null }, { endsAt: { gte: now } }] }] }, include: { area: true, _count: { select: { helpfulVotes: true } } }, orderBy: { createdAt: 'desc' }, take: 100 });
    res.json(updates);
  } catch (error) { next(error); }
});

app.post('/api/now', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const input = nowCreateSchema.parse(req.body);
    const update = await prisma.nowUpdate.create({ data: { ...input, areaId: input.areaId ?? null, status: ReviewStatus.PENDING } });
    await audit('now.submitted', 'nowUpdate', update.id, { userId: session.userId });
    res.status(201).json({ ...update, message: 'تم إرسال التنبيه للمراجعة' });
  } catch (error) { next(error); }
});
app.post('/api/now/:id/helpful', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const nowUpdateId = String(req.params.id);
    const existing = await prisma.nowHelpful.findUnique({ where: { userId_nowUpdateId: { userId: session.userId, nowUpdateId } } });
    if (existing) await prisma.nowHelpful.delete({ where: { userId_nowUpdateId: { userId: session.userId, nowUpdateId } } });
    else await prisma.nowHelpful.create({ data: { userId: session.userId, nowUpdateId } });
    const count = await prisma.nowHelpful.count({ where: { nowUpdateId } });
    res.json({ active: !existing, count });
  } catch (error) { next(error); }
});

app.post('/api/support-tickets', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const input = z.object({ subject: z.string().trim().min(3).max(120), message: z.string().trim().min(5).max(2000) }).parse(req.body);
    const ticket = await prisma.supportTicket.create({ data: { ...input, userId: session.userId } });
    res.status(201).json({ id: ticket.id, status: ticket.status });
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
      const created = await tx.review.create({ data: { ...input, authorId: session.userId, status: ReviewStatus.APPROVED, pointsAwarded: true } });
      const author = await tx.user.findUniqueOrThrow({ where: { id: session.userId }, select: { points: true } });
      const points = author.points + 1;
      const level = points >= 100 ? 'QENAWY_ASIL' : points >= 50 ? 'QENAWY_RAYEQ' : 'QENAWY';
      await tx.user.update({ where: { id: session.userId }, data: { points, level } });
      return created;
    });
    await audit('review.created', 'review', review.id, { providerId: input.providerId });
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
    const review = await prisma.review.findUnique({ where: { id: String(req.params.id) } });
    if (!review || review.status !== ReviewStatus.APPROVED) return res.status(404).json({ message: 'التقييم غير متاح' });
    const reply = await prisma.reviewReply.create({ data: { reviewId: review.id, authorId: session.userId, text: input.text, status: ReviewStatus.PENDING }, include: { author: { select: publicAuthorSelect } } });
    res.status(201).json({ ...reply, message: 'تم إرسال الرد للمراجعة وسيظهر بعد اعتماده' });
  } catch (error) { next(error); }
});

app.post('/api/reviews/:id/helpful', async (req, res, next) => {
  try {
    const session = await sessionFromRequest(req);
    if (!session) return res.status(401).json({ message: 'سجّل الدخول أولاً' });
    const reviewId = String(req.params.id);
    const existing = await prisma.reviewHelpful.findUnique({ where: { userId_reviewId: { userId: session.userId, reviewId } } });
    if (existing) await prisma.reviewHelpful.delete({ where: { userId_reviewId: { userId: session.userId, reviewId } } });
    else await prisma.reviewHelpful.create({ data: { userId: session.userId, reviewId } });
    const count = await prisma.reviewHelpful.count({ where: { reviewId } });
    res.json({ active: !existing, count });
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

const backupName = z.string().regex(/^henaqena-[A-Za-z0-9_.-]+\.dump$/);
app.get('/api/admin/backups', requireAdmin, async (_req, res, next) => {
  try { res.json({ backups: await listDatabaseBackups(), schedule: await readBackupSchedule() }); } catch (error) { next(error); }
});
app.post('/api/admin/backups', requireAdmin, async (_req, res, next) => {
  try { const backup = await createDatabaseBackup(); await audit('database.backup_created', 'database', backup.filename); res.status(201).json({ filename: backup.filename, backups: await listDatabaseBackups() }); } catch (error) { next(error); }
});
app.delete('/api/admin/backups/:filename', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try { const filename = backupName.parse(req.params.filename); await unlink(path.join(backupRoot, filename)); await audit('database.backup_deleted', 'database', filename); res.json({ deleted: true }); } catch (error) { next(error); }
});
app.post('/api/admin/backups/restore', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try {
    const { filename, confirm } = z.object({ filename: backupName, confirm: z.literal('RESTORE_HENA_QENA') }).parse(req.body);
    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) throw new Error('DATABASE_URL غير مهيأ');
    await execFile('pg_restore', ['--clean', '--if-exists', '--no-owner', '--dbname', databaseUrl, path.join(backupRoot, filename)], { timeout: 20 * 60 * 1000 });
    await audit('database.restored', 'database', filename);
    res.json({ restored: true, filename });
  } catch (error) { next(error); }
});
app.patch('/api/admin/backups/schedule', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try {
    const input = z.object({ enabled: z.boolean(), interval: z.enum(['3d', '6d', 'week', 'month']) }).parse(req.body);
    const nextRunAt = input.enabled ? new Date(Date.now() + backupIntervals[input.interval] * 24 * 60 * 60 * 1000).toISOString() : null;
    const schedule = { ...input, nextRunAt, updatedAt: new Date().toISOString() } satisfies BackupSchedule;
    await writeBackupSchedule(schedule); await audit('database.backup_schedule_updated', 'database', 'schedule', input); res.json(schedule);
  } catch (error) { next(error); }
});

const resetScope = z.enum(['providers', 'listings', 'reviews', 'ads', 'prices', 'now', 'users', 'notifications', 'audit', 'uploads']);
app.post('/api/admin/maintenance/reset', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try {
    const { scopes, confirm } = z.object({ scopes: z.array(resetScope).min(1), confirm: z.literal('RESET_HENA_QENA') }).parse(req.body);
    const unique = [...new Set(scopes)];
    await prisma.$transaction(async (tx) => {
      if (unique.includes('reviews')) { await tx.reviewHelpful.deleteMany(); await tx.reviewReply.deleteMany(); await tx.review.deleteMany(); }
      if (unique.includes('providers')) { await tx.providerFavorite.deleteMany(); await tx.providerReport.deleteMany(); await tx.providerService.deleteMany(); await tx.providerOffer.deleteMany(); await tx.providerCategory.deleteMany(); await tx.providerImage.deleteMany(); await tx.provider.deleteMany(); }
      if (unique.includes('listings')) { await tx.listingFavorite.deleteMany(); await tx.listingInterest.deleteMany(); await tx.listingReport.deleteMany(); await tx.listingImage.deleteMany(); await tx.listing.deleteMany(); }
      if (unique.includes('ads')) { await tx.adReaction.deleteMany(); await tx.ad.deleteMany(); }
      if (unique.includes('prices')) await tx.priceGuide.deleteMany();
      if (unique.includes('now')) { await tx.nowHelpful.deleteMany(); await tx.nowUpdate.deleteMany(); }
      if (unique.includes('notifications')) await tx.notification.deleteMany();
      if (unique.includes('users')) { await tx.session.deleteMany(); await tx.verificationCode.deleteMany(); await tx.user.deleteMany({ where: { role: { not: 'SYSTEM' } } }); }
      if (unique.includes('audit')) await tx.auditLog.deleteMany();
    });
    if (unique.includes('uploads')) { await rm(uploadRoot, { recursive: true, force: true }); await mkdir(uploadRoot, { recursive: true }); }
    await audit('maintenance.reset', 'database', 'scoped-reset', { scopes: unique });
    res.json({ reset: true, scopes: unique });
  } catch (error) { next(error); }
});

app.get('/api/admin/team', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.adminAccount.findMany({ select: { id: true, name: true, email: true, role: true, isActive: true, lastLoginAt: true, createdAt: true }, orderBy: { createdAt: 'desc' } })); } catch (error) { next(error); }
});
const adminAccountSchema = z.object({ name: z.string().trim().min(2).max(80), email: z.string().email(), password: z.string().min(10).max(128), role: z.enum(['OWNER', 'REVIEWER', 'CONTENT_EDITOR', 'MODERATOR']).default('REVIEWER') });
app.post('/api/admin/team', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try { const input = adminAccountSchema.parse(req.body); const member = await prisma.adminAccount.create({ data: { name: input.name, email: input.email.toLowerCase(), passwordHash: await passwordHash(input.password), role: input.role } }); res.status(201).json({ id: member.id, name: member.name, email: member.email, role: member.role, isActive: member.isActive }); } catch (error) { next(error); }
});
app.patch('/api/admin/team/:id', requireAdminRoles(['OWNER']), async (req, res, next) => {
  try { const input = z.object({ role: z.enum(['OWNER', 'REVIEWER', 'CONTENT_EDITOR', 'MODERATOR']).optional(), isActive: z.boolean().optional(), name: z.string().trim().min(2).max(80).optional() }).parse(req.body); const member = await prisma.adminAccount.update({ where: { id: String(req.params.id) }, data: input }); res.json({ id: member.id, name: member.name, email: member.email, role: member.role, isActive: member.isActive }); } catch (error) { next(error); }
});

app.get('/api/admin/users', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.user.findMany({ select: { id: true, name: true, phone: true, email: true, points: true, level: true, role: true, createdAt: true, _count: { select: { reviews: true, listings: true, providers: true } } }, orderBy: { createdAt: 'desc' }, take: 500 })); } catch (error) { next(error); }
});

app.get('/api/admin/support-tickets', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.supportTicket.findMany({ include: { user: { select: publicAuthorSelect } }, orderBy: { createdAt: 'desc' }, take: 250 })); } catch (error) { next(error); }
});
app.patch('/api/admin/support-tickets/:id', requireAdmin, async (req, res, next) => {
  try { const { status } = z.object({ status: z.enum([ReviewStatus.APPROVED, ReviewStatus.REJECTED]) }).parse(req.body); res.json(await prisma.supportTicket.update({ where: { id: String(req.params.id) }, data: { status } })); } catch (error) { next(error); }
});
app.get('/api/admin/listing-reports', requireAdmin, async (_req, res, next) => {
  try { res.json(await prisma.listingReport.findMany({ include: { user: { select: publicAuthorSelect }, listing: { select: { id: true, title: true, status: true } } }, orderBy: { createdAt: 'desc' }, take: 250 })); } catch (error) { next(error); }
});
app.patch('/api/admin/listing-reports/:id', requireAdmin, async (req, res, next) => {
  try { const { status } = z.object({ status: z.enum([ReviewStatus.APPROVED, ReviewStatus.REJECTED]) }).parse(req.body); res.json(await prisma.listingReport.update({ where: { id: String(req.params.id) }, data: { status } })); } catch (error) { next(error); }
});

app.get('/api/admin/audit', requireAdmin, async (req, res, next) => {
  try {
    const entity = typeof req.query.entity === 'string' ? req.query.entity : undefined;
    const action = typeof req.query.action === 'string' ? req.query.action : undefined;
    const logs = await prisma.auditLog.findMany({ where: { ...(entity ? { entity } : {}), ...(action ? { action: { contains: action, mode: 'insensitive' } } : {}) }, include: { actor: { select: { name: true, email: true } } }, orderBy: { createdAt: 'desc' }, take: 250 });
    res.json(logs);
  } catch (error) { next(error); }
});
app.get('/api/admin/services', requireAdmin, async (_req, res, next) => { try { res.json(await prisma.providerService.findMany({ include: { provider: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: 250 })); } catch (error) { next(error); } });
app.get('/api/admin/offers', requireAdmin, async (_req, res, next) => { try { res.json(await prisma.providerOffer.findMany({ include: { provider: { select: { id: true, name: true } } }, orderBy: { createdAt: 'desc' }, take: 250 })); } catch (error) { next(error); } });
app.patch('/api/admin/services/:id', requireAdmin, async (req, res, next) => { try { const { status } = moderationSchema.parse(req.body); const item = await prisma.providerService.update({ where: { id: String(req.params.id) }, data: { status } }); await audit(`service.${status.toLowerCase()}`, 'providerService', item.id, { status }); res.json(item); } catch (error) { next(error); } });
app.patch('/api/admin/offers/:id', requireAdmin, async (req, res, next) => { try { const { status } = moderationSchema.parse(req.body); const item = await prisma.providerOffer.update({ where: { id: String(req.params.id) }, data: { status } }); await audit(`offer.${status.toLowerCase()}`, 'providerOffer', item.id, { status }); res.json(item); } catch (error) { next(error); } });

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

const resolveAreaId = async (areaId?: string, newAreaName?: string) => {
  if (areaId) return areaId;
  const name = (newAreaName ?? '').trim();
  if (!name) throw new Error('اختر منطقة موجودة أو اكتب اسم منطقة جديدة');
  const existing = await prisma.area.findFirst({ where: { name } });
  if (existing) return existing.id;
  const created = await prisma.area.create({ data: { name, city: 'قنا' } });
  return created.id;
};

const resolveCategoryId = async (categoryId?: string, newCategoryName?: string) => {
  if (categoryId) return categoryId;
  const name = (newCategoryName ?? '').trim();
  if (!name) throw new Error('اختر فئة موجودة أو اكتب اسم فئة جديدة');
  const slugBase = name.toLowerCase().replace(/[^a-z0-9؀-ۿ]+/g, '-').replace(/^-+|-+$/g, '') || 'category';
  const existing = await prisma.category.findFirst({ where: { OR: [{ name }, { slug: slugBase }] } });
  if (existing) return existing.id;
  const created = await prisma.category.create({ data: { name, slug: `${slugBase}-${randomBytes(3).toString('hex')}` } });
  return created.id;
};

const systemListingOwner = async () => {
  const email = 'system-admin@henaqena.internal';
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) return existing.id;
  const created = await prisma.user.create({ data: { name: 'إدارة هنا قنا', email, role: 'SYSTEM' } });
  return created.id;
};

const adminProviderCreateSchema = z.object({
  name: z.string().trim().min(2).max(120),
  description: z.string().trim().max(1000).optional(),
  phone: z.string().regex(/^01[0125][0-9]{8}$/).optional(),
  whatsapp: z.string().regex(/^01[0125][0-9]{8}$/).optional(),
  socialPlatform: socialPlatformSchema.optional(),
  socialUrl: z.string().trim().url().max(300).optional(),
  phoneType: z.enum(['BUSINESS', 'PERSONAL']).default('BUSINESS'),
  address: z.string().trim().max(240).optional(),
  areaId: z.string().min(1).optional(),
  newAreaName: z.string().trim().max(120).optional(),
  serviceMode: z.enum(['LOCAL', 'ONLINE']).default('LOCAL'),
  openingTime: z.string().max(10).optional(),
  closingTime: z.string().max(10).optional(),
  categoryId: z.string().min(1).optional(),
  newCategoryName: z.string().trim().max(120).optional(),
  isVerified: z.coerce.boolean().default(true),
  images: z.array(z.object({ url: z.string().url(), kind: z.string().max(30).optional() })).min(1).max(10),
});
app.post('/api/admin/providers', requireAdmin, async (req, res, next) => {
  try {
    const input = adminProviderCreateSchema.parse(req.body);
    const areaId = await resolveAreaId(input.areaId, input.newAreaName);
    const categoryId = await resolveCategoryId(input.categoryId, input.newCategoryName);
    const provider = await prisma.provider.create({
      data: {
        name: input.name, description: input.description, phone: input.phone, whatsapp: input.whatsapp, socialPlatform: input.socialPlatform, socialUrl: input.socialUrl, phoneType: input.phoneType, address: input.address, areaId, serviceMode: input.serviceMode, openingTime: input.openingTime, closingTime: input.closingTime,
        communityAdded: false, submissionKind: 'ADMIN', status: ReviewStatus.APPROVED, isVerified: input.isVerified,
        images: { create: input.images.map((image, index) => ({ url: image.url, kind: image.kind ?? 'work', sortOrder: index })) },
        categories: { create: [{ categoryId }] },
      },
      include: { area: true, images: true, categories: { include: { category: true } } },
    });
    await audit('provider.admin_create', 'provider', provider.id, { name: provider.name });
    res.status(201).json(provider);
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

const adminListingCreateSchema = z.object({
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().max(1200).optional(),
  category: z.string().trim().min(1).max(60),
  price: z.coerce.number().positive().max(999999999),
  areaId: z.string().min(1).optional(),
  newAreaName: z.string().trim().max(120).optional(),
  expiresInDays: z.coerce.number().int().min(1).max(365).default(90),
  images: z.array(z.string().url()).min(1).max(5),
});
app.post('/api/admin/listings', requireAdmin, async (req, res, next) => {
  try {
    const input = adminListingCreateSchema.parse(req.body);
    const areaId = await resolveAreaId(input.areaId, input.newAreaName);
    const ownerId = await systemListingOwner();
    const listing = await prisma.listing.create({
      data: { title: input.title, description: input.description, category: input.category, price: input.price, ownerId, areaId, status: ListingStatus.ACTIVE, expiresAt: new Date(Date.now() + input.expiresInDays * 24 * 60 * 60 * 1000), images: { create: input.images.map((url, index) => ({ url, sortOrder: index })) } },
      include: { area: true, images: true, owner: true },
    });
    await audit('listing.admin_create', 'listing', listing.id, { title: listing.title });
    res.status(201).json(listing);
  } catch (error) { next(error); }
});

app.get('/api/admin/ads', requireAdmin, async (_req, res, next) => {
  try {
    const ads = await prisma.ad.findMany({ include: { area: true }, orderBy: [{ weight: 'desc' }, { createdAt: 'desc' }] });
    res.json(ads);
  } catch (error) { next(error); }
});

// Platform-wide settings: home ads rotation interval, and how often the app
// re-fetches its home-page listings/categories. Public GET so every client
// (signed in or not) can sync to the same cadence.
app.get('/api/settings', async (_req, res, next) => {
  try {
    const settings = await prisma.platformSettings.upsert({ where: { id: 'default' }, update: {}, create: { id: 'default' } });
    res.json({ adRotationSeconds: settings.adRotationSeconds, dataRefreshSeconds: settings.dataRefreshSeconds });
  } catch (error) { next(error); }
});

const platformSettingsSchema = z.object({
  adRotationSeconds: z.coerce.number().int().min(2).max(60),
  dataRefreshSeconds: z.coerce.number().int().min(60).max(3600),
});
app.patch('/api/admin/settings', requireAdmin, async (req, res, next) => {
  try {
    const input = platformSettingsSchema.parse(req.body);
    const settings = await prisma.platformSettings.upsert({
      where: { id: 'default' },
      update: { adRotationSeconds: input.adRotationSeconds, dataRefreshSeconds: input.dataRefreshSeconds },
      create: { id: 'default', adRotationSeconds: input.adRotationSeconds, dataRefreshSeconds: input.dataRefreshSeconds },
    });
    await audit('settings.update', 'PlatformSettings', settings.id, { adRotationSeconds: settings.adRotationSeconds, dataRefreshSeconds: settings.dataRefreshSeconds });
    res.json({ adRotationSeconds: settings.adRotationSeconds, dataRefreshSeconds: settings.dataRefreshSeconds });
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
app.delete('/api/admin/providers/:id', requireAdmin, async (req, res, next) => {
  try {
    const provider = await prisma.provider.findUnique({ where: { id: String(req.params.id) } });
    if (!provider) return res.status(404).json({ message: 'النشاط غير موجود' });
    await prisma.provider.delete({ where: { id: provider.id } });
    await audit('provider.deleted', 'provider', provider.id, { name: provider.name });
    res.json({ deleted: true });
  } catch (error) { next(error); }
});

app.delete('/api/admin/listings/:id', requireAdmin, async (req, res, next) => {
  try { const id = String(req.params.id); const listing = await prisma.listing.findUnique({ where: { id }, select: { id: true, title: true } }); if (!listing) return res.status(404).json({ message: 'الإعلان غير موجود' }); await prisma.listing.delete({ where: { id } }); await audit('listing.deleted', 'listing', id, { title: listing.title }); res.json({ deleted: true }); } catch (error) { next(error); }
});
app.delete('/api/admin/services/:id', requireAdmin, async (req, res, next) => {
  try { const id = String(req.params.id); const item = await prisma.providerService.delete({ where: { id } }); await audit('service.deleted', 'providerService', id, { name: item.name }); res.json({ deleted: true }); } catch (error) { next(error); }
});
app.delete('/api/admin/offers/:id', requireAdmin, async (req, res, next) => {
  try { const id = String(req.params.id); const item = await prisma.providerOffer.delete({ where: { id } }); await audit('offer.deleted', 'providerOffer', id, { title: item.title }); res.json({ deleted: true }); } catch (error) { next(error); }
});
app.delete('/api/admin/ads/:id', requireAdmin, async (req, res, next) => {
  try { const id = String(req.params.id); const item = await prisma.ad.delete({ where: { id } }); await audit('ad.deleted', 'ad', id, { name: item.name }); res.json({ deleted: true }); } catch (error) { next(error); }
});

app.patch('/api/admin/providers/:id/content', requireAdmin, async (req, res, next) => {
  try {
    const input = z.object({ name: z.string().trim().min(2).max(120).optional(), description: z.string().trim().max(1000).nullable().optional(), phone: z.union([z.string().regex(/^01[0125][0-9]{8}$/), z.literal('')]).optional(), whatsapp: z.union([z.string().regex(/^01[0125][0-9]{8}$/), z.literal('')]).optional(), address: z.string().trim().max(240).nullable().optional(), openingTime: z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(), closingTime: z.string().regex(/^\d{2}:\d{2}$/).nullable().optional(), isVerified: z.boolean().optional(), ...Object.fromEntries(Object.keys(providerAttributesFields).map((key) => [key, z.boolean().optional()])) }).parse(req.body);
    const provider = await prisma.provider.update({ where: { id: String(req.params.id) }, data: { ...input, phone: input.phone === '' ? null : input.phone, whatsapp: input.whatsapp === '' ? null : input.whatsapp } });
    await audit('provider.content_updated', 'provider', provider.id, { fields: Object.keys(input) });
    res.json(provider);
  } catch (error) { next(error); }
});
app.patch('/api/admin/reviews/:id', requireAdmin, async (req, res, next) => {
  try {
    const { status, note } = moderationWithNoteSchema.parse(req.body);
    const previous = await prisma.review.findUniqueOrThrow({ where: { id: String(req.params.id) } });
    const review = await prisma.$transaction(async (tx) => {
      const shouldAward = status === ReviewStatus.APPROVED && !previous.pointsAwarded;
      const updated = await tx.review.update({ where: { id: previous.id }, data: { status, moderatedAt: new Date(), ...(shouldAward ? { pointsAwarded: true } : {}) } });
      if (shouldAward) {
        const author = await tx.user.findUniqueOrThrow({ where: { id: updated.authorId }, select: { points: true } });
        const points = author.points + 1;
        const level = points >= 100 ? 'QENAWY_ASIL' : points >= 50 ? 'QENAWY_RAYEQ' : 'QENAWY';
        await tx.user.update({ where: { id: updated.authorId }, data: { points, level } });
      }
      return updated;
    });
    await prisma.notification.create({ data: { userId: review.authorId, title: status === ReviewStatus.APPROVED ? 'تم اعتماد تقييمك' : 'لم يتم اعتماد تقييمك', body: status === ReviewStatus.APPROVED ? 'شكراً لمساهمتك في تحسين هنا قنا.' : `سبب الرفض: ${note ?? 'يرجى مراجعة محتوى التقييم.'}` } });
    await audit(`review.${status.toLowerCase()}`, 'review', review.id, { status, note });
    res.json(review);
  } catch (error) { next(error); }
});

app.delete('/api/admin/reviews/:id', requireAdmin, async (req, res, next) => {
  try {
    const input = z.object({ reason: z.string().trim().max(500).optional(), notify: z.coerce.boolean().default(false) }).parse(req.body ?? {});
    const review = await prisma.review.findUnique({ where: { id: String(req.params.id) } });
    if (!review) return res.status(404).json({ message: 'التقييم غير موجود' });
    await prisma.review.delete({ where: { id: review.id } });
    if (input.notify) {
      await prisma.notification.create({ data: { userId: review.authorId, title: 'تم حذف تقييمك', body: input.reason ? `سبب الحذف: ${input.reason}` : 'تم حذف تقييمك بواسطة الإدارة لمخالفته سياسات المنصة.' } });
    }
    await audit('review.deleted', 'review', review.id, { reason: input.reason, notified: input.notify });
    res.json({ deleted: true });
  } catch (error) { next(error); }
});

app.patch('/api/admin/replies/:id', requireAdmin, async (req, res, next) => {
  try {
    const { status, note } = moderationWithNoteSchema.parse(req.body);
    const reply = await prisma.reviewReply.update({ where: { id: String(req.params.id) }, data: { status, moderatedAt: new Date() }, include: { review: { select: { authorId: true } } } });
    await prisma.notification.create({ data: { userId: reply.authorId, title: status === ReviewStatus.APPROVED ? 'تم اعتماد ردك' : 'لم يتم اعتماد ردك', body: status === ReviewStatus.APPROVED ? 'ردك ظاهر الآن ضمن التقييمات.' : `سبب الرفض: ${note ?? 'يرجى مراجعة محتوى الرد.'}` } });
    if (status === ReviewStatus.APPROVED && reply.review.authorId !== reply.authorId) {
      await prisma.notification.create({ data: { userId: reply.review.authorId, title: 'رد جديد على تقييمك', body: 'حد رد على تقييمك في هنا قنا، افتح التقييمات لو حابب ترد.' } });
    }
    await audit(`reply.${status.toLowerCase()}`, 'reviewReply', reply.id, { status, note });
    res.json(reply);
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
app.patch('/api/admin/listings/:id/content', requireAdmin, async (req, res, next) => {
  try {
    const input = z.object({ title: z.string().trim().min(3).max(120).optional(), description: z.string().trim().max(1200).nullable().optional(), category: z.enum(['للبيع', 'للإيجار', 'وظائف', 'سيارات', 'عقارات']).optional(), price: z.number().positive().max(999999999).optional() }).parse(req.body);
    const listing = await prisma.listing.update({ where: { id: String(req.params.id) }, data: input });
    await audit('listing.content_updated', 'listing', listing.id, { fields: Object.keys(input) });
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

app.get('/api/admin/constants/:type', requireAdmin, async (req, res, next) => {
  try {
    const type = String(req.params.type);
    if (type === 'categories') {
      const items = await prisma.category.findMany({ orderBy: { name: 'asc' } });
      return res.json({ data: items });
    }
    if (type === 'areas') {
      const items = await prisma.area.findMany({ orderBy: { name: 'asc' } });
      return res.json({ data: items });
    }
    if (['service-types', 'listing-types', 'news-types'].includes(type)) {
      return res.json({ data: [] });
    }
    res.status(400).json({ message: 'نوع ثابت غير معروف' });
  } catch (error) { next(error); }
});

app.post('/api/admin/constants/:type', requireAdmin, async (req, res, next) => {
  try {
    const type = String(req.params.type);
    const { name } = z.object({ name: z.string().trim().min(1).max(120) }).parse(req.body);

    if (type === 'categories') {
      const slug = `${name.toLowerCase().replace(/[^a-z0-9؀-ۿ]+/g, '-').replace(/^-+|-+$/g, '') || 'category'}-${randomBytes(3).toString('hex')}`;
      const item = await prisma.category.create({ data: { name, slug, isActive: true } });
      await audit('category.create', 'category', item.id, { name });
      return res.json(item);
    }
    if (type === 'areas') {
      const item = await prisma.area.create({ data: { name, city: 'قنا', isActive: true } });
      await audit('area.create', 'area', item.id, { name });
      return res.json(item);
    }
    if (['service-types', 'listing-types', 'news-types'].includes(type)) {
      return res.json({ id: randomBytes(8).toString('hex'), name });
    }
    res.status(400).json({ message: 'نوع ثابت غير معروف' });
  } catch (error) { next(error); }
});

app.put('/api/admin/constants/:type/:id', requireAdmin, async (req, res, next) => {
  try {
    const type = String(req.params.type);
    const id = String(req.params.id);
    const { name } = z.object({ name: z.string().trim().min(1).max(120) }).parse(req.body);

    if (type === 'categories') {
      const item = await prisma.category.update({ where: { id }, data: { name } });
      await audit('category.update', 'category', item.id, { name });
      return res.json(item);
    }
    if (type === 'areas') {
      const item = await prisma.area.update({ where: { id }, data: { name } });
      await audit('area.update', 'area', item.id, { name });
      return res.json(item);
    }
    if (['service-types', 'listing-types', 'news-types'].includes(type)) {
      return res.json({ id, name });
    }
    res.status(400).json({ message: 'نوع ثابت غير معروف' });
  } catch (error) { next(error); }
});

app.delete('/api/admin/constants/:type/:id', requireAdmin, async (req, res, next) => {
  try {
    const type = String(req.params.type);
    const id = String(req.params.id);

    if (type === 'categories') {
      await prisma.category.delete({ where: { id } });
      await audit('category.delete', 'category', id);
      return res.json({ ok: true });
    }
    if (type === 'areas') {
      await prisma.area.delete({ where: { id } });
      await audit('area.delete', 'area', id);
      return res.json({ ok: true });
    }
    if (['service-types', 'listing-types', 'news-types'].includes(type)) {
      return res.json({ ok: true });
    }
    res.status(400).json({ message: 'نوع ثابت غير معروف' });
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

const runListingLifecycle = async () => {
  const now = new Date();
  const expiring = await prisma.listing.findMany({ where: { status: ListingStatus.ACTIVE, expiresAt: { lt: now } }, select: { id: true, ownerId: true, title: true } });
  for (const listing of expiring) {
    await prisma.$transaction([
      prisma.listing.update({ where: { id: listing.id }, data: { status: ListingStatus.EXPIRED } }),
      prisma.notification.create({ data: { userId: listing.ownerId, title: 'انتهت مدة إعلانك', body: `إعلان «${listing.title}» انتهت مدته. افتح «إعلاناتي» خلال 3 أيام لإعادة نشره.` } }),
    ]);
  }
  const cleanupBefore = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);
  const stale = await prisma.listing.findMany({ where: { status: ListingStatus.EXPIRED, expiresAt: { lt: cleanupBefore } }, include: { images: true } });
  for (const listing of stale) {
    await prisma.listing.delete({ where: { id: listing.id } });
    await Promise.all(listing.images.map(async (image) => {
      try {
        const pathname = new URL(image.url).pathname;
        if (pathname.startsWith('/uploads/providers/')) await unlink(path.join(uploadRoot, 'providers', path.basename(pathname)));
      } catch { /* Missing files do not block lifecycle cleanup. */ }
    }));
  }
};

app.listen(port, host, () => {
  console.log(`Hena Qena API listening on http://${host}:${port}`);
  if (process.env.ENABLE_BACKGROUND_JOBS !== 'false') {
    void runListingLifecycle().catch((error) => console.error('[listing-lifecycle]', error));
    const lifecycleTimer = setInterval(() => void runListingLifecycle().catch((error) => console.error('[listing-lifecycle]', error)), 6 * 60 * 60 * 1000);
    lifecycleTimer.unref();
    startBackupScheduler();
    backupTimer?.unref();
  }
});
