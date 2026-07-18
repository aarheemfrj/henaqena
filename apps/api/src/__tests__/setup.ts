// Jest setup file
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = process.env.DATABASE_URL || 'postgresql://henaqena:henaqena@localhost:5433/henaqena?schema=public';
});

afterAll(() => {
  // Cleanup if needed
});
