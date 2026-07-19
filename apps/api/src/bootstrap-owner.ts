import 'dotenv/config';
import { randomBytes, scrypt as scryptCallback } from 'node:crypto';
import { promisify } from 'node:util';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const scrypt = promisify(scryptCallback);

async function hashPassword(password: string) {
  const salt = randomBytes(16);
  const derived = await scrypt(password, salt, 64) as Buffer;
  return `${salt.toString('hex')}:${derived.toString('hex')}`;
}

async function main() {
  const existingOwner = await prisma.adminAccount.findFirst({
    where: { role: 'OWNER', isActive: true },
    select: { email: true },
  });
  if (existingOwner) {
    console.log(`OWNER account already exists: ${existingOwner.email}`);
    return;
  }

  const name = process.env.OWNER_NAME?.trim();
  const email = process.env.OWNER_EMAIL?.trim().toLowerCase();
  const password = process.env.OWNER_PASSWORD;
  if (!name || !email || !email.includes('@') || !password || password.length < 12) {
    console.error('No active OWNER exists. OWNER_NAME, OWNER_EMAIL, and OWNER_PASSWORD (12+ characters) are required once.');
    process.exitCode = 2;
    return;
  }

  await prisma.adminAccount.create({
    data: {
      name,
      email,
      passwordHash: await hashPassword(password),
      role: 'OWNER',
      isActive: true,
    },
  });
  console.log(`Created initial OWNER account: ${email}`);
}

main()
  .catch((error) => {
    console.error('Failed to bootstrap OWNER account', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
