import { apiGet } from '@/lib/api';

type NowItem = { id: string; title: string; body?: string | null; category: string; startsAt: string; endsAt?: string | null; area?: { name: string } | null };

export const dynamic = 'force-dynamic';

export default async function NowPage() {
  const updates = await apiGet<NowItem[]>('/api/now').catch(() => []);
  return <section><span className="eyebrow">قنا الآن</span><h1 className="pageTitle">دلوقتي</h1><p className="pageLead">افتتاحات وتنبيهات وفعاليات محلية اعتمدتها الإدارة من نفس بيانات التطبيق.</p><div className="section timeline">{updates.map((item) => <article className="surface nowCard" key={item.id}><span className="liveDot"/><div><div className="providerTitle"><h3>{item.title}</h3><span className="badge">{item.category}</span></div><p>{item.body || 'لا توجد تفاصيل إضافية.'}</p><small>{item.area?.name ?? 'قنا كلها'} · {new Date(item.startsAt).toLocaleDateString('ar-EG')}</small></div></article>)}{updates.length === 0 && <div className="surface empty">لا توجد تحديثات نشطة حالياً.</div>}</div></section>;
}
