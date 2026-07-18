'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { apiPatch, apiPost } from '@/lib/api';
import { clearAdminSession, createAdminSession, hasAdminSession, isValidDashboardPassword } from '@/lib/admin-session';

export async function loginAdmin(formData: FormData) {
  const password = String(formData.get('password') ?? '');
  if (!isValidDashboardPassword(password)) redirect('/admin/login?error=1');
  await createAdminSession();
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
