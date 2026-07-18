import { apiGet } from '@/lib/api';

type Price = { id: string; name: string; category?: string | null; minPrice: number; maxPrice: number; unit?: string | null; sourceNote?: string | null; area?: { name: string } | null };

export const dynamic = 'force-dynamic';

export default async function PricesPage() {
  const prices = await apiGet<Price[]>('/api/prices').catch(() => []);
  return <section><span className="eyebrow">العروض والأسعار</span><h1 className="pageTitle">بكام؟</h1><p className="pageLead">نطاقات سعرية معتمدة تساعدك تقارن من غير ما نوهمك بسعر ثابت لخدمة متغيرة.</p><div className="section contentGrid">{prices.map((item) => <article className="surface priceCard" key={item.id}><span className="badge">{item.category || 'عام'}</span><h3>{item.name}</h3><strong>{item.minPrice.toLocaleString('ar-EG')} — {item.maxPrice.toLocaleString('ar-EG')} جنيه</strong><small>{item.unit || 'للوحدة'} · {item.area?.name ?? 'قنا كلها'}</small>{item.sourceNote && <p>{item.sourceNote}</p>}</article>)}{prices.length === 0 && <div className="surface empty">لا توجد أسعار معتمدة حالياً.</div>}</div></section>;
}
