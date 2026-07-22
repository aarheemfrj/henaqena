'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { apiDelete, apiPatch, apiPost } from '@/lib/api';
import { clearAdminSession, createAdminSession, hasAdminSession } from '@/lib/admin-session';
import { getApiBaseUrl } from '@/lib/api';

export async function loginAdmin(formData: FormData) {
  const email = String(formData.get('email') ?? ''); const password = String(formData.get('password') ?? '');
  const response = await fetch(`${getApiBaseUrl()}/api/admin/auth/login`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ email, password }), cache: 'no-store' });
  if (!response.ok) redirect('/admin/login?error=1');
  const body = await response.json() as { token: string };
  await createAdminSession(body.token);
  redirect('/admin');
}

export async function logoutAdmin() {
  await clearAdminSession();
  redirect('/admin/login');
}

export async function moderateProvider(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? '');
  const status = String(formData.get('status') ?? '');
  if (!id || !['APPROVED', 'REJECTED'].includes(status)) return;
  await apiPatch(`/api/admin/providers/${id}`, { status });
  revalidatePath('/admin');
  revalidatePath('/providers');
  revalidatePath('/');
}

export async function deleteProvider(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? ''); if (!id) return;
  await apiDelete(`/api/admin/providers/${id}`);
  revalidatePath('/admin/providers');
  revalidatePath('/providers');
  revalidatePath('/');
}

export async function createAd(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/ads', { name: String(formData.get('name') ?? ''), imageUrl: String(formData.get('imageUrl') ?? ''), description: String(formData.get('description') ?? '') || undefined, targetUrl: String(formData.get('targetUrl') ?? '') || undefined, weight: Number(formData.get('weight') ?? 100), startsAt: String(formData.get('startsAt') ?? ''), endsAt: String(formData.get('endsAt') ?? '') });
  revalidatePath('/admin/ads');
}

export async function moderateAd(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? '');
  const status = String(formData.get('status') ?? '');
  if (!id || !['APPROVED', 'REJECTED'].includes(status)) return;
  await apiPatch(`/api/admin/ads/${id}`, { status });
  revalidatePath('/admin/ads');
}

export async function updatePlatformSettings(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPatch('/api/admin/settings', {
    adRotationSeconds: Number(formData.get('adRotationSeconds') ?? 6),
    dataRefreshSeconds: Number(formData.get('dataRefreshSeconds') ?? 900),
  });
  revalidatePath('/admin/ads');
}

export async function createPrice(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/admin/prices', { name: String(formData.get('name') ?? ''), category: String(formData.get('category') ?? '') || undefined, minPrice: Number(formData.get('minPrice') ?? 0), maxPrice: Number(formData.get('maxPrice') ?? 0), unit: String(formData.get('unit') ?? '') || undefined, sourceNote: String(formData.get('sourceNote') ?? '') || undefined });
  revalidatePath('/admin/prices');
}

export async function moderatePrice(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? '');
  if (!id || !['APPROVED', 'REJECTED'].includes(status)) return;
  await apiPatch(`/api/admin/prices/${id}`, { status }); revalidatePath('/admin/prices');
}

export async function createNow(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/admin/now', { title: String(formData.get('title') ?? ''), body: String(formData.get('body') ?? '') || undefined, category: String(formData.get('category') ?? 'عام') });
  revalidatePath('/admin/now');
}

export async function moderateNow(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? '');
  if (!id || !['APPROVED', 'REJECTED'].includes(status)) return;
  await apiPatch(`/api/admin/now/${id}`, { status }); revalidatePath('/admin/now');
}

export async function createTeamMember(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/admin/team', { name: String(formData.get('name') ?? ''), email: String(formData.get('email') ?? ''), password: String(formData.get('password') ?? ''), role: String(formData.get('role') ?? 'REVIEWER') });
  revalidatePath('/admin/team');
}

export async function updateTeamMember(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? ''); if (!id) return;
  await apiPatch(`/api/admin/team/${id}`, { role: String(formData.get('role') ?? 'REVIEWER'), isActive: formData.get('isActive') === 'true' });
  revalidatePath('/admin/team');
}

export async function moderateListing(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login'); const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? ''); if (!id || !['ACTIVE', 'REJECTED', 'ARCHIVED'].includes(status)) return; await apiPatch(`/api/admin/listings/${id}`, { status, note: String(formData.get('note') ?? '') }); revalidatePath('/admin/listings'); revalidatePath('/listings');
}

export async function moderateReview(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login'); const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? ''); if (!id || !['APPROVED', 'REJECTED'].includes(status)) return; await apiPatch(`/api/admin/reviews/${id}`, { status, note: String(formData.get('note') ?? '') }); revalidatePath('/admin/reviews');
}

export async function deleteReview(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const id = String(formData.get('id') ?? ''); if (!id) return;
  const reason = String(formData.get('reason') ?? '').trim();
  const notify = formData.get('notify') === 'true';
  await apiDelete(`/api/admin/reviews/${id}`, { reason: reason || undefined, notify });
  revalidatePath('/admin/reviews');
}

export async function moderateReport(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login'); const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? ''); if (!id || !['APPROVED', 'REJECTED'].includes(status)) return; await apiPatch(`/api/admin/provider-reports/${id}`, { status }); revalidatePath('/admin/reports');
}

export async function importProviders(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const file = formData.get('file'); if (!(file instanceof File)) return;
  const csv = await file.text(); await apiPost('/api/admin/import/providers', { csv }); revalidatePath('/admin/providers'); revalidatePath('/admin/import');
}

export async function moderateService(formData: FormData) { if (!await hasAdminSession()) redirect('/admin/login'); const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? ''); if (!id || !['APPROVED', 'REJECTED'].includes(status)) return; await apiPatch(`/api/admin/services/${id}`, { status }); revalidatePath('/admin/services'); }
export async function moderateOffer(formData: FormData) { if (!await hasAdminSession()) redirect('/admin/login'); const id = String(formData.get('id') ?? ''); const status = String(formData.get('status') ?? ''); if (!id || !['APPROVED', 'REJECTED'].includes(status)) return; await apiPatch(`/api/admin/offers/${id}`, { status }); revalidatePath('/admin/services'); }

export async function createProviderAdmin(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/providers?error=1');
  const images = JSON.parse(String(formData.get('images') ?? '[]')) as { url: string; kind?: string }[];
  if (images.length === 0) redirect('/admin/providers?error=images');
  try {
    await apiPost('/api/admin/providers', {
      name: String(formData.get('name') ?? ''),
      description: String(formData.get('description') ?? '') || undefined,
      phone: String(formData.get('phone') ?? '') || undefined,
      whatsapp: String(formData.get('whatsapp') ?? '') || undefined,
      phoneType: String(formData.get('phoneType') ?? 'BUSINESS'),
      address: String(formData.get('address') ?? '') || undefined,
      areaId: String(formData.get('areaId') ?? '') || undefined,
      newAreaName: String(formData.get('newAreaName') ?? '') || undefined,
      serviceMode: String(formData.get('serviceMode') ?? 'LOCAL'),
      openingTime: String(formData.get('openingTime') ?? '') || undefined,
      closingTime: String(formData.get('closingTime') ?? '') || undefined,
      categoryId: String(formData.get('categoryId') ?? '') || undefined,
      newCategoryName: String(formData.get('newCategoryName') ?? '') || undefined,
      isVerified: formData.get('isVerified') === 'true',
      images,
    });
  } catch {
    redirect('/admin/providers?error=1');
  }
  revalidatePath('/admin/providers'); revalidatePath('/providers'); revalidatePath('/');
  redirect('/admin/providers?created=1');
}

export async function createListingAdmin(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/listings?error=1');
  const images = (JSON.parse(String(formData.get('images') ?? '[]')) as { url: string }[]).map((image) => image.url);
  if (images.length === 0) redirect('/admin/listings?error=images');
  try {
    await apiPost('/api/admin/listings', {
      title: String(formData.get('title') ?? ''),
      description: String(formData.get('description') ?? '') || undefined,
      category: String(formData.get('category') ?? ''),
      price: Number(formData.get('price') ?? 0),
      areaId: String(formData.get('areaId') ?? '') || undefined,
      newAreaName: String(formData.get('newAreaName') ?? '') || undefined,
      expiresInDays: Number(formData.get('expiresInDays') ?? 90),
      images,
    });
  } catch {
    redirect('/admin/listings?error=1');
  }
  revalidatePath('/admin/listings'); revalidatePath('/listings');
  redirect('/admin/listings?created=1');
}

export async function createDatabaseBackup() {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/admin/backups', {});
  revalidatePath('/admin/maintenance');
}

export async function updateBackupSchedule(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPatch('/api/admin/backups/schedule', {
    enabled: formData.get('enabled') === 'on',
    interval: String(formData.get('interval') ?? 'week'),
  });
  revalidatePath('/admin/maintenance');
}

export async function restoreDatabaseBackup(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiPost('/api/admin/backups/restore', {
    filename: String(formData.get('filename') ?? ''),
    confirm: 'RESTORE_HENA_QENA',
  });
  revalidatePath('/admin/maintenance');
}

export async function deleteDatabaseBackup(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  await apiDelete(`/api/admin/backups/${encodeURIComponent(String(formData.get('filename') ?? ''))}`);
  revalidatePath('/admin/maintenance');
}

export async function factoryReset(formData: FormData) {
  if (!await hasAdminSession()) redirect('/admin/login');
  if (String(formData.get('confirm') ?? '') !== 'RESET_HENA_QENA') redirect('/admin/maintenance?error=confirm');
  const scopes = formData.getAll('scopes').map(String);
  await apiPost('/api/admin/maintenance/reset', { scopes, confirm: 'RESET_HENA_QENA' });
  revalidatePath('/admin');
  revalidatePath('/admin/maintenance');
}
