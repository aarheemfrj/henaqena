import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';

export const dynamic = 'force-dynamic';
const entities = [{ key: 'providers', label: 'الأنشطة', title: 'name' }, { key: 'listings', label: 'الإعلانات المحلية', title: 'title' }, { key: 'ads', label: 'إعلانات الرئيسية', title: 'name' }, { key: 'services', label: 'الخدمات', title: 'name' }, { key: 'offers', label: 'العروض', title: 'title' }, { key: 'prices', label: 'الأسعار', title: 'name' }, { key: 'now', label: 'دلوقتي', title: 'title' }] as const;
type Item = { id: string; name?: string; title?: string; status?: string; area?: { name: string }; provider?: { name: string } };

export default async function CatalogPage({ searchParams }: { searchParams: Promise<{ entity?: string; q?: string; status?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const params = await searchParams;
  const entity = entities.some((item) => item.key === params.entity) ? params.entity! : 'providers';
  const q = params.q ?? '';
  const status = params.status ?? '';
  const result = await apiGet<{ items: Item[] }>(`/api/admin/catalog?entity=${entity}&q=${encodeURIComponent(q)}${status ? `&status=${status}` : ''}`, { admin: true }).catch(() => ({ items: [] }));
  return <section><div className="sectionHead"><div><span className="eyebrow">إدارة موحدة</span><h1 className="pageTitle">سجل البيانات</h1></div></div><p className="pageLead">ابحث في كل محتوى المنصة من شاشة واحدة، ثم افتح القسم المتخصص للتعديل أو الاعتماد.</p><nav className="chipRow">{entities.map((item) => <a key={item.key} className={item.key === entity ? 'chip chipActive' : 'chip'} href={`/admin/catalog?entity=${item.key}`}>{item.label}</a>)}</nav><form className="filterBar surface" method="get"><input type="hidden" name="entity" value={entity} /><input name="q" placeholder="بحث بالاسم أو العنوان" defaultValue={q} /><select name="status" defaultValue={status}><option value="">كل الحالات</option><option value="PENDING">قيد المراجعة</option><option value="APPROVED">منشور</option><option value="ACTIVE">نشط</option><option value="ARCHIVED">مؤرشف</option><option value="REJECTED">مرفوض</option></select><button className="primaryButton" type="submit">بحث</button></form><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>{entities.find((item) => item.key === entity)?.label}</h2><span className="badge">{result.items.length}</span></div>{result.items.length === 0 ? <p className="empty">لا توجد نتائج.</p> : <table><thead><tr><th>الاسم</th><th>المنطقة</th><th>الحالة</th><th>المعرف</th></tr></thead><tbody>{result.items.map((item) => <tr key={item.id}><td>{item.name ?? item.title ?? '—'}{item.provider ? <small className="muted">{item.provider.name}</small> : null}</td><td>{item.area?.name ?? 'كل المناطق'}</td><td><span className="badge">{item.status ?? '—'}</span></td><td><code>{item.id}</code></td></tr>)}</tbody></table>}</section></section>;
}
