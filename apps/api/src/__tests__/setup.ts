import { PrismaClient } from '@prisma/client';

let prisma: PrismaClient;

beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  if (!process.env.DATABASE_URL) {
    process.env.DATABASE_URL = 'postgresql://henaqena:henaqena@localhost:5434/henaqena_test?schema=public';
  }

  prisma = new PrismaClient({
    log: process.env.DEBUG_TESTS ? ['query', 'info'] : ['error'],
  });

  try {
    await prisma.$executeRawUnsafe('SELECT 1');
  } catch (error) {
    const dbUrl = process.env.DATABASE_URL;
    console.error('❌ Test database connection failed:', dbUrl);
    console.error('   For local testing: npm run test:setup && npm test && npm run test:teardown');
    console.error('   Or ensure CI PostgreSQL service is running.');
    throw error;
  }
});

afterAll(async () => {
  if (prisma) {
    await prisma.$disconnect();
  }
});
