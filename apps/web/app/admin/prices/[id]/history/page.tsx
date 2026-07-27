import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';

export const dynamic = 'force-dynamic';
type History = { id: string; snapshot: Record<string, unknown>; reason?: string | null; createdAt: string };

export default async function PriceHistoryPage({ params }: { params: Promise<{ id: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const { id } = await params;
  const history = await apiGet<History[]>(`/api/admin/prices/${id}/history`, { admin: true }).catch(() => []);
  return <section><div className="sectionHead"><div><span className="eyebrow">تدقيق الأسعار</span><h1 className="pageTitle">سجل تغييرات السعر</h1></div><Link href="/admin/prices">العودة للأسعار</Link></div><section className="section surface table"><table><thead><tr><th>التاريخ</th><th>السبب</th><th>النطاق</th><th>الحالة</th><th>الصلاحية</th></tr></thead><tbody>{history.map((item) => <tr key={item.id}><td>{new Date(item.createdAt).toLocaleString('ar-EG')}</td><td>{item.reason ?? '—'}</td><td>{String(item.snapshot.minPrice ?? '—')} - {String(item.snapshot.maxPrice ?? '—')}</td><td>{String(item.snapshot.status ?? '—')}</td><td>{item.snapshot.validUntil ? String(item.snapshot.validUntil).slice(0, 10) : '—'}</td></tr>)}</tbody></table></section></section>;
}
