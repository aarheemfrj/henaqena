'use server';

import { revalidatePath } from 'next/cache';
import { userPatch, userPost } from '@/lib/api';

export async function markNotificationRead(formData: FormData) {
  const id = String(formData.get('id') ?? '');
  if (!id) return;
  await userPatch(`/api/notifications/${id}/read`, {}).catch(() => undefined);
  revalidatePath('/notifications');
}

export async function markAllNotificationsRead() {
  await userPost('/api/notifications/read-all', {}).catch(() => undefined);
  revalidatePath('/notifications');
}
