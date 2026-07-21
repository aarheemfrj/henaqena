import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { PrismaClient } from '@prisma/client';
import { runCsvImportForJob } from './import-runner';

const prisma = new PrismaClient();

const getArg = (name: string): string | undefined => {
  const prefixed = `--${name}=`;
  return process.argv.find((arg) => arg.startsWith(prefixed))?.slice(prefixed.length);
};

const required = (name: string): string => {
  const value = getArg(name);
  if (!value) throw new Error(`Missing --${name}=...`);
  return value;
};

const main = async () => {
  const file = required('file');
  const sourceId = getArg('source') ?? 'manual-csv';
  const defaultCategory = getArg('category') ?? null;
  const defaultArea = getArg('area') ?? null;
  const jobId = randomUUID();

  await prisma.$executeRawUnsafe(
    `INSERT INTO "CollectionJob"
      ("id", "sourceId", "category", "area", "query", "status")
     VALUES ($1, $2, $3, $4, $5, 'PENDING')`,
    jobId,
    sourceId,
    defaultCategory,
    defaultArea,
    `csv:${file}`,
  );

  const csvContent = await readFile(file, 'utf8');
  const result = await runCsvImportForJob(prisma, { jobId, sourceId, defaultCategory, defaultArea, csvContent });

  console.log(JSON.stringify({ jobId, ...result }, null, 2));
};

main()
  .catch(async (error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
