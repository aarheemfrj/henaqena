'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { userPost } from '@/lib/api';

export async function toggleProviderFavorite(formData: FormData) {
  const providerId = String(formData.get('providerId') ?? '');
  if (!providerId) return;
  try {
    await userPost(`/api/providers/${providerId}/favorite`, {});
  } catch {
    redirect(`/providers/${providerId}?error=login`);
  }
  revalidatePath(`/providers/${providerId}`);
}

export async function submitProviderReview(formData: FormData) {
  const providerId = String(formData.get('providerId') ?? '');
  try {
    await userPost('/api/reviews', {
      providerId,
      quality: Number(formData.get('quality') ?? 0),
      commitment: Number(formData.get('commitment') ?? 0),
      value: Number(formData.get('value') ?? 0),
      comment: String(formData.get('comment') ?? '') || undefined,
    });
  } catch {
    redirect(`/providers/${providerId}?error=review`);
  }
  revalidatePath(`/providers/${providerId}`);
  redirect(`/providers/${providerId}?reviewed=1`);
}
