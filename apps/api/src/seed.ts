import 'dotenv/config';
import { randomBytes, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';
import { ListingStatus, PrismaClient, Provider, ReviewStatus, UserLevel } from '@prisma/client';

const prisma = new PrismaClient();
const scrypt = promisify(scryptCallback);
const demoPassword = 'HenaQenaDemo!2026';
const demoDomain = 'henaqena.local';

const areas = [
  'قنا كلها', 'وسط البلد', 'مدينة العمال', 'الشؤون', 'المساكن', 'نجع سعيد',
  'المعنى', 'الحميدات', 'الأحوال', 'عمر أفندي', 'المنشية',
];

const categories = [
  ['خدمات طبية', 'medical'], ['مطاعم وكافيهات', 'food'], ['صيانة وفنيين', 'maintenance'],
  ['سوبر ماركت', 'markets'], ['تعليم ودروس', 'education'], ['ترفيه ومناسبات', 'entertainment'],
  ['بنوك وخدمات مالية', 'banking'], ['اتصالات', 'telecom'], ['سيارات', 'cars'],
  ['عقارات', 'property'], ['تصوير وأفراح', 'photography'], ['خدمات حكومية', 'government'],
] as const;

const image = (id: string) => `https://images.unsplash.com/${id}?auto=format&fit=crop&w=1200&q=75`;

async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const derived = await scrypt(password, salt, 64) as Buffer;
  return `${salt.toString('hex')}:${derived.toString('hex')}`;
}

async function resetShowcase() {
  const users = await prisma.user.findMany({ where: { email: { endsWith: `@${demoDomain}` } }, select: { id: true } });
  const userIds = users.map((item) => item.id);
  if (!userIds.length) return;
  await prisma.reviewReply.deleteMany({ where: { authorId: { in: userIds } } });
  await prisma.review.deleteMany({ where: { authorId: { in: userIds } } });
  await prisma.provider.deleteMany({ where: { ownerId: { in: userIds } } });
  await prisma.listing.deleteMany({ where: { ownerId: { in: userIds } } });
  await prisma.user.deleteMany({ where: { id: { in: userIds } } });
}

async function main() {
  await resetShowcase();
  await prisma.provider.deleteMany({ where: { name: { in: ['كهربائي المصباح', 'مركز الشفاء الطبي'] } } });
  await prisma.priceGuide.deleteMany({ where: { name: 'زيت عباد الشمس — 1 لتر' } });
  await prisma.nowUpdate.deleteMany({ where: { title: 'تحديثات قنا اليومية' } });
  const passwordHash = await hashPassword(demoPassword);
  const areaRecords = await Promise.all(areas.map(async (name) => {
    const existing = await prisma.area.findFirst({ where: { name, city: 'قنا' } });
    return existing ?? prisma.area.create({ data: { name, city: 'قنا' } });
  }));
  const area = Object.fromEntries(areaRecords.map((item) => [item.name, item]));
  const categoryRecords = await Promise.all(categories.map(([name, slug]) => prisma.category.upsert({
    where: { slug }, update: { name, isActive: true }, create: { name, slug },
  })));
  const category = Object.fromEntries(categoryRecords.map((item) => [item.slug, item]));

  const users = await Promise.all([
    ['سارة القناوية', '01099990001', `sara@${demoDomain}`, 78],
    ['محمود العمري', '01199990002', `mahmoud@${demoDomain}`, 18],
    ['مريم علي', '01299990003', `mariam@${demoDomain}`, 145],
    ['مستخدم يحتاج مراجعة', '01599990004', `review@${demoDomain}`, 0],
  ].map(([name, phone, email, points]) => prisma.user.create({ data: {
    name: String(name), phone: String(phone), email: String(email), points: Number(points),
    level: Number(points) >= 100 ? UserLevel.QENAWY_ASIL : Number(points) >= 50 ? UserLevel.QENAWY_RAYEQ : UserLevel.QENAWY,
    passwordHash, authProvider: 'password', phoneVerifiedAt: new Date(),
    interests: ['خدمات طبية', 'مطاعم وكافيهات'], preferredAreaIds: [area['وسط البلد'].id],
  } })));
  const [sara, mahmoud, mariam, reviewUser] = users;

  const providerSpecs = [
    {
      name: 'فرع فودافون قنا — عرض تجريبي', slug: 'telecom', owner: sara, area: 'وسط البلد', status: ReviewStatus.APPROVED, verified: true,
      address: 'شارع 23 يوليو أمام مطعم كويك دور — قنا', description: 'بيانات Showcase مستندة لدليل فروع Vodafone الرسمي؛ يجب إعادة التحقق قبل النشر الإنتاجي.', opening: '09:00', closing: '21:30', img: image('photo-1563013544-824ae1b704d3'),
    },
    {
      name: 'بنك مصر للمعاملات الإسلامية — عرض تجريبي', slug: 'banking', owner: mahmoud, area: 'المنشية', status: ReviewStatus.APPROVED, verified: true,
      address: 'برج الخليفة، شارع الشنهورية، قنا', description: 'نموذج عرض مبني على عنوان منشور بدليل بنك مصر الرسمي.', opening: '08:30', closing: '15:00', img: image('photo-1541354329998-f4d9a9f9297f'),
    },
    {
      name: 'معمل ألفا قنا — عرض تجريبي', slug: 'medical', owner: mariam, area: 'وسط البلد', status: ReviewStatus.APPROVED, verified: false,
      address: 'شارع المعبر أمام مستشفى الصدر', description: 'بيانات عرض لاختبار صفحة نشاط طبي غير موثقة داخل هنا قنا.', opening: '08:00', closing: '23:00', img: image('photo-1579154204601-01588f351e67'),
    },
    {
      name: 'ورشة النور للكهرباء (نموذج)', slug: 'maintenance', owner: mahmoud, area: 'مدينة العمال', status: ReviewStatus.PENDING, verified: false,
      address: 'مدينة العمال، قنا', description: 'نشاط خيالي مخصص لاختبار طلبات المراجعة.', opening: '10:00', closing: '22:00', img: image('photo-1621905252507-b35492cc74b4'),
    },
    {
      name: 'مطبخ بيت قنا (نموذج مرفوض)', slug: 'food', owner: reviewUser, area: 'المساكن', status: ReviewStatus.REJECTED, verified: false,
      address: 'عنوان غير مكتمل', description: 'نموذج مرفوض لاختبار حالات نقص البيانات.', opening: null, closing: null, img: image('photo-1556911220-bff31c812dba'),
    },
  ];

  const providers: Provider[] = [];
  for (const spec of providerSpecs) {
    providers.push(await prisma.provider.create({ data: {
      name: spec.name, description: spec.description, address: spec.address, areaId: area[spec.area].id,
      ownerId: spec.owner.id, status: spec.status, isVerified: spec.verified, openingTime: spec.opening, closingTime: spec.closing,
      phone: spec.owner.phone, whatsapp: spec.owner.phone, latitude: 26.164, longitude: 32.726,
      images: { create: [{ url: spec.img, sortOrder: 0, kind: 'showcase' }] },
      categories: { create: { categoryId: category[spec.slug].id } },
    } }));
  }
  const [vodafone, bank, lab, workshop] = providers;

  await prisma.providerService.createMany({ data: [
    { providerId: vodafone.id, name: 'خدمات الخطوط والاستبدال', priceNote: 'حسب نوع الخدمة', status: ReviewStatus.APPROVED },
    { providerId: lab.id, name: 'صورة دم كاملة', price: 220, priceNote: 'سعر Showcase غير ملزم', status: ReviewStatus.APPROVED },
    { providerId: workshop.id, name: 'معاينة عطل منزلي', price: 150, status: ReviewStatus.PENDING },
  ] });
  await prisma.providerOffer.createMany({ data: [
    { providerId: lab.id, title: 'خصم 15% على باقة الاطمئنان (نموذج)', description: 'عرض تجريبي للواجهة', startsAt: new Date(), endsAt: new Date(Date.now() + 14 * 86400000), status: ReviewStatus.APPROVED },
    { providerId: workshop.id, title: 'كشف مجاني مع الإصلاح', startsAt: new Date(), endsAt: new Date(Date.now() + 7 * 86400000), status: ReviewStatus.PENDING },
  ] });

  const approvedReview = await prisma.review.create({ data: { providerId: lab.id, authorId: sara.id, quality: 5, commitment: 4, value: 4, comment: 'المكان نظيف والتعامل كان مرتب، وده تعليق Showcase.', status: ReviewStatus.APPROVED, moderatedAt: new Date(), pointsAwarded: true } });
  await prisma.reviewReply.create({ data: { reviewId: approvedReview.id, authorId: mariam.id, text: 'شكرًا لتجربتك، هل النتيجة ظهرت في نفس اليوم؟', status: ReviewStatus.APPROVED, moderatedAt: new Date() } });
  await prisma.review.create({ data: { providerId: bank.id, authorId: mahmoud.id, quality: 3, commitment: 3, value: 3, comment: 'تقييم معلق لاختبار مركز المراجعة.', status: ReviewStatus.PENDING } });
  await prisma.review.create({ data: { providerId: vodafone.id, authorId: reviewUser.id, quality: 1, commitment: 1, value: 1, comment: 'تعليق غير كافٍ — نموذج مرفوض.', status: ReviewStatus.REJECTED, moderatedAt: new Date() } });

  const listingSpecs = [
    { owner: sara, title: 'مكتب خشب بحالة جيدة (نموذج)', description: 'صور واضحة، المقاس 120×60 سم.', category: 'أثاث', price: 2200, status: ListingStatus.ACTIVE, area: 'وسط البلد', img: image('photo-1518455027359-f3f8164ba6bd') },
    { owner: mahmoud, title: 'هاتف مستعمل 128GB (نموذج)', description: 'في انتظار مراجعة الصور والسعر.', category: 'إلكترونيات', price: 8500, status: ListingStatus.PENDING, area: 'مدينة العمال', img: image('photo-1511707171634-5f897ff02aa9') },
    { owner: reviewUser, title: 'إعلان بسعر غير منطقي (نموذج)', description: 'مرفوض بسبب السعر غير الكافي.', category: 'أخرى', price: 1, status: ListingStatus.REJECTED, area: 'المساكن', img: image('photo-1586023492125-27b2c045efd7') },
  ];
  for (const item of listingSpecs) await prisma.listing.create({ data: {
    title: item.title, description: item.description, category: item.category, price: item.price, status: item.status,
    ownerId: item.owner.id, areaId: area[item.area].id, expiresAt: item.status === ListingStatus.ACTIVE ? new Date(Date.now() + 7 * 86400000) : null,
    images: { create: [{ url: item.img, sortOrder: 0 }] },
  } });

  await prisma.priceGuide.deleteMany({ where: { sourceNote: { contains: 'Showcase' } } });
  await prisma.priceGuide.createMany({ data: [
    { name: 'زيت عباد الشمس 1 لتر', category: 'سوبر ماركت', minPrice: 78, maxPrice: 92, unit: 'عبوة', sourceNote: 'Showcase — نطاق تجريبي', areaId: area['وسط البلد'].id, status: ReviewStatus.APPROVED },
    { name: 'صيانة حنفية منزلية', category: 'خدمات', minPrice: 150, maxPrice: 350, unit: 'للزيارة', sourceNote: 'Showcase — سعر استرشادي غير ملزم', areaId: area['مدينة العمال'].id, status: ReviewStatus.APPROVED },
    { name: 'منتج بسعر شاذ', category: 'اختبار مراجعة', minPrice: 1, maxPrice: 99999, sourceNote: 'Showcase — يجب رفضه', status: ReviewStatus.PENDING },
  ] });

  await prisma.nowUpdate.deleteMany({ where: { body: { contains: 'Showcase' } } });
  await prisma.nowUpdate.createMany({ data: [
    { title: 'تنبيه صيانة مياه (نموذج)', body: 'Showcase — تنبيه تجريبي للواجهة وليس بلاغًا رسميًا.', category: 'خدمات ومرافق', areaId: area['المساكن'].id, status: ReviewStatus.APPROVED, endsAt: new Date(Date.now() + 86400000) },
    { title: 'فعالية رياضية محلية (نموذج)', body: 'Showcase — بند معلق لاختبار مراجعة الإدارة.', category: 'فعاليات', areaId: area['وسط البلد'].id, status: ReviewStatus.PENDING, endsAt: new Date(Date.now() + 3 * 86400000) },
  ] });

  await prisma.ad.deleteMany({ where: { name: { startsWith: 'Showcase' } } });
  await prisma.ad.createMany({ data: [
    { name: 'Showcase — واجهة خدمات قنا', imageUrl: image('photo-1524230572899-a752b3835840'), description: 'اعرف الخدمات الأقرب لك في قنا', targetUrl: `/providers`, weight: 60, startsAt: new Date(Date.now() - 86400000), endsAt: new Date(Date.now() + 30 * 86400000), status: ReviewStatus.APPROVED },
    { name: 'Showcase — حملة معلقة', imageUrl: image('photo-1556742049-0cfed4f6a45d'), description: 'إعلان بانتظار المراجعة', weight: 40, startsAt: new Date(), endsAt: new Date(Date.now() + 14 * 86400000), status: ReviewStatus.PENDING },
  ] });

  await prisma.notification.createMany({ data: [
    { userId: sara.id, title: 'تم نشر مساهمتك', body: 'الإعلان التجريبي ظهر في قسم «عندك؟».' },
    { userId: mahmoud.id, title: 'طلبك قيد المراجعة', body: 'هنبعت لك إشعار بعد قرار الإدارة.' },
  ] });

  console.log(JSON.stringify({
    ok: true, areas: areaRecords.length, categories: categoryRecords.length, users: users.length,
    providers: providers.length, demoLogin: { email: `sara@${demoDomain}`, password: demoPassword },
    note: 'كل الأسماء الموسومة بـ«نموذج/Showcase» مخصصة للمعاينة المحلية فقط.',
  }, null, 2));
}

main().finally(() => prisma.$disconnect());
