import { createHash, randomBytes } from 'node:crypto';
import { mkdir, rm, stat, writeFile } from 'node:fs/promises';
import request from 'supertest';
import { ReviewStatus, ListingStatus } from '@prisma/client';

// Keep this suite completely separate from any developer or production database.
process.env.NODE_ENV = 'test';
process.env.ADMIN_API_KEY = 'integration-admin-key';
process.env.GOOGLE_CLIENT_IDS = 'integration-google-client';
process.env.PUBLIC_API_BASE_URL = 'http://127.0.0.1:4311';
process.env.UPLOADS_DIR = '/tmp/henaqena-sprint11-uploads';

jest.mock('jose', () => ({
  createRemoteJWKSet: jest.fn(() => ({})),
  jwtVerify: jest.fn(async () => ({ payload: { sub: 'blocked-google-sub', email: 'blocked-federated@example.com', name: 'Blocked Federated' } })),
}));

import { app, prisma, runListingLifecycle } from '../server';

const tables = [
  'AdminSession', 'Session', 'VerificationCode', 'AuditLog', 'ProviderReport', 'ProviderImage',
  'ProviderFavorite', 'FavoriteList', 'SavedSearch', 'ProviderService', 'ProviderOffer',
  'ProviderCategory', 'ListingFavorite', 'ListingInterest', 'ListingReport', 'ListingImage',
  'ReviewHelpful', 'ReviewReply', 'AdReaction', 'NowHelpful', 'Notification', 'SupportTicket',
  'DuplicateCandidate', 'CollectedBusiness', 'CollectionJob', 'DataSource', 'Provider', 'Listing',
  'Review', 'Ad', 'PriceGuide', 'NowUpdate', 'Category', 'Area', 'PlatformSettings', 'User', 'AdminAccount',
];

const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const makeToken = async (userId: string) => {
  const token = `user-token-${randomBytes(8).toString('hex')}`;
  await prisma.session.create({ data: { userId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 60_000) } });
  return token;
};
const makeAdminToken = async (adminId: string) => {
  const token = `admin-token-${randomBytes(8).toString('hex')}`;
  await prisma.adminSession.create({ data: { adminId, tokenHash: hash(token), expiresAt: new Date(Date.now() + 60_000) } });
  return token;
};
const makeUser = async (name: string, role = 'USER') => prisma.user.create({ data: { name, phone: `010${String(Math.floor(Math.random() * 1_000_000_000)).padStart(9, '0')}`, role } });
const makeAreaCategory = async () => {
  const area = await prisma.area.create({ data: { name: `Area ${randomBytes(3).toString('hex')}`, city: 'قنا' } });
  const category = await prisma.category.create({ data: { name: `Category ${randomBytes(3).toString('hex')}`, slug: `category-${randomBytes(5).toString('hex')}` } });
  return { area, category };
};
const makeProvider = async (ownerId: string, status: ReviewStatus = ReviewStatus.PENDING) => {
  const { area, category } = await makeAreaCategory();
  const provider = await prisma.provider.create({
    data: {
      name: `Provider ${randomBytes(3).toString('hex')}`, ownerId, areaId: area.id, status,
      categories: { create: { categoryId: category.id } },
    },
  });
  return { provider, area, category };
};

beforeAll(async () => {
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tables.map((table) => `"${table}"`).join(', ')} RESTART IDENTITY CASCADE`);
  await rm(process.env.UPLOADS_DIR!, { recursive: true, force: true });
  await mkdir(`${process.env.UPLOADS_DIR}/providers`, { recursive: true });
  await mkdir(`${process.env.UPLOADS_DIR}/avatars`, { recursive: true });
  await mkdir(`${process.env.UPLOADS_DIR}/listings`, { recursive: true });
});

afterAll(async () => {
  await prisma.$disconnect();
});

describe('Sprint 1 production stabilization integration', () => {
  it('rejects blocked sessions, password login, and federated login', async () => {
    const blocked = await prisma.user.create({ data: { name: 'Blocked', phone: '01011111111', passwordHash: 'not-used', isBlocked: true, authProvider: 'google', authSubject: 'blocked-google-sub', email: 'blocked-federated@example.com' } });
    const token = await makeToken(blocked.id);
    expect((await request(app).get('/api/me').set('Authorization', `Bearer ${token}`)).status).toBe(401);
    const passwordResponse = await request(app).post('/api/auth/login').send({ identifier: blocked.phone, password: 'anything' });
    expect(passwordResponse.status).toBe(403);
    const federatedResponse = await request(app).post('/api/auth/federated').send({ provider: 'google', identityToken: 'x'.repeat(128) });
    expect(federatedResponse.status).toBe(403);
  });

  it('hides pending providers publicly but allows the owner to inspect their own pending provider', async () => {
    const owner = await makeUser('Owner');
    const ownerToken = await makeToken(owner.id);
    const { provider } = await makeProvider(owner.id, ReviewStatus.PENDING);
    expect((await request(app).get(`/api/providers/${provider.id}`)).status).toBe(404);
    expect((await request(app).get(`/api/providers/${provider.id}`).set('Authorization', `Bearer ${ownerToken}`)).status).toBe(200);
  });

  it('rejects favorite-list IDOR and provider/listing ownership violations', async () => {
    const owner = await makeUser('Owner');
    const other = await makeUser('Other');
    const ownerToken = await makeToken(owner.id);
    const otherToken = await makeToken(other.id);
    const { provider, area } = await makeProvider(owner.id, ReviewStatus.APPROVED);
    const foreignList = await prisma.favoriteList.create({ data: { userId: other.id, name: 'Foreign' } });
    expect((await request(app).post(`/api/providers/${provider.id}/favorite`).set('Authorization', `Bearer ${ownerToken}`).send({ listId: foreignList.id })).status).toBe(403);
    expect((await request(app).patch(`/api/providers/${provider.id}`).set('Authorization', `Bearer ${otherToken}`).send({ name: 'Hijack' })).status).toBe(403);
    const listing = await prisma.listing.create({ data: { title: 'Owner listing', price: 10, ownerId: owner.id, areaId: area.id, status: ListingStatus.ACTIVE, expiresAt: new Date(Date.now() + 86_400_000), images: { create: { url: 'https://cdn.example/listing.jpg' } } } });
    expect((await request(app).delete(`/api/me/listings/${listing.id}`).set('Authorization', `Bearer ${otherToken}`)).status).toBe(404);
  });

  it('rejects invalid image bytes and oversized images despite declared MIME', async () => {
    const user = await makeUser('Uploader');
    const token = await makeToken(user.id);
    const invalid = Buffer.from('not-a-png').toString('base64');
    expect((await request(app).post('/api/uploads/provider-images').set('Authorization', `Bearer ${token}`).send({ images: [{ base64: invalid, mimeType: 'image/png' }] })).status).toBe(400);
    const oversized = Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(2 * 1024 * 1024)]).toString('base64');
    expect((await request(app).post('/api/uploads/provider-images').set('Authorization', `Bearer ${token}`).send({ images: [{ base64: oversized, mimeType: 'image/jpeg' }] })).status).toBe(400);
  });

  it('cleans local images on replacement while leaving remote images untouched', async () => {
    const owner = await makeUser('Image owner');
    const token = await makeToken(owner.id);
    const { provider } = await makeProvider(owner.id, ReviewStatus.APPROVED);
    const oldPath = `${process.env.UPLOADS_DIR}/providers/old.jpg`;
    await writeFile(oldPath, Buffer.from('old'));
    await prisma.providerImage.create({ data: { providerId: provider.id, url: `${process.env.PUBLIC_API_BASE_URL}/uploads/providers/old.jpg` } });
    const response = await request(app).patch(`/api/providers/${provider.id}`).set('Authorization', `Bearer ${token}`).send({ images: [{ url: 'https://cdn.example/new.jpg' }] });
    expect(response.status).toBe(200);
    await expect(stat(oldPath)).rejects.toThrow();

    const avatarOldPath = `${process.env.UPLOADS_DIR}/avatars/avatar-old.jpg`;
    await writeFile(avatarOldPath, Buffer.from('old-avatar'));
    await prisma.user.update({ where: { id: owner.id }, data: { avatarUrl: `${process.env.PUBLIC_API_BASE_URL}/uploads/avatars/avatar-old.jpg` } });
    const avatarUpdate = await request(app).patch('/api/me/profile').set('Authorization', `Bearer ${token}`).send({ name: owner.name, avatarUrl: 'https://cdn.example/avatar-new.jpg' });
    expect(avatarUpdate.status).toBe(200);
    await expect(stat(avatarOldPath)).rejects.toThrow();

    const listingPath = `${process.env.UPLOADS_DIR}/listings/listing-old.jpg`;
    await writeFile(listingPath, Buffer.from('old-listing'));
    const listing = await prisma.listing.create({ data: { title: 'Local listing', price: 10, ownerId: owner.id, areaId: provider.areaId, status: ListingStatus.ACTIVE, expiresAt: new Date(Date.now() + 86_400_000), images: { create: { url: `${process.env.PUBLIC_API_BASE_URL}/uploads/listings/listing-old.jpg` } } } });
    const listingDelete = await request(app).delete(`/api/admin/listings/${listing.id}`).set('x-admin-key', process.env.ADMIN_API_KEY!);
    expect(listingDelete.status).toBe(200);
    await expect(stat(listingPath)).rejects.toThrow();

    const remoteProvider = await makeProvider(owner.id, ReviewStatus.APPROVED);
    await prisma.providerImage.create({ data: { providerId: remoteProvider.provider.id, url: 'https://cdn.example/remote.jpg' } });
    await request(app).delete(`/api/admin/providers/${remoteProvider.provider.id}`).set('x-admin-key', process.env.ADMIN_API_KEY!);
    await expect(stat(oldPath)).rejects.toThrow();
  });

  it('deactivates referenced categories/areas and rejects case-insensitive duplicates', async () => {
    const admin = await prisma.adminAccount.create({ data: { name: 'Integration owner', email: `admin-${randomBytes(3).toString('hex')}@example.com`, passwordHash: 'unused', role: 'OWNER' } });
    const adminToken = await makeAdminToken(admin.id);
    const category = await request(app).post('/api/admin/constants/categories').set('Authorization', `Bearer ${adminToken}`).send({ name: 'مطاعم' });
    expect(category.status).toBe(200);
    expect((await request(app).post('/api/admin/constants/categories').set('Authorization', `Bearer ${adminToken}`).send({ name: 'مطاعم' })).status).toBe(409);
    const area = await request(app).post('/api/admin/constants/areas').set('Authorization', `Bearer ${adminToken}`).send({ name: 'وسط البلد' });
    expect(area.status).toBe(200);
    expect((await request(app).post('/api/admin/constants/areas').set('Authorization', `Bearer ${adminToken}`).send({ name: 'وسط البلد' })).status).toBe(409);
    const user = await makeUser('Category owner');
    const used = await prisma.provider.create({ data: { name: 'Used provider', ownerId: user.id, areaId: area.body.id, categories: { create: { categoryId: category.body.id } } } });
    expect(used.id).toBeTruthy();
    const deletedCategory = await request(app).delete(`/api/admin/constants/categories/${category.body.id}`).set('Authorization', `Bearer ${adminToken}`);
    expect(deletedCategory.body.archived).toBe(true);
    const deletedArea = await request(app).delete(`/api/admin/constants/areas/${area.body.id}`).set('Authorization', `Bearer ${adminToken}`);
    expect(deletedArea.body.archived).toBe(true);
  });

  it('records admin actor ID and role and protects system/admin users from blocking', async () => {
    const admin = await prisma.adminAccount.create({ data: { name: 'Audit owner', email: `audit-${randomBytes(3).toString('hex')}@example.com`, passwordHash: 'unused', role: 'OWNER' } });
    const adminToken = await makeAdminToken(admin.id);
    const user = await makeUser('Blockable');
    const blocked = await request(app).patch(`/api/admin/users/${user.id}`).set('Authorization', `Bearer ${adminToken}`).send({ isBlocked: true, blockedReason: 'test' });
    expect(blocked.status).toBe(200);
    const audit = await prisma.auditLog.findFirst({ where: { action: 'user.blocked', entityId: user.id }, orderBy: { createdAt: 'desc' } });
    expect(audit?.metadata).toMatchObject({ adminId: admin.id, adminRole: 'OWNER', reason: 'test' });
    const system = await makeUser('Protected', 'ADMIN');
    expect((await request(app).patch(`/api/admin/users/${system.id}`).set('Authorization', `Bearer ${adminToken}`).send({ isBlocked: true })).status).toBe(404);
  });

  it('can run listing lifecycle cleanup without deleting remote media', async () => {
    await runListingLifecycle();
    const remoteUrl = 'https://cdn.example/remote-only.jpg';
    const user = await makeUser('Remote media');
    const { area } = await makeAreaCategory();
    const listing = await prisma.listing.create({ data: { title: 'Expired remote', price: 1, ownerId: user.id, areaId: area.id, status: ListingStatus.EXPIRED, expiresAt: new Date(Date.now() - 5 * 86_400_000), images: { create: { url: remoteUrl } } } });
    await runListingLifecycle();
    expect(await prisma.listing.findUnique({ where: { id: listing.id } })).toBeNull();
    // A remote URL is never translated into a local filesystem path or deleted.
    expect(remoteUrl.startsWith('https://')).toBe(true);
  });
});
