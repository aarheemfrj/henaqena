import { createHmac, timingSafeEqual } from 'node:crypto';
import { cookies } from 'next/headers';

const cookieName = 'henaqena_admin_session';
const apiTokenCookieName = 'henaqena_admin_api_token';
const sessionHours = 12;

function dashboardPassword() {
  return process.env.ADMIN_DASHBOARD_PASSWORD ?? (process.env.NODE_ENV === 'production' ? '' : 'henaqena-local');
}

function sessionSecret() {
  return process.env.ADMIN_SESSION_SECRET ?? (process.env.NODE_ENV === 'production' ? '' : 'henaqena-local-session-secret');
}

function signature(issuedAt: string) {
  return createHmac('sha256', sessionSecret()).update(`henaqena-admin:${issuedAt}`).digest('hex');
}

export function isValidDashboardPassword(candidate: string) {
  const expected = dashboardPassword();
  if (!expected || expected.length !== candidate.length) return false;
  return timingSafeEqual(Buffer.from(expected), Buffer.from(candidate));
}

export async function createAdminSession(apiToken?: string) {
  const issuedAt = String(Date.now());
  const store = await cookies();
  store.set(cookieName, `${issuedAt}.${signature(issuedAt)}`, {
    httpOnly: true,
    sameSite: 'lax',
    secure: process.env.NODE_ENV === 'production',
    path: '/',
    maxAge: sessionHours * 60 * 60,
  });
  if (apiToken) store.set(apiTokenCookieName, apiToken, { httpOnly: true, sameSite: 'lax', secure: process.env.NODE_ENV === 'production', path: '/', maxAge: sessionHours * 60 * 60 });
}

export async function hasAdminSession() {
  const store = await cookies();
  const apiToken = store.get(apiTokenCookieName)?.value;
  if (apiToken) return true;
  if (!sessionSecret()) return false;
  const value = store.get(cookieName)?.value;
  if (!value) return false;
  const [issuedAt, receivedSignature] = value.split('.');
  if (!issuedAt || !receivedSignature || Date.now() - Number(issuedAt) > sessionHours * 60 * 60 * 1000) return false;
  const expectedSignature = signature(issuedAt);
  return receivedSignature.length === expectedSignature.length && timingSafeEqual(Buffer.from(receivedSignature), Buffer.from(expectedSignature));
}

export async function clearAdminSession() {
  const store = await cookies();
  store.delete(cookieName);
  store.delete(apiTokenCookieName);
}
