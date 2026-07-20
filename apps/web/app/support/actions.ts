'use server';

import { redirect } from 'next/navigation';
import { userPost } from '@/lib/api';

export async function submitSupportTicket(formData: FormData) {
  try {
    await userPost('/api/support-tickets', { subject: String(formData.get('subject') ?? ''), message: String(formData.get('message') ?? '') });
  } catch {
    redirect('/support?error=1');
  }
  redirect('/support?sent=1');
}
