/* eslint-disable @next/next/no-img-element -- provider photos are served from our own uploads host, not next/image's optimizer */
import Link from 'next/link';
import { apiGet, type Category, type Paginated, type Provider } from '@/lib/api';
import { FavoriteButton } from '@/components/favorite-button';

export const revalidate = 3600;

export default async function HomePage() {
  const [providersResult, categoriesResult] = await Promise.allSettled([
    apiGet<Provider[]>('/api/providers', { revalidate: 3600 }),
    apiGet<Paginated<Category>>('/api/categories', { revalidate: 86400, cache: 'force-cache' })
  ]);
  const providers = providersResult.status === 'fulfilled' ? providersResult.value : [];
  const categories = categoriesResult.status === 'fulfilled' ? categoriesResult.value.data : [];
  return <>
    <section className="heroPanel"><div><span className="eyebrow">منصة خدمات مجتمع قنا</span><h1>كل ما تحتاجه..<br />قريب منك.</h1><p>ابحث عن الخدمات والأماكن، تابع العروض، واعرف الجديد في منطقتك من مكان واحد.</p></div><aside className="heroMetric"><small>مقدمو خدمات ظاهرون الآن</small><strong>{providers.length}</strong><span>متصلون بنفس بيانات تطبيق هنا قنا</span></aside></section>
    <section className="section"><div className="sectionHead"><h2>الفئات</h2><Link href="/providers">شوف الكل</Link></div><div className="categoryRail">{categories.map((category) => <Link className="category" href={`/providers?category=${category.slug}`} key={category.id}><i />{category.name}</Link>)}{categories.length === 0 && <span className="empty">يتم تحميل الفئات من المنصة…</span>}</div></section>
    <section className="section"><div className="sectionHead"><h2>أماكن قريبة منك</h2><Link href="/providers">كل مقدمي الخدمات</Link></div><div className="providerGrid">{providers.slice(0, 6).map((provider) => <ProviderCard key={provider.id} provider={provider} />)}{providers.length === 0 && <div className="surface empty">تعذر الوصول للبيانات الآن. شغّل API هنا قنا ثم أعد المحاولة.</div>}</div></section>
  </>;
}

export function ProviderCard({ provider }: { provider: Provider }) {
  const category = provider.categories[0]?.category.name ?? 'خدمة محلية';
  return <Link href={`/providers/${provider.id}`} className="surface provider"><FavoriteButton id={provider.id} kind="providers" /><div className="providerImage">{provider.images[0]?.url ? <img src={provider.images[0].url} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} /> : '⌖'}</div><div className="providerBody"><div className="providerTitle"><h3>{provider.name}</h3>{provider.isVerified && <span className="badge">موثق</span>}</div><p>{provider.description || 'خدمة قريبة منك داخل قنا.'}</p><span className="providerMeta">{provider.area.name} · {category} · {provider.serviceMode === 'ONLINE' ? 'أونلاين' : 'محلي'}</span></div></Link>;
}
