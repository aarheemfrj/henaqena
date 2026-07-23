import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';

export const dynamic = 'force-dynamic';
type Summary = { totals: Record<string, number>; pending: Record<string, number>; quality: Record<string, number> };
const names: Record<string, string> = { providers: 'الأنشطة', listings: 'الإعلانات المحلية', ads: 'إعلانات الرئيسية', reviews: 'التقييمات', missingProviderLocation: 'أنشطة بلا موقع', missingProviderPhone: 'أنشطة بلا هاتف' };
export default async function AnalyticsPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const data = await apiGet<Summary>('/api/admin/reports/summary', { admin: true }).catch(() => ({ totals: {}, pending: {}, quality: {} }));
  return <section><div className="sectionHead"><div><span className="eyebrow">تقارير وتشغيل</span><h1 className="pageTitle">التقارير وجودة البيانات</h1></div></div><p className="pageLead">ملخص تشغيلي سريع يساعدك على معرفة حجم المحتوى وما يحتاج مراجعة أو استكمال.</p><div className="adminLayout">{Object.entries(data.totals).map(([key, value]) => <article className="surface stat" key={key}><small>{names[key] ?? key}</small><strong>{value}</strong><span>إجمالي مسجل</span></article>)}</div><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>العناصر المعلقة</h2></div><table><thead><tr><th>القسم</th><th>العدد</th><th>الخطوة التالية</th></tr></thead><tbody>{Object.entries(data.pending).map(([key, value]) => <tr key={key}><td>{names[key] ?? key}</td><td><span className="badge">{value}</span></td><td>فتح مركز الاعتماد</td></tr>)}</tbody></table></section><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>جودة بيانات الأنشطة</h2></div><table><thead><tr><th>المؤشر</th><th>العدد</th><th>الإجراء المقترح</th></tr></thead><tbody>{Object.entries(data.quality).map(([key, value]) => <tr key={key}><td>{names[key] ?? key}</td><td><span className="badge">{value}</span></td><td>استكمال من سجل البيانات أو الاستيراد</td></tr>)}</tbody></table></section></section>;
}
