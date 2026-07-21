'use server';

import { revalidatePath } from 'next/cache';
import { apiPatch, apiPost, getApiBaseUrl } from '@/lib/api';
import { getAdminApiToken, hasAdminSession } from '@/lib/admin-session';
import type { CollectedBusiness, CollectedRecordStatus, CsvImportOutcome, NewCollectionJob } from './types';

export async function updateCollectedRecord(id: string, status: CollectedRecordStatus, reviewNote: string) {
  if (!await hasAdminSession()) throw new Error('يجب تسجيل الدخول كمسؤول');
  const record = await apiPatch<CollectedBusiness>(`/api/admin/data-collection/records/${id}`, {
    status,
    reviewNote: reviewNote.trim() ? reviewNote.trim() : null,
  });
  revalidatePath('/admin/data-collection');
  return record;
}

export async function resolveDuplicateRecord(id: string, resolution: 'MERGE_LEFT' | 'MERGE_RIGHT' | 'NOT_DUPLICATE') {
  if (!await hasAdminSession()) throw new Error('يجب تسجيل الدخول كمسؤول');
  const result = await apiPatch<{ resolved: boolean; id: string; resolution: string }>(
    `/api/admin/data-collection/duplicates/${id}`,
    { resolution },
  );
  revalidatePath('/admin/data-collection');
  return result;
}

export async function createCollectionJob(formData: FormData) {
  if (!await hasAdminSession()) throw new Error('يجب تسجيل الدخول كمسؤول');
  const sourceId = String(formData.get('sourceId') ?? '').trim();
  const category = String(formData.get('category') ?? '').trim();
  const area = String(formData.get('area') ?? '').trim();
  const query = String(formData.get('query') ?? '').trim();
  const limit = Number(formData.get('limit') ?? 50);

  const result = await apiPost<{ job: NewCollectionJob }>('/api/admin/data-collection/jobs', {
    sourceId,
    category,
    area,
    query: query || undefined,
    limit,
  });
  revalidatePath('/admin/data-collection');
  return result.job;
}

export async function uploadCsvForJob(formData: FormData) {
  if (!await hasAdminSession()) throw new Error('يجب تسجيل الدخول كمسؤول');
  const jobId = String(formData.get('jobId') ?? '');
  const file = formData.get('file');
  if (!jobId) throw new Error('رقم المهمة مطلوب');
  if (!(file instanceof File)) throw new Error('ملف CSV مطلوب');

  const token = await getAdminApiToken();
  if (!token) throw new Error('Admin session is required');

  const uploadForm = new FormData();
  uploadForm.append('file', file);

  const response = await fetch(`${getApiBaseUrl()}/api/admin/data-collection/jobs/${jobId}/import-csv`, {
    method: 'POST',
    headers: { authorization: `Bearer ${token}` },
    body: uploadForm,
    cache: 'no-store',
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(body.message || `تعذر رفع الملف (${response.status})`);

  revalidatePath('/admin/data-collection');
  return body as CsvImportOutcome;
}
