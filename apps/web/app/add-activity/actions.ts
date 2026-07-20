'use server';

import { redirect } from 'next/navigation';
import { userPost } from '@/lib/api';

export async function submitActivity(formData: FormData) {
  const images = JSON.parse(String(formData.get('images') ?? '[]')) as { url: string; kind?: string }[];
  if (images.length === 0) redirect('/add-activity?error=1');
  try {
    await userPost('/api/providers', {
      name: String(formData.get('name') ?? ''),
      description: String(formData.get('description') ?? '') || undefined,
      phone: String(formData.get('phone') ?? '') || undefined,
      whatsapp: String(formData.get('whatsapp') ?? '') || undefined,
      phoneType: String(formData.get('phoneType') ?? 'BUSINESS'),
      address: String(formData.get('address') ?? '') || undefined,
      areaId: String(formData.get('areaId') ?? ''),
      serviceMode: String(formData.get('serviceMode') ?? 'LOCAL'),
      openingTime: String(formData.get('openingTime') ?? '') || undefined,
      closingTime: String(formData.get('closingTime') ?? '') || undefined,
      categoryIds: [String(formData.get('categoryId') ?? '')],
      images,
    });
  } catch {
    redirect('/add-activity?error=1');
  }
  redirect('/add-activity?sent=1');
}
