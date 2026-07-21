'use server';

import { revalidatePath } from 'next/cache';
import { apiPatch } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import type { CollectedBusiness, CollectedRecordStatus } from './types';

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
