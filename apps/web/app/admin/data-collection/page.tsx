import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { RecordsPanel } from './RecordsPanel';
import { DuplicatesPanel } from './DuplicatesPanel';
import { JobLauncherCard } from './JobLauncherCard';
import { JobsTable } from './JobsTable';
import type { CollectedBusiness, CollectedRecordStatus, DataCollectionOverview, DataSourceOption, DuplicateCandidate, RecordsPage } from './types';

const RECORDS_PAGE_SIZE = 50;

const sortOptions: { value: string; label: string }[] = [
  { value: 'quality', label: 'ترتيب حسب جودة البيانات' },
  { value: 'newest', label: 'الأحدث أولًا' },
  { value: 'oldest', label: 'الأقدم أولًا' },
  { value: 'name', label: 'الاسم أبجديًا' },
];

export const dynamic = 'force-dynamic';

const statusOptions: { value: CollectedRecordStatus; label: string }[] = [
  { value: 'NEW', label: 'جديد' },
  { value: 'NEEDS_REVIEW', label: 'بحاجة لمراجعة' },
  { value: 'APPROVED', label: 'معتمد' },
  { value: 'REJECTED', label: 'مرفوض' },
  { value: 'MERGED', label: 'مدموج' },
];

type SearchParams = { tab?: string; status?: string; search?: string; category?: string; area?: string; sort?: string; offset?: string };

export default async function DataCollectionAdminPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const tab = query.tab === 'duplicates' || query.tab === 'jobs' ? query.tab : 'records';

  const [overview, sourcesResult] = await Promise.all([
    apiGet<DataCollectionOverview>('/api/admin/data-collection/overview', { admin: true })
      .catch(() => ({ statuses: {}, unresolvedDuplicates: 0, latestJobs: [] } as DataCollectionOverview)),
    apiGet<{ items: DataSourceOption[] }>('/api/admin/data-collection/sources', { admin: true })
      .catch(() => ({ items: [] as DataSourceOption[] })),
  ]);

  const totalRecords = Object.values(overview.statuses).reduce((sum, count) => sum + (count ?? 0), 0);

  let records: CollectedBusiness[] = [];
  let duplicates: DuplicateCandidate[] = [];
  let pagination: RecordsPage['pagination'] = { total: 0, limit: RECORDS_PAGE_SIZE, offset: 0, hasMore: false };

  const parsedOffset = Number(query.offset ?? '0');
  const offset = Number.isFinite(parsedOffset) && parsedOffset > 0 ? Math.floor(parsedOffset) : 0;

  if (tab === 'records') {
    const params = new URLSearchParams({ limit: String(RECORDS_PAGE_SIZE), offset: String(offset) });
    if (query.status) params.set('status', query.status);
    if (query.search) params.set('search', query.search);
    if (query.category) params.set('category', query.category);
    if (query.area) params.set('area', query.area);
    if (query.sort) params.set('sortBy', query.sort);
    const page = await apiGet<RecordsPage>(`/api/admin/data-collection/records?${params.toString()}`, { admin: true })
      .catch(() => ({ items: [], pagination: { total: 0, limit: RECORDS_PAGE_SIZE, offset, hasMore: false } } as RecordsPage));
    records = page.items;
    pagination = page.pagination;
  } else if (tab === 'duplicates') {
    duplicates = await apiGet<DuplicateCandidate[]>('/api/admin/data-collection/duplicates', { admin: true }).catch(() => []);
  }

  const pageHref = (newOffset: number) => {
    const params = new URLSearchParams({ tab: 'records' });
    if (query.search) params.set('search', query.search);
    if (query.status) params.set('status', query.status);
    if (query.category) params.set('category', query.category);
    if (query.area) params.set('area', query.area);
    if (query.sort) params.set('sort', query.sort);
    params.set('offset', String(newOffset));
    return `/admin/data-collection?${params.toString()}`;
  };

  const tabLink = (value: string, label: string) => <Link key={value} href={`/admin/data-collection?tab=${value}`} className={tab === value ? 'tabLinkActive' : 'tabLink'}>{label}</Link>;

  return <section>
    <div className="sectionHead"><div><span className="eyebrow">Data Collection</span><h1 className="pageTitle">تجميع البيانات</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">مراجعة السجلات التي تم تجميعها تلقائيًا من مصادر مختلفة، اعتمادها أو رفضها، وحل حالات التكرار قبل نشرها كأنشطة رسمية.</p>

    <section className="section surface grid">
      <div className="stat"><small>إجمالي السجلات</small><strong>{totalRecords}</strong></div>
      <div className="stat"><small>سجلات جديدة</small><strong>{overview.statuses.NEW ?? 0}</strong></div>
      <div className="stat"><small>بحاجة لمراجعة</small><strong>{overview.statuses.NEEDS_REVIEW ?? 0}</strong></div>
      <div className="stat"><small>معتمدة</small><strong>{overview.statuses.APPROVED ?? 0}</strong></div>
      <div className="stat"><small>مرفوضة</small><strong>{overview.statuses.REJECTED ?? 0}</strong></div>
      <div className="stat"><small>مدموجة</small><strong>{overview.statuses.MERGED ?? 0}</strong></div>
      <div className="stat"><small>حالات تكرار غير محلولة</small><strong>{overview.unresolvedDuplicates}</strong></div>
      <div className="stat"><small>آخر مهام الاستيراد</small><strong>{overview.latestJobs.length}</strong></div>
    </section>

    <section className="section">
      <JobLauncherCard sources={sourcesResult.items} />
    </section>

    <div className="tabBar">
      {tabLink('records', 'السجلات')}
      {tabLink('duplicates', `حالات التكرار${overview.unresolvedDuplicates ? ` (${overview.unresolvedDuplicates})` : ''}`)}
      {tabLink('jobs', 'مهام الاستيراد')}
    </div>

    {tab === 'records' && <>
      <form className="surface filterBar" method="get">
        <input type="hidden" name="tab" value="records" />
        <input name="search" placeholder="بحث بالاسم أو الهاتف" defaultValue={query.search ?? ''} />
        <select name="status" defaultValue={query.status ?? ''}>
          <option value="">كل الحالات</option>
          {statusOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
        </select>
        <input name="category" placeholder="الفئة" defaultValue={query.category ?? ''} />
        <input name="area" placeholder="المركز / المنطقة" defaultValue={query.area ?? ''} />
        <select name="sort" defaultValue={query.sort ?? 'quality'}>
          {sortOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
        </select>
        <button type="submit">تصفية</button>
      </form>
      <RecordsPanel records={records} />
      <div className="pageFooter">
        <span>{pagination.total} نتيجة</span>
        <div className="actionRow">
          {offset > 0
            ? <Link href={pageHref(Math.max(0, offset - RECORDS_PAGE_SIZE))} className="secondaryButton">السابق</Link>
            : <span className="secondaryButton disabledLink">السابق</span>}
          {pagination.hasMore
            ? <Link href={pageHref(offset + RECORDS_PAGE_SIZE)} className="secondaryButton">التالي</Link>
            : <span className="secondaryButton disabledLink">التالي</span>}
        </div>
      </div>
    </>}

    {tab === 'duplicates' && <section className="section"><DuplicatesPanel duplicates={duplicates} /></section>}

    {tab === 'jobs' && <section className="section surface table">
      <JobsTable jobs={overview.latestJobs} />
    </section>}
  </section>;
}
