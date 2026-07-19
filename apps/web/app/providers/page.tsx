import { apiGet, type Provider } from '@/lib/api';
import { ProviderCard } from '../page';

export const revalidate = 3600;

type ApiResponse = { data: Provider[]; total: number; page: number; pageSize: number };

export default async function ProvidersPage({ searchParams }: { searchParams: Promise<{ page?: string; search?: string; category?: string; area?: string }> }) {
  const params = await searchParams;
  const page = Math.max(1, Number(params.page ?? 1));
  const queryParams = new URLSearchParams({
    page: String(page),
    pageSize: '20',
    ...(params.search && { q: params.search }),
    ...(params.category && { category: params.category }),
    ...(params.area && { areaId: params.area }),
  });
  const response = await apiGet<ApiResponse>(`/api/providers?${queryParams}`, { revalidate: 600 }).catch(() => ({ data: [], total: 0, page, pageSize: 20 }));
  const providers = response.data;
  const totalPages = Math.ceil(response.total / 20);
  return <section><span className="eyebrow">دليل قنا</span><h1 className="pageTitle">مين؟</h1><p className="pageLead">أماكن وخدمات مضافة ومراجعة من الإدارة، بنفس البيانات التي تظهر في تطبيق هنا قنا.</p><div className="section"><div className="providerGrid">{providers.map((provider) => <ProviderCard provider={provider} key={provider.id} />)}{providers.length === 0 && <div className="surface empty">لا توجد بيانات متاحة حالياً.</div>}</div>{totalPages > 1 && <div className="pagination"><span>صفحة {page} من {totalPages}</span>{page > 1 && <a href={`?page=${page - 1}${params.search ? `&search=${params.search}` : ''}${params.category ? `&category=${params.category}` : ''}${params.area ? `&area=${params.area}` : ''}`}>← السابقة</a>}{page < totalPages && <a href={`?page=${page + 1}${params.search ? `&search=${params.search}` : ''}${params.category ? `&category=${params.category}` : ''}${params.area ? `&area=${params.area}` : ''}`}>التالية →</a>}</div>}</div></section>;
}
