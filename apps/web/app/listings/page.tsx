/* eslint-disable @next/next/no-img-element -- admin-approved external listing images use multiple temporary hosts */
import { apiGet } from '@/lib/api';

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
  const response = await apiGet<ApiResponse>(`/api/listings?${queryParams}`, { revalidate: 600 }).catch(() => ({ data: [], total: 0, page, pageSize: 20 }));
  const listings = response.data;
  const totalPages = Math.ceil(response.total / 20);
  return <section><span className="eyebrow">مجتمع هنا قنا</span><h1 className="pageTitle">عندك؟</h1><p className="pageLead">إعلانات حقيقية أضافها المجتمع وراجعتها الإدارة، وتختفي تلقائياً عند انتهاء مدة النشر.</p><div className="section contentGrid">{listings.map((item) => <article className="surface contentCard" key={item.id}>{item.images[0]?.url ? <img src={item.images[0].url} alt="" /> : <div className="contentPlaceholder">◇</div>}<div><div className="providerTitle"><h3>{item.title}</h3><span className="badge">{item.category}</span></div><p>{item.description || 'بدون وصف إضافي'}</p><strong>{item.price.toLocaleString('ar-EG')} جنيه</strong><small>{item.area?.name ?? 'قنا'} · {item.owner?.name ?? 'قناوي'}</small></div></article>)}{listings.length === 0 && <div className="surface empty">لا توجد إعلانات منشورة حالياً.</div>}</div>{totalPages > 1 && <div className="pagination"><span>صفحة {page} من {totalPages}</span>{page > 1 && <a href={`?page=${page - 1}${params.search ? `&search=${params.search}` : ''}${params.category ? `&category=${params.category}` : ''}${params.area ? `&area=${params.area}` : ''}`}>← السابقة</a>}{page < totalPages && <a href={`?page=${page + 1}${params.search ? `&search=${params.search}` : ''}${params.category ? `&category=${params.category}` : ''}${params.area ? `&area=${params.area}` : ''}`}>التالية →</a>}</div>}</section>;
}
