import { NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api';
import { getAdminApiToken, hasAdminSession } from '@/lib/admin-session';

export async function POST(request: Request) {
  if (!await hasAdminSession()) return NextResponse.json({ message: 'صلاحيات الإدارة مطلوبة' }, { status: 403 });
  const token = await getAdminApiToken();
  if (!token) return NextResponse.json({ message: 'صلاحيات الإدارة مطلوبة' }, { status: 403 });
  const body = await request.text();
  const response = await fetch(`${getApiBaseUrl()}/api/uploads/provider-images`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body, cache: 'no-store' });
  const data = await response.text();
  return new NextResponse(data, { status: response.status, headers: { 'content-type': 'application/json' } });
}
