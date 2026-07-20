'use server';

import { redirect } from 'next/navigation';
import { getApiBaseUrl } from '@/lib/api';

export async function requestPasswordReset(formData: FormData) {
  const identifier = String(formData.get('identifier') ?? '').trim();
  const channel = String(formData.get('channel') ?? 'sms');
  await fetch(`${getApiBaseUrl()}/api/auth/password-reset/request`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identifier, channel }), cache: 'no-store' }).catch(() => undefined);
  redirect(`/forgot-password?step=confirm&identifier=${encodeURIComponent(identifier)}&channel=${channel}`);
}

export async function confirmPasswordReset(formData: FormData) {
  const identifier = String(formData.get('identifier') ?? '');
  const channel = String(formData.get('channel') ?? 'sms');
  const response = await fetch(`${getApiBaseUrl()}/api/auth/password-reset/confirm`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ identifier, channel, code: String(formData.get('code') ?? ''), newPassword: String(formData.get('newPassword') ?? '') }), cache: 'no-store' });
  if (!response.ok) redirect(`/forgot-password?step=confirm&identifier=${encodeURIComponent(identifier)}&channel=${channel}&error=1`);
  redirect('/account?reset=1');
}
