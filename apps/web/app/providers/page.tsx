import { apiGet, type Area, type Category, type Paginated, type Provider } from '@/lib/api';
import { ProviderCard } from '../page';

export const revalidate = 3600;

type ApiResponse = { data: Provider[]; total: number; page: number; pageSize: number };

export default async function ProvidersPage({ searchParams }: { searchParams: Promise<{ page?: string; search?: string; category?: string; area?: string; verified?: string }> }) {
  const params = await searchParams;
  const page = Math.max(1, Number(params.page ?? 1));
  const queryParams = new URLSearchParams({
    page: String(page),
    pageSize: '20',
    ...(params.search && { q: params.search }),
    ...(params.category && { category: params.category }),
    ...(params.area && { areaId: params.area }),
    ...(params.verified === '1' && { verified: 'true' }),
  });
  const [response, categoriesResult, areasResult] = await Promise.all([
    apiGet<ApiResponse | Provider[]>(`/api/providers?${queryParams}`, { revalidate: 600 }).catch(() => [] as Provider[]),
    apiGet<Paginated<Category>>('/api/categories', { revalidate: 86400, cache: 'force-cache' }).catch(() => ({ data: [] as Category[], total: 0, limit: 0, offset: 0 })),
    apiGet<Paginated<Area>>('/api/areas', { revalidate: 86400, cache: 'force-cache' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
  ]);
  const providers = Array.isArray(response) ? response : response.data;
  const totalPages = Array.isArray(response) ? 1 : Math.ceil(response.total / 20);
  const qs = (extra: Record<string, string>) => new URLSearchParams({ ...(params.search && { search: params.search }), ...(params.category && { category: params.category }), ...(params.area && { area: params.area }), ...(params.verified && { verified: params.verified }), ...extra }).toString();
  return <section>
    <span className="eyebrow">دليل قنا</span><h1 className="pageTitle">مين؟</h1><p className="pageLead">أماكن وخدمات مضافة ومراجعة من الإدارة، بنفس البيانات التي تظهر في تطبيق هنا قنا.</p>
    <form className="surface filterBar" method="get">
      <input type="search" name="search" placeholder="ابحث عن اسم، خدمة، أو عنوان…" defaultValue={params.search ?? ''} />
      <select name="category" defaultValue={params.category ?? ''}><option value="">كل الفئات</option>{categoriesResult.data.map((category) => <option value={category.slug} key={category.id}>{category.name}</option>)}</select>
      <select name="area" defaultValue={params.area ?? ''}><option value="">كل المناطق</option>{areasResult.data.map((area) => <option value={area.id} key={area.id}>{area.name}</option>)}</select>
      <label style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13, color: 'var(--muted)' }}><input type="checkbox" name="verified" value="1" defaultChecked={params.verified === '1'} style={{ width: 16, height: 16 }} /> موثق فقط</label>
      <button className="secondaryButton" type="submit">بحث</button>
    </form>
    <div className="section">
      <div className="providerGrid">{providers.map((provider) => <ProviderCard provider={provider} key={provider.id} />)}{providers.length === 0 && <div className="surface empty">لا توجد بيانات متاحة حالياً.</div>}</div>
      {totalPages > 1 && <div className="pagination"><span>صفحة {page} من {totalPages}</span>{page > 1 && <a href={`?${qs({ page: String(page - 1) })}`}>← السابقة</a>}{page < totalPages && <a href={`?${qs({ page: String(page + 1) })}`}>التالية →</a>}</div>}
    </div>
  </section>;
}
