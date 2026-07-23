import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';
import { updateLifecycle } from '../actions';

export const dynamic = 'force-dynamic';

const entities = [
  { key: 'provider', label: 'الأنشطة' },
  { key: 'listing', label: 'الإعلانات المحلية' },
  { key: 'ad', label: 'إعلانات الرئيسية' },
  { key: 'service', label: 'الخدمات' },
  { key: 'offer', label: 'العروض' },
  { key: 'price', label: 'دليل الأسعار' },
  { key: 'now', label: 'دلوقتي' },
] as const;

type ArchiveItem = { id: string; name?: string; title?: string; archivedAt?: string | null; deletedAt?: string | null; archiveReason?: string | null; provider?: { name: string } };

export default async function ArchivePage({ searchParams }: { searchParams: Promise<{ entity?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const params = await searchParams;
  const entity = entities.some((item) => item.key === params.entity) ? params.entity! : 'provider';
  const result = await apiGet<{ items: ArchiveItem[] }>(`/api/admin/archive?entity=${entity}`, { admin: true }).catch(() => ({ items: [] }));
  const selectedLabel = entities.find((item) => item.key === entity)?.label;
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">دورة حياة البيانات</span><h1 className="pageTitle">الأرشيف والاسترجاع</h1></div></div>
    <p className="pageLead">كل ما يتم أرشفته أو حذفه منطقيًا يظل قابلًا للاسترجاع. الحذف النهائي منفصل ومخصص لمدير النظام.</p>
    <nav className="chipRow" aria-label="أنواع البيانات">{entities.map((item) => <a key={item.key} className={item.key === entity ? 'chip chipActive' : 'chip'} href={`/admin/archive?entity=${item.key}`}>{item.label}</a>)}</nav>
    <section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>{selectedLabel}</h2><span className="badge">{result.items.length}</span></div>
      {result.items.length === 0 ? <p className="empty">لا توجد عناصر مؤرشفة في هذا القسم.</p> : <table><thead><tr><th>العنصر</th><th>الحالة</th><th>السبب</th><th>إجراء</th></tr></thead><tbody>{result.items.map((item) => <tr key={item.id}><td>{item.name ?? item.title ?? item.provider?.name ?? item.id}</td><td><span className="badge">{item.deletedAt ? 'محذوف منطقيًا' : 'مؤرشف'}</span></td><td>{item.archiveReason ?? '—'}</td><td><div className="actionRow"><form action={updateLifecycle}><input type="hidden" name="entity" value={entity} /><input type="hidden" name="id" value={item.id} /><input type="hidden" name="action" value={item.deletedAt ? 'UNDELETE' : 'RESTORE'} /><button className="approveButton" type="submit">استرجاع</button></form><form action={updateLifecycle}><input type="hidden" name="entity" value={entity} /><input type="hidden" name="id" value={item.id} /><input type="hidden" name="action" value="PURGE" /><button className="rejectButton" type="submit">حذف نهائي</button></form></div></td></tr>)}</tbody></table>}
    </section>
  </section>;
}
