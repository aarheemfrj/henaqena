/* eslint-disable @next/next/no-img-element -- admin-approved external listing images use multiple temporary hosts */
import Link from 'next/link';
import { apiGet, type Area, type Paginated } from '@/lib/api';
import { FavoriteButton } from '@/components/favorite-button';

type Listing = { id: string; title: string; description?: string | null; category: string; price: number; area?: { name: string } | null; images: { url: string }[]; owner?: { name: string } | null; expiresAt: string };
type ApiResponse = { data: Listing[]; total: number; page: number; pageSize: number };

export const revalidate = 600;

export default async function ListingsPage({ searchParams }: { searchParams: Promise<{ page?: string; search?: string; category?: string; area?: string }> }) {
  const params = await searchParams;
  const page = Math.max(1, Number(params.page ?? 1));
  const queryParams = new URLSearchParams({
    page: String(page),
    pageSize: '20',
    ...(params.search && { q: params.search }),
    ...(params.category && { category: params.category }),
    ...(params.area && { areaId: params.area }),
  });
  const [response, areasResult, categoriesResult] = await Promise.all([
    apiGet<ApiResponse>(`/api/listings?${queryParams}`, { revalidate: 600 }).catch(() => ({ data: [], total: 0, page, pageSize: 20 })),
    apiGet<Paginated<Area>>('/api/areas', { revalidate: 86400, cache: 'force-cache' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
    apiGet<{ data: string[] }>('/api/listings/categories', { revalidate: 300 }).catch(() => ({ data: [] as string[] })),
  ]);
  const listings = response.data;
  const totalPages = Math.ceil(response.total / 20);
  const qs = (extra: Record<string, string>) => new URLSearchParams({ ...(params.search && { search: params.search }), ...(params.category && { category: params.category }), ...(params.area && { area: params.area }), ...extra }).toString();
  return <section>
    <span className="eyebrow">مجتمع هنا قنا</span><h1 className="pageTitle">عندك؟</h1><p className="pageLead">إعلانات حقيقية أضافها المجتمع وراجعتها الإدارة، وتختفي تلقائياً عند انتهاء مدة النشر.</p>
    <form className="surface filterBar" method="get">
      <input type="search" name="search" placeholder="ابحث في العنوان أو الوصف…" defaultValue={params.search ?? ''} />
      <select name="category" defaultValue={params.category ?? ''}><option value="">كل الأنواع</option>{categoriesResult.data.map((category) => <option value={category} key={category}>{category}</option>)}</select>
      <select name="area" defaultValue={params.area ?? ''}><option value="">كل المناطق</option>{areasResult.data.map((area) => <option value={area.id} key={area.id}>{area.name}</option>)}</select>
      <button className="secondaryButton" type="submit">بحث</button>
    </form>
    <div className="section contentGrid">
      {listings.map((item) => <Link href={`/listings/${item.id}`} className="surface contentCard" key={item.id}><FavoriteButton id={item.id} kind="listings" />{item.images[0]?.url ? <img src={item.images[0].url} alt="" /> : <div className="contentPlaceholder">◇</div>}<div><div className="providerTitle"><h3>{item.title}</h3><span className="badge">{item.category}</span></div><p>{item.description || 'بدون وصف إضافي'}</p><strong>{item.price.toLocaleString('ar-EG')} جنيه</strong><small>{item.area?.name ?? 'قنا'} · {item.owner?.name ?? 'قناوي'}</small></div></Link>)}
      {listings.length === 0 && <div className="surface empty">لا توجد إعلانات منشورة حالياً.</div>}
    </div>
    {totalPages > 1 && <div className="pagination"><span>صفحة {page} من {totalPages}</span>{page > 1 && <a href={`?${qs({ page: String(page - 1) })}`}>← السابقة</a>}{page < totalPages && <a href={`?${qs({ page: String(page + 1) })}`}>التالية →</a>}</div>}
  </section>;
}
