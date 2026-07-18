import Link from 'next/link';
import { apiGet, type AdminOverview, type Provider } from '@/lib/api';

export const dynamic = 'force-dynamic';

export default async function AdminPage() {
  const [overviewResult, providersResult] = await Promise.allSettled([apiGet<AdminOverview>('/api/admin/overview', { admin: true }), apiGet<Provider[]>('/api/admin/providers', { admin: true })]);
  const overview = overviewResult.status === 'fulfilled' ? overviewResult.value : null;
  const providers = providersResult.status === 'fulfilled' ? providersResult.value : [];
  return <section><span className="eyebrow">إدارة هنا قنا</span><h1 className="pageTitle">لوحة المتابعة</h1><p className="pageLead">منصة Next.js متصلة بـ API التطبيق نفسه. مفاتيح الإدارة تبقى في الخادم ولا تصل للمتصفح.</p><div className="adminLayout">{[{ label: 'مقدمو خدمة نشطون', value: overview?.providers }, { label: 'بانتظار مراجعة', value: overview?.pending }, { label: 'إعلانات رئيسية نشطة', value: overview?.listings }, { label: 'تقييمات هذا الشهر', value: overview?.reviews }].map((stat) => <article className="surface stat" key={stat.label}><small>{stat.label}</small><strong>{stat.value ?? '—'}</strong><span>{overview ? 'بيانات مباشرة' : 'تحقق من مفتاح الإدارة'}</span></article>)}</div><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>مقدمو الخدمات</h2><Link href="/providers">عرض الدليل</Link></div><table><thead><tr><th>النشاط</th><th>الفئة</th><th>المنطقة</th><th>الحالة</th></tr></thead><tbody>{providers.slice(0, 10).map((provider) => <tr key={provider.id}><td>{provider.name}</td><td>{provider.categories[0]?.category.name ?? '—'}</td><td>{provider.area.name}</td><td><span className="badge">{provider.isVerified ? 'موثق' : 'قيد المراجعة'}</span></td></tr>)}</tbody></table>{providers.length === 0 && <p className="empty">تعذر تحميل بيانات الإدارة. تأكد من `ADMIN_API_KEY`.</p>}</section></section>;
}
