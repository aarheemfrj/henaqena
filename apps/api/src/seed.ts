import { PrismaClient, ReviewStatus } from '@prisma/client';

const prisma = new PrismaClient();
const areas = ['قنا كلها', 'وسط البلد', 'مدينة العمال', 'الشؤون', 'الحميدات', 'المساكن'];
const categories = [
  ['خدمات طبية', 'medical'],
  ['مطاعم وكافيهات', 'food'],
  ['صيانة وفنيين', 'maintenance'],
  ['سوبر ماركت', 'markets'],
  ['تعليم ودروس', 'education'],
  ['ترفيه', 'entertainment'],
] as const;

async function findOrCreateArea(name: string) {
  return prisma.area.findFirst({ where: { name, city: 'قنا' } }).then((area) => area ?? prisma.area.create({ data: { name, city: 'قنا' } }));
}

async function main() {
  const areaRecords = await Promise.all(areas.map(findOrCreateArea));
  const categoryRecords = await Promise.all(categories.map(([name, slug]) => prisma.category.upsert({ where: { slug }, update: { name }, create: { name, slug } })));
  const mainArea = areaRecords.find((area) => area.name === 'وسط البلد') ?? areaRecords[0];
  const medical = categoryRecords.find((category) => category.slug === 'medical')!;
  const maintenance = categoryRecords.find((category) => category.slug === 'maintenance')!;
  const seedUser = await prisma.user.upsert({ where: { phone: '01000000000' }, update: { name: 'فريق هنا قنا' }, create: { name: 'فريق هنا قنا', phone: '01000000000' } });
  const providers = [
    { name: 'كهربائي المصباح', description: 'خدمات كهرباء وصيانة منزلية داخل قنا.', areaId: mainArea.id, categoryId: maintenance.id },
    { name: 'مركز الشفاء الطبي', description: 'خدمات طبية ومتابعة للحجز والاستفسار.', areaId: mainArea.id, categoryId: medical.id },
  ];
  for (const provider of providers) {
    const existing = await prisma.provider.findFirst({ where: { name: provider.name } });
    if (existing) continue;
    await prisma.provider.create({ data: { name: provider.name, description: provider.description, areaId: provider.areaId, ownerId: seedUser.id, status: ReviewStatus.APPROVED, isVerified: true, images: { create: [{ url: '/assets/brand/temp-logo-mark.svg', sortOrder: 0, kind: 'temporary' }] }, categories: { create: { categoryId: provider.categoryId } } } });
  }
  console.log(`Seeded ${areaRecords.length} areas, ${categoryRecords.length} categories, and ${providers.length} demo providers.`);
}

main().finally(() => prisma.$disconnect());
