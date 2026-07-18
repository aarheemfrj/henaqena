import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { createNow, moderateNow } from '../actions';

export const dynamic = 'force-dynamic';
type NowItem = { id: string; title: string; body?: string | null; category: string; status: string };

export default async function NowAdminPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const items = await apiGet<NowItem[]>('/api/admin/now', { admin: true }).catch(() => []);
  return <section><div className="sectionHead"><div><span className="eyebrow">المحتوى المحلي</span><h1 className="pageTitle">إدارة «دلوقتي»</h1></div><Link href="/admin">العودة للوحة</Link></div><p className="pageLead">انشر تنبيهات وفعاليات وافتتاحات مرتبطة بقنا أو بمنطقة محددة.</p><form action={createNow} className="surface formGrid"><label>العنوان<input name="title" required /></label><label>التصنيف<input name="category" defaultValue="عام" /></label><label>التفاصيل<input name="body" /></label><button className="primaryButton" type="submit">نشر التحديث</button></form><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>التحديثات المنشورة</h2><span className="badge">{items.length}</span></div><table><thead><tr><th>العنوان</th><th>التصنيف</th><th>الحالة</th><th>إجراء</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}><td>{item.title}<small>{item.body}</small></td><td>{item.category}</td><td><span className="badge">{item.status}</span></td><td>{item.status === 'PENDING' && <div className="actionRow"><form action={moderateNow}><input type="hidden" name="id" value={item.id} /><input type="hidden" name="status" value="APPROVED" /><button className="approveButton" type="submit">اعتماد</button></form><form action={moderateNow}><input type="hidden" name="id" value={item.id} /><input type="hidden" name="status" value="REJECTED" /><button className="rejectButton" type="submit">رفض</button></form></div>}</td></tr>)}</tbody></table></section></section>;
}
