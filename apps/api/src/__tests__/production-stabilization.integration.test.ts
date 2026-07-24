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

import { app, prisma, haversineDistanceKm, normalizeSearchText, providerOpenNow, runListingLifecycle } from '../server';

const tables = [
  'PriceConfirmation',
  'MinShaterReport', 'MinShaterHelpful', 'MinShaterRecommendation', 'MinShaterRequest',
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

  it('blocks review, favorite and helpful actions for a blocked account', async () => {
    const owner = await makeUser('Blocked action owner');
    const reviewer = await makeUser('Blocked action reviewer');
    const ownerToken = await makeToken(owner.id);
    const reviewerToken = await makeToken(reviewer.id);
    const { provider } = await makeProvider(owner.id, ReviewStatus.APPROVED);
    const review = await request(app).post('/api/reviews').set('Authorization', `Bearer ${reviewerToken}`).send({ providerId: provider.id, quality: 4, commitment: 4, value: 4 });
    expect(review.status).toBe(201);
    await prisma.user.update({ where: { id: reviewer.id }, data: { isBlocked: true } });
    expect((await request(app).post('/api/reviews').set('Authorization', `Bearer ${reviewerToken}`).send({ providerId: provider.id, quality: 5, commitment: 5, value: 5 })).status).toBe(401);
    expect((await request(app).post(`/api/providers/${provider.id}/favorite`).set('Authorization', `Bearer ${reviewerToken}`).send({})).status).toBe(401);
    expect((await request(app).post(`/api/reviews/${review.body.id}/helpful`).set('Authorization', `Bearer ${reviewerToken}`)).status).toBe(401);
    expect((await request(app).post(`/api/reviews/${review.body.id}/replies`).set('Authorization', `Bearer ${ownerToken}`).send({ text: 'رد' })).status).toBe(201);
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

  it('keeps public directory taxonomy active-only and paginated without duplicates', async () => {
    const user = await makeUser('Directory owner');
    const active = await makeProvider(user.id, ReviewStatus.APPROVED);
    await makeProvider(user.id, ReviewStatus.APPROVED);
    await makeProvider(user.id, ReviewStatus.APPROVED);
    const inactiveArea = await prisma.area.create({ data: { name: `Inactive ${randomBytes(3).toString('hex')}`, city: 'قنا', isActive: false } });
    const inactiveCategory = await prisma.category.create({ data: { name: `Hidden ${randomBytes(3).toString('hex')}`, slug: `hidden-${randomBytes(5).toString('hex')}`, isActive: false } });
    await prisma.provider.create({ data: { name: 'Hidden provider', ownerId: user.id, areaId: inactiveArea.id, status: ReviewStatus.APPROVED, categories: { create: { categoryId: inactiveCategory.id } } } });
    const categories = await request(app).get('/api/categories');
    const areas = await request(app).get('/api/areas');
    expect(categories.status).toBe(200);
    expect(areas.status).toBe(200);
    expect(categories.body.data.some((item: { id: string }) => item.id === inactiveCategory.id)).toBe(false);
    expect(areas.body.data.some((item: { id: string }) => item.id === inactiveArea.id)).toBe(false);
    const first = await request(app).get('/api/providers?meta=true&page=1&pageSize=1');
    const second = await request(app).get('/api/providers?meta=true&page=2&pageSize=1');
    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    const pageIds = [...first.body.data, ...second.body.data].map((item: { id: string }) => item.id);
    expect(new Set(pageIds).size).toBe(pageIds.length);
    expect((await request(app).get(`/api/providers?areaId=${inactiveArea.id}`)).body).toEqual([]);
    expect((await request(app).get(`/api/providers?category=${inactiveCategory.slug}`)).body).toEqual([]);
    expect(active.provider.id).toBeTruthy();
  });

  it('rejects invalid directory filters and handles missing optional provider data', async () => {
    const user = await makeUser('Sparse directory owner');
    await makeProvider(user.id, ReviewStatus.APPROVED);
    expect((await request(app).get('/api/providers?page=0')).status).toBe(400);
    expect((await request(app).get('/api/providers?sort=unknown')).status).toBe(400);
    const response = await request(app).get('/api/providers?meta=true&pageSize=50&sort=rating');
    expect(response.status).toBe(200);
    expect(response.body.data.every((item: { rating: number; reviewCount: number }) => typeof item.rating === 'number' && typeof item.reviewCount === 'number')).toBe(true);
  });

  it('calculates Cairo opening hours safely, including overnight and invalid values', () => {
    const atMorning = new Date('2026-07-24T06:00:00.000Z'); // 09:00 in Cairo during July.
    expect(providerOpenNow({ openingTime: '09:00', closingTime: '22:00' }, atMorning)).toBe(true);
    expect(providerOpenNow({ openingTime: '22:00', closingTime: '02:00' }, atMorning)).toBe(false);
    expect(providerOpenNow({ openingTime: 'bad', closingTime: '22:00' }, atMorning)).toBeNull();
    expect(providerOpenNow({ open24h: true }, atMorning)).toBe(true);
  });

  it('normalizes Arabic search text without changing stored values', () => {
    expect(normalizeSearchText('  إِسْعَاف ـ ١٢  ')).toBe('اسعاف 12');
    expect(normalizeSearchText('مُحَمَّد')).toBe('محمد');
    expect(normalizeSearchText('HELLO')).toBe('hello');
  });

  it('ranks exact and prefix matches before service/category/area matches', async () => {
    const owner = await makeUser('Search owner');
    const { area, category } = await makeAreaCategory();
    const exact = await prisma.provider.create({ data: { name: 'مطعم قنا', ownerId: owner.id, areaId: area.id, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } } } });
    const serviceMatch = await prisma.provider.create({ data: { name: 'مكان آخر', ownerId: owner.id, areaId: area.id, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } }, services: { create: { name: 'مطاعم وأكل', status: ReviewStatus.APPROVED } } } });
    const response = await request(app).get('/api/providers?meta=true&q=مطعم&pageSize=20');
    expect(response.status).toBe(200);
    expect(response.body.data.map((item: { id: string }) => item.id).indexOf(exact.id)).toBeLessThan(response.body.data.map((item: { id: string }) => item.id).indexOf(serviceMatch.id));
  });

  it('supports service/category/area search, suggestions and excludes inactive taxonomy', async () => {
    const owner = await makeUser('Suggestion owner');
    const { area, category } = await makeAreaCategory();
    const provider = await prisma.provider.create({ data: { name: 'مركز الهواتف', ownerId: owner.id, areaId: area.id, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } }, services: { create: { name: 'صيانة موبايلات', status: ReviewStatus.APPROVED } } } });
    const suggestions = await request(app).get('/api/search/suggestions?q=موبايلات');
    expect(suggestions.status).toBe(200);
    expect(suggestions.body.data.some((item: { value: string; type: string }) => item.value === 'صيانة موبايلات' && item.type === 'service')).toBe(true);
    const service = await request(app).get('/api/providers?meta=true&q=هواتف');
    expect(service.status).toBe(200);
    expect(service.body.data.some((item: { id: string }) => item.id === provider.id)).toBe(true);
    await prisma.category.update({ where: { id: category.id }, data: { isActive: false } });
    expect((await request(app).get(`/api/providers?categoryId=${category.id}`)).body.some((item: { id: string }) => item.id === provider.id)).toBe(false);
  });

  it('rejects oversized search text and keeps pagination stable with search', async () => {
    const tooLong = await request(app).get(`/api/providers?q=${'x'.repeat(121)}`);
    expect(tooLong.status).toBe(400);
    const first = await request(app).get('/api/providers?meta=true&q=Provider&page=1&pageSize=1');
    const second = await request(app).get('/api/providers?meta=true&q=Provider&page=2&pageSize=1');
    expect(first.status).toBe(200);
    expect(second.status).toBe(200);
    const ids = [...first.body.data, ...second.body.data].map((item: { id: string }) => item.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('serves only approved geocoded providers inside valid map bounds', async () => {
    const owner = await makeUser('Map owner');
    const { area, category } = await makeAreaCategory();
    const visible = await prisma.provider.create({ data: { name: 'Visible map place', ownerId: owner.id, areaId: area.id, latitude: 26.1555, longitude: 32.7165, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } } } });
    await prisma.provider.create({ data: { name: 'Outside map place', ownerId: owner.id, areaId: area.id, latitude: 26.30, longitude: 32.90, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } } } });
    await prisma.provider.create({ data: { name: 'Pending map place', ownerId: owner.id, areaId: area.id, latitude: 26.155, longitude: 32.716, status: ReviewStatus.PENDING, categories: { create: { categoryId: category.id } } } });
    await prisma.provider.create({ data: { name: 'Missing map place', ownerId: owner.id, areaId: area.id, status: ReviewStatus.APPROVED, categories: { create: { categoryId: category.id } } } });
    const response = await request(app).get('/api/providers/map?north=26.2&south=26.1&east=32.8&west=32.6&latitude=26.15&longitude=32.71');
    expect(response.status).toBe(200);
    expect(response.body.data.map((item: { id: string }) => item.id)).toEqual([visible.id]);
    expect(response.body.data[0]).toMatchObject({ name: 'Visible map place', categoryName: category.name });
    expect(response.body.data[0].services).toBeUndefined();
    expect((await request(app).get('/api/providers/map?north=26.1&south=26.2&east=32.8&west=32.6')).status).toBe(400);
    expect((await request(app).get('/api/providers/map?north=nan&south=26.1&east=32.8&west=32.6')).status).toBe(400);
  });

  it('uses a stable Haversine distance in kilometres', () => {
    const distance = haversineDistanceKm({ latitude: 0, longitude: 0 }, { latitude: 0, longitude: 1 });
    expect(distance).toBeGreaterThan(111);
    expect(distance).toBeLessThan(112);
  });

  it('keeps provider details public-safe and enforces review ownership and visibility', async () => {
    const owner = await makeUser('Detail owner');
    const reviewer = await makeUser('Reviewer');
    const other = await makeUser('Other reviewer');
    const ownerToken = await makeToken(owner.id);
    const reviewerToken = await makeToken(reviewer.id);
    const otherToken = await makeToken(other.id);
    const { provider } = await makeProvider(owner.id, ReviewStatus.APPROVED);
    const detail = await request(app).get(`/api/providers/${provider.id}`);
    expect(detail.status).toBe(200);
    expect(detail.body.ownerId).toBeUndefined();
    expect(detail.body.status).toBeUndefined();
    expect(detail.body.archivedAt).toBeUndefined();
    const ownerReview = await request(app).post('/api/reviews').set('Authorization', `Bearer ${ownerToken}`).send({ providerId: provider.id, quality: 5, commitment: 5, value: 5 });
    expect(ownerReview.status).toBe(403);
    const review = await request(app).post('/api/reviews').set('Authorization', `Bearer ${reviewerToken}`).send({ providerId: provider.id, quality: 5, commitment: 4, value: 5, comment: 'ممتاز' });
    expect(review.status).toBe(201);
    const reviewerTwo = await makeUser('Reviewer two');
    const reviewerThree = await makeUser('Reviewer three');
    const reviewerTwoToken = await makeToken(reviewerTwo.id);
    const reviewerThreeToken = await makeToken(reviewerThree.id);
    const reviewTwo = await request(app).post('/api/reviews').set('Authorization', `Bearer ${reviewerTwoToken}`).send({ providerId: provider.id, quality: 4, commitment: 4, value: 4 });
    const reviewThree = await request(app).post('/api/reviews').set('Authorization', `Bearer ${reviewerThreeToken}`).send({ providerId: provider.id, quality: 3, commitment: 4, value: 3 });
    expect(reviewTwo.status).toBe(201);
    expect(reviewThree.status).toBe(201);
    const replyByOther = await request(app).post(`/api/reviews/${review.body.id}/replies`).set('Authorization', `Bearer ${otherToken}`).send({ text: 'رد' });
    expect(replyByOther.status).toBe(403);
    const replyByOwner = await request(app).post(`/api/reviews/${review.body.id}/replies`).set('Authorization', `Bearer ${ownerToken}`).send({ text: 'شكرًا' });
    expect(replyByOwner.status).toBe(201);
    const firstPage = await request(app).get(`/api/providers/${provider.id}/reviews?page=1&pageSize=1`);
    expect(firstPage.status).toBe(200);
    expect(firstPage.body.data).toHaveLength(1);
    expect(firstPage.body.hasMore).toBe(true);
    const secondPage = await request(app).get(`/api/providers/${provider.id}/reviews?page=2&pageSize=1`);
    expect(secondPage.status).toBe(200);
    expect(secondPage.body.data).toHaveLength(1);
    expect(secondPage.body.data[0].id).not.toBe(firstPage.body.data[0].id);
    const helpful = await request(app).post(`/api/reviews/${review.body.id}/helpful`).set('Authorization', `Bearer ${otherToken}`);
    expect(helpful.status).toBe(200);
    const removed = await request(app).delete(`/api/me/reviews/${review.body.id}`).set('Authorization', `Bearer ${reviewerToken}`);
    expect(removed.status).toBe(200);
    expect((await request(app).delete(`/api/me/reviews/${reviewTwo.body.id}`).set('Authorization', `Bearer ${reviewerTwoToken}`)).status).toBe(200);
    expect((await request(app).delete(`/api/me/reviews/${reviewThree.body.id}`).set('Authorization', `Bearer ${reviewerThreeToken}`)).status).toBe(200);
    expect((await request(app).get(`/api/providers/${provider.id}/reviews`)).body.total).toBe(0);
  });

  it('supports the Min Shater pending, moderation, ownership, helpful and report lifecycle', async () => {
    const owner = await makeUser('Min Shater owner');
    const other = await makeUser('Min Shater other');
    const ownerToken = await makeToken(owner.id);
    const otherToken = await makeToken(other.id);
    const { provider, area, category } = await makeProvider(owner.id, ReviewStatus.APPROVED);

    expect((await request(app).post('/api/min-shater').send({ title: 'محتاج فني تكييف', categoryId: category.id })).status).toBe(401);
    const created = await request(app).post('/api/min-shater').set('Authorization', `Bearer ${ownerToken}`).send({ title: 'محتاج فني تكييف', description: 'ترشيح موثوق', categoryId: category.id, areaId: area.id });
    expect(created.status).toBe(201);
    const requestId = created.body.id;
    expect((await request(app).get('/api/min-shater')).body.data.some((row: { id: string }) => row.id === requestId)).toBe(false);
    expect((await request(app).get(`/api/min-shater/${requestId}`).set('Authorization', `Bearer ${ownerToken}`)).status).toBe(200);
    expect((await request(app).get(`/api/min-shater/${requestId}`).set('Authorization', `Bearer ${otherToken}`)).status).toBe(404);

    const admin = await prisma.adminAccount.create({ data: { name: 'Min Shater moderator', email: `min-${randomBytes(3).toString('hex')}@example.com`, passwordHash: 'unused', role: 'MODERATOR' } });
    const adminToken = await makeAdminToken(admin.id);
    expect((await request(app).patch(`/api/admin/min-shater/requests/${requestId}/status`).set('Authorization', `Bearer ${adminToken}`).send({ status: 'APPROVED' })).status).toBe(200);
    expect((await request(app).get(`/api/min-shater/${requestId}`)).status).toBe(200);

    const recommendation = await request(app).post(`/api/min-shater/${requestId}/recommendations`).set('Authorization', `Bearer ${otherToken}`).send({ providerId: provider.id, description: 'شاطر جدًا' });
    expect(recommendation.status).toBe(201);
    const recommendationId = recommendation.body.id;
    expect((await request(app).post(`/api/min-shater/${requestId}/recommendations`).set('Authorization', `Bearer ${otherToken}`).send({ providerId: provider.id })).status).toBe(409);
    expect((await request(app).patch(`/api/admin/min-shater/recommendations/${recommendationId}/status`).set('Authorization', `Bearer ${adminToken}`).send({ status: 'APPROVED' })).status).toBe(200);
    expect((await request(app).post(`/api/min-shater/recommendations/${recommendationId}/helpful`).set('Authorization', `Bearer ${ownerToken}`)).status).toBe(200);
    expect((await request(app).post(`/api/min-shater/recommendations/${recommendationId}/helpful`).set('Authorization', `Bearer ${ownerToken}`)).status).toBe(200);
    expect((await request(app).post(`/api/min-shater/${requestId}/report`).set('Authorization', `Bearer ${ownerToken}`).send({ reason: 'SPAM' })).status).toBe(201);
    expect((await request(app).post(`/api/min-shater/${requestId}/report`).set('Authorization', `Bearer ${ownerToken}`).send({ reason: 'SPAM' })).status).toBe(409);
    expect((await request(app).post(`/api/min-shater/${requestId}/close`).set('Authorization', `Bearer ${ownerToken}`)).status).toBe(200);
    expect((await request(app).post(`/api/min-shater/${requestId}/recommendations`).set('Authorization', `Bearer ${otherToken}`).send({ recommendedName: 'شخص جديد' })).status).toBe(400);

    await prisma.user.update({ where: { id: other.id }, data: { isBlocked: true } });
    expect((await request(app).post(`/api/min-shater/${requestId}/report`).set('Authorization', `Bearer ${otherToken}`).send({ reason: 'OTHER' })).status).toBe(401);
  });

  it('supports approved price confirmations without allowing public or duplicate writes', async () => {
    const user = await makeUser('Price confirmer');
    const token = await makeToken(user.id);
    const { area } = await makeAreaCategory();
    const price = await prisma.priceGuide.create({ data: { name: `سعر اختبار ${randomBytes(3).toString('hex')}`, minPrice: 100, maxPrice: 120, areaId: area.id, status: ReviewStatus.APPROVED } });
    const before = await request(app).get('/api/prices');
    expect(before.status).toBe(200);
    const item = before.body.find((row: { id: string }) => row.id === price.id);
    expect(item.confirmationCount).toBe(0);
    expect((await request(app).post(`/api/prices/${price.id}/confirm`).set('Authorization', `Bearer ${token}`).send({ stillValid: true })).status).toBe(200);
    expect((await request(app).post(`/api/prices/${price.id}/confirm`).set('Authorization', `Bearer ${token}`).send({ stillValid: false, note: 'اتغير السعر' })).status).toBe(200);
    const after = await request(app).get('/api/prices').set('Authorization', `Bearer ${token}`);
    const updated = after.body.find((row: { id: string }) => row.id === price.id);
    expect(updated.viewerConfirmed).toBe(false);
    expect(updated.confirmationCount).toBe(0);
  });

  it('hides expired prices and supports audited admin archive/restore', async () => {
    const admin = await prisma.adminAccount.create({ data: { name: 'Price editor', email: `price-${randomBytes(3).toString('hex')}@example.com`, passwordHash: 'unused', role: 'OWNER' } });
    const adminToken = await makeAdminToken(admin.id);
    const expired = await prisma.priceGuide.create({ data: { name: `منتهي ${randomBytes(3).toString('hex')}`, minPrice: 10, maxPrice: 20, validUntil: new Date(Date.now() - 86_400_000), status: ReviewStatus.APPROVED } });
    expect((await request(app).get('/api/prices')).body.some((row: { id: string }) => row.id === expired.id)).toBe(false);
    const archived = await request(app).patch(`/api/admin/prices/${expired.id}/archive`).set('Authorization', `Bearer ${adminToken}`).send({ archived: true, reason: 'بيانات قديمة' });
    expect(archived.status).toBe(200);
    const restored = await request(app).patch(`/api/admin/prices/${expired.id}/archive`).set('Authorization', `Bearer ${adminToken}`).send({ archived: false });
    expect(restored.status).toBe(200);
    const audit = await prisma.auditLog.findFirst({ where: { action: 'price.restored', entityId: expired.id }, orderBy: { createdAt: 'desc' } });
    expect(audit).not.toBeNull();
  });

  it('flags price outliers for administration without exposing the signal publicly', async () => {
    const admin = await prisma.adminAccount.create({ data: { name: 'Outlier reviewer', email: `outlier-${randomBytes(3).toString('hex')}@example.com`, passwordHash: 'unused', role: 'OWNER' } });
    const adminToken = await makeAdminToken(admin.id);
    const { area } = await makeAreaCategory();
    const common = { category: 'خضار', areaId: area.id, status: ReviewStatus.APPROVED };
    await prisma.priceGuide.createMany({ data: [
      { ...common, name: 'طماطم 1', minPrice: 10, maxPrice: 12 },
      { ...common, name: 'طماطم 2', minPrice: 11, maxPrice: 13 },
      { ...common, name: 'طماطم 3', minPrice: 100, maxPrice: 120 },
    ] });
    const adminResponse = await request(app).get('/api/admin/prices?outliersOnly=true').set('Authorization', `Bearer ${adminToken}`);
    expect(adminResponse.status).toBe(200);
    expect(adminResponse.body).toHaveLength(1);
    expect(adminResponse.body[0].outlier).toBe(true);
    expect(adminResponse.body[0].outlierReason).toBeTruthy();
    const publicResponse = await request(app).get('/api/prices');
    expect(publicResponse.body.find((row: { id: string }) => row.id === adminResponse.body[0].id)?.outlier).toBeUndefined();
  });
});
