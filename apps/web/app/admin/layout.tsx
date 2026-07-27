import { AdminNav } from './admin-nav';
import { apiGet } from '@/lib/api';
import { getAdminApiToken } from '@/lib/admin-session';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const role = await getAdminApiToken() ? (await apiGet<{ role: string }>('/api/admin/auth/me', { admin: true }).catch(() => ({ role: 'OWNER' }))).role : 'OWNER';
  return <div className="adminWorkspace"><AdminNav role={role} /><div className="adminContent">{children}</div></div>;
}
