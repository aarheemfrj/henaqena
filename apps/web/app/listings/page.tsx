/* eslint-disable @next/next/no-img-element -- admin-approved external listing images use multiple temporary hosts */
import { apiGet } from '@/lib/api';

type Listing = { id: string; title: string; description?: string | null; category: string; price: number; area?: { name: string } | null; images: { url: string }[]; owner?: { name: string } | null; expiresAt: string };

export const dynamic = 'force-dynamic';

export default async function ListingsPage() {
  const listings = await apiGet<Listing[]>('/api/listings').catch(() => []);
  return <section><span className="eyebrow">مجتمع هنا قنا</span><h1 className="pageTitle">عندك؟</h1><p className="pageLead">إعلانات حقيقية أضافها المجتمع وراجعتها الإدارة، وتختفي تلقائياً عند انتهاء مدة النشر.</p><div className="section contentGrid">{listings.map((item) => <article className="surface contentCard" key={item.id}>{item.images[0]?.url ? <img src={item.images[0].url} alt="" /> : <div className="contentPlaceholder">◇</div>}<div><div className="providerTitle"><h3>{item.title}</h3><span className="badge">{item.category}</span></div><p>{item.description || 'بدون وصف إضافي'}</p><strong>{item.price.toLocaleString('ar-EG')} جنيه</strong><small>{item.area?.name ?? 'قنا'} · {item.owner?.name ?? 'قناوي'}</small></div></article>)}{listings.length === 0 && <div className="surface empty">لا توجد إعلانات منشورة حالياً.</div>}</div></section>;
}
