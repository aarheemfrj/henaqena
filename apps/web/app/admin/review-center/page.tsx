import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';
import { moderateQueueItem } from '../actions';

export const dynamic = 'force-dynamic';
type Item = { id: string; entity: string; label: string; context?: string; createdAt: string };
const labels: Record<string, string> = { provider: 'نشاط', listing: 'إعلان محلي', ad: 'إعلان رئيسي', service: 'خدمة', offer: 'عرض', price: 'سعر', now: 'دلوقتي', review: 'تقييم', reply: 'رد' };

export default async function ReviewCenterPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const result = await apiGet<{ items: Item[] }>('/api/admin/review-queue', { admin: true }).catch(() => ({ items: [] }));
  return <section><div className="sectionHead"><div><span className="eyebrow">مراجعة موحدة</span><h1 className="pageTitle">مركز الاعتماد</h1></div><span className="badge">{result.items.length} معلّق</span></div><p className="pageLead">كل طلبات المحتوى الجديدة في قائمة واحدة، مع اعتماد أو رفض مباشر وإعادة التحقق من المصدر.</p><section className="section surface table">{result.items.length === 0 ? <p className="empty">لا توجد عناصر بانتظار المراجعة.</p> : <table><thead><tr><th>النوع</th><th>العنصر</th><th>المصدر</th><th>التاريخ</th><th>القرار</th></tr></thead><tbody>{result.items.map((item) => <tr key={`${item.entity}-${item.id}`}><td><span className="badge">{labels[item.entity] ?? item.entity}</span></td><td>{item.label}</td><td>{item.context ?? '—'}</td><td>{new Date(item.createdAt).toLocaleDateString('ar-EG')}</td><td><div className="actionRow"><form action={moderateQueueItem}><input type="hidden" name="entity" value={item.entity} /><input type="hidden" name="id" value={item.id} /><input type="hidden" name="status" value={item.entity === 'listing' ? 'ACTIVE' : 'APPROVED'} /><button className="approveButton" type="submit">اعتماد</button></form><form action={moderateQueueItem}><input type="hidden" name="entity" value={item.entity} /><input type="hidden" name="id" value={item.id} /><input type="hidden" name="status" value={item.entity === 'listing' ? 'ARCHIVED' : 'REJECTED'} /><button className="rejectButton" type="submit">رفض</button></form></div></td></tr>)}</tbody></table>}</section></section>;
}
