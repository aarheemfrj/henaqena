import { NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';

export async function POST(request: Request) {
  const token = await getUserApiToken();
  if (!token) return NextResponse.json({ message: 'سجّل الدخول أولاً لرفع الصور' }, { status: 401 });
  const body = await request.text();
  const response = await fetch(`${getApiBaseUrl()}/api/uploads/provider-images`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body, cache: 'no-store' });
  const data = await response.text();
  return new NextResponse(data, { status: response.status, headers: { 'content-type': 'application/json' } });
}
