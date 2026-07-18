'use server';

import { redirect } from 'next/navigation';
import { clearUserSession, createUserSession, getUserApiToken } from '@/lib/user-session';
import { getApiBaseUrl } from '@/lib/api';

export async function loginUser(formData: FormData) {
  const response = await fetch(`${getApiBaseUrl()}/api/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identifier: String(formData.get('identifier') ?? ''), password: String(formData.get('password') ?? '') }), cache: 'no-store' });
  if (!response.ok) redirect('/account?error=login');
  const body = await response.json() as { token: string };
  await createUserSession(body.token);
  redirect('/account');
}

export async function registerUser(formData: FormData) {
  const email = String(formData.get('email') ?? '').trim();
  const response = await fetch(`${getApiBaseUrl()}/api/auth/register`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ name: String(formData.get('name') ?? ''), phone: String(formData.get('phone') ?? ''), email: email || undefined, password: String(formData.get('password') ?? '') }), cache: 'no-store' });
  if (!response.ok) redirect('/account?error=register');
  const body = await response.json() as { token: string };
  await createUserSession(body.token);
  redirect('/account');
}

export async function logoutUser() {
  const token = await getUserApiToken();
  if (token) await fetch(`${getApiBaseUrl()}/api/auth/logout`, { method: 'POST', headers: { authorization: `Bearer ${token}` }, cache: 'no-store' }).catch(() => undefined);
  await clearUserSession();
  redirect('/account');
}
