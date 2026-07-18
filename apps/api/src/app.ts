import cors from 'cors';
import express from 'express';
import { PrismaClient, ReviewStatus, ListingStatus } from '@prisma/client';
import { z } from 'zod';
import { createHash, randomBytes, randomInt, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';

export function createApp(prismaClient?: PrismaClient) {
  const prisma = prismaClient || new PrismaClient();
  const app = express();
  const scrypt = promisify(scryptCallback);
  const hash = (value: string) => createHash('sha256').update(value).digest('hex');
  const passwordHash = async (password: string) => { const salt = randomBytes(16); const derived = await scrypt(password, salt, 64) as Buffer; return `${salt.toString('hex')}:${derived.toString('hex')}`; };
  const verifyPassword = async (password: string, stored: string) => { const [saltHex, storedHash] = stored.split(':'); const salt = Buffer.from(saltHex, 'hex'); const derived = await scrypt(password, salt, 64) as Buffer; return derived.toString('hex') === storedHash; };

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

  const issueSession = async (userId: string) => { const token = randomBytes(32).toString('hex'); await prisma.session.create({ data: { userId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) } }); return token; };
  const sessionFromRequest = async (req: express.Request) => { const token = typeof req.headers.authorization === 'string' ? req.headers.authorization.replace(/^Bearer\s+/i, '') : ''; if (!token) return null; const session = await prisma.session.findUnique({ where: { tokenHash: hash(token) }, include: { user: true } }); return session && session.expiresAt > new Date() ? session : null; };
  const requireAdmin = (req: express.Request, res: express.Response, next: express.NextFunction) => { const expected = process.env.ADMIN_API_KEY ?? (process.env.NODE_ENV !== 'production' ? 'dev-henaqena-admin' : undefined); const provided = typeof req.headers['x-admin-key'] === 'string' ? req.headers['x-admin-key'] : ''; if (!expected || provided !== expected) return res.status(403).json({ message: 'صلاحيات الإدارة مطلوبة' }); next(); };
  const audit = (action: string, entity: string, entityId: string, metadata?: Record<string, unknown>) => prisma.auditLog.create({ data: { action, entity, entityId, metadata: metadata as any } });

  app.use(cors());
  app.use(express.json({ limit: '2mb' }));

  const authLimiter = createRateLimiter(5, 15 * 60 * 1000);
  const verificationLimiter = createRateLimiter(10, 60 * 60 * 1000);

  // Health endpoint
  app.get('/health', (_req, res) => res.json({ ok: true, service: 'hena-qena-api' }));

  // Auth endpoints
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

  // Public endpoints
  app.get('/api/areas', async (_req, res, next) => {
    try {
      const areas = await prisma.area.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } });
      res.json(areas);
    } catch (error) { next(error); }
  });

  app.get('/api/categories', async (_req, res, next) => {
    try { res.json(await prisma.category.findMany({ where: { isActive: true }, orderBy: { name: 'asc' } })); } catch (error) { next(error); }
  });

  // 404 handler
  app.use((_req: express.Request, res: express.Response) => {
    res.status(404).json({ message: 'المسار غير موجود' });
  });

  // Error handler
  app.use((error: unknown, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
    if (error instanceof z.ZodError) {
      const formatted = error.issues.map(issue => ({ path: issue.path.join('.'), message: issue.message }));
      return res.status(400).json({ message: 'بيانات المدخلات غير صحيحة', errors: formatted });
    }
    if (error instanceof Error && error.message.includes('Unique constraint')) {
      return res.status(409).json({ message: 'البيانات موجودة بالفعل' });
    }
    console.error('[API Error]', error);
    res.status(500).json({ message: 'خطأ في الخادم - يرجى المحاولة لاحقاً' });
  });

  return app;
}
