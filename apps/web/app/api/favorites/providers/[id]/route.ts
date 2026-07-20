import { NextResponse } from 'next/server';
import { getApiBaseUrl } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';

export async function POST(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const token = await getUserApiToken();
  if (!token) return NextResponse.json({ message: 'سجّل الدخول أولاً' }, { status: 401 });
  const { id } = await params;
  const response = await fetch(`${getApiBaseUrl()}/api/providers/${id}/favorite`, { method: 'POST', headers: { authorization: `Bearer ${token}` }, cache: 'no-store' });
  const data = await response.text();
  return new NextResponse(data, { status: response.status, headers: { 'content-type': 'application/json' } });
}
