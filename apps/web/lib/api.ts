export type Area = { id: string; name: string };
export type Category = { id: string; name: string; slug: string };
export type Provider = {
  id: string;
  name: string;
  description?: string | null;
  isVerified: boolean;
  communityAdded: boolean;
  serviceMode: 'LOCAL' | 'ONLINE';
  openingTime?: string | null;
  closingTime?: string | null;
  area: Area;
  images: { url: string; sortOrder: number }[];
  categories: { category: Category }[];
};
export type AdminOverview = { providers: number; pending: number; listings: number; reviews: number };

const apiBaseUrl = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://127.0.0.1:4000';

export async function apiGet<T>(path: string, options?: { admin?: boolean }): Promise<T> {
  const headers = new Headers();
  if (options?.admin) headers.set('x-admin-key', process.env.ADMIN_API_KEY ?? 'dev-henaqena-admin');
  const response = await fetch(`${apiBaseUrl}${path}`, { headers, cache: 'no-store' });
  if (!response.ok) throw new Error(`API request failed: ${response.status}`);
  return response.json() as Promise<T>;
}

export function getApiBaseUrl() {
  return apiBaseUrl;
}
