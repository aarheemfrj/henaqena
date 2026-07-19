export type Area = { id: string; name: string };
export type Category = { id: string; name: string; slug: string };
export type Provider = {
  id: string;
  name: string;
  description?: string | null;
  isVerified: boolean;
  communityAdded: boolean;
  serviceMode: 'LOCAL' | 'ONLINE';
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  openingTime?: string | null;
  closingTime?: string | null;
  area: Area;
  images: { url: string; sortOrder: number }[];
  categories: { category: Category }[];
};
export type AdminOverview = { providers: number; pending: number; listings: number; reviews: number };

const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://127.0.0.1:4000';

export async function apiGet<T>(path: string, options?: { admin?: boolean; user?: boolean; cache?: 'force-cache' | 'no-store'; revalidate?: number }): Promise<T> {
  const headers = new Headers();
  if (options?.admin) {
    const token = await getAdminApiToken();
    if (!token) throw new Error('Admin session is required');
    headers.set('authorization', `Bearer ${token}`);
  }
  if (options?.user) {
    const token = await getUserApiToken();
    if (!token) throw new Error('User session is required');
    headers.set('authorization', `Bearer ${token}`);
  }
  const cacheStrategy = options?.cache ?? 'no-store';
  const fetchOptions: any = { headers, cache: cacheStrategy };
  if (options?.revalidate) fetchOptions.next = { revalidate: options.revalidate };
  const response = await fetch(`${apiBaseUrl}${path}`, fetchOptions);
  if (!response.ok) throw new Error(`API request failed: ${response.status}`);
  return response.json() as Promise<T>;
}

export async function userPost<T>(path: string, body: Record<string, unknown>): Promise<T> {
  const token = await getUserApiToken();
  if (!token) throw new Error('User session is required');
  const response = await fetch(`${apiBaseUrl}${path}`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body: JSON.stringify(body), cache: 'no-store' });
  if (!response.ok) throw new Error(`API request failed: ${response.status} ${await response.text()}`);
  return response.json() as Promise<T>;
}

export async function apiPatch<T>(path: string, body: Record<string, unknown>): Promise<T> {
  const token = await getAdminApiToken();
  if (!token) throw new Error('Admin session is required');
  const response = await fetch(`${apiBaseUrl}${path}`, { method: 'PATCH', headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body: JSON.stringify(body), cache: 'no-store' });
  if (!response.ok) throw new Error(`API request failed: ${response.status} ${await response.text()}`);
  return response.json() as Promise<T>;
}

export async function apiPost<T>(path: string, body: Record<string, unknown>): Promise<T> {
  const token = await getAdminApiToken();
  if (!token) throw new Error('Admin session is required');
  const response = await fetch(`${apiBaseUrl}${path}`, { method: 'POST', headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body: JSON.stringify(body), cache: 'no-store' });
  if (!response.ok) throw new Error(`API request failed: ${response.status} ${await response.text()}`);
  return response.json() as Promise<T>;
}

export function getApiBaseUrl() {
  return apiBaseUrl;
}
import 'server-only';

import { getAdminApiToken } from './admin-session';
import { getUserApiToken } from './user-session';
