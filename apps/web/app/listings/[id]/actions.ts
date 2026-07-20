'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { userPost } from '@/lib/api';

export async function toggleListingFavorite(formData: FormData) {
  const listingId = String(formData.get('listingId') ?? '');
  if (!listingId) return;
  try {
    await userPost(`/api/listings/${listingId}/favorite`, {});
  } catch {
    redirect(`/listings/${listingId}?error=login`);
  }
  revalidatePath(`/listings/${listingId}`);
}

export async function toggleListingInterest(formData: FormData) {
  const listingId = String(formData.get('listingId') ?? '');
  if (!listingId) return;
  try {
    await userPost(`/api/listings/${listingId}/interested`, {});
  } catch {
    redirect(`/listings/${listingId}?error=login`);
  }
  revalidatePath(`/listings/${listingId}`);
}

export async function reportListing(formData: FormData) {
  const listingId = String(formData.get('listingId') ?? '');
  try {
    await userPost(`/api/listings/${listingId}/reports`, { reason: String(formData.get('reason') ?? '') });
  } catch {
    redirect(`/listings/${listingId}?error=report`);
  }
  redirect(`/listings/${listingId}?reported=1`);
}
