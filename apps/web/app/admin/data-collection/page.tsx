import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { RecordsPanel } from './RecordsPanel';
import { DuplicatesPanel } from './DuplicatesPanel';
import type { CollectedBusiness, CollectedRecordStatus, DataCollectionOverview, DuplicateCandidate } from './types';

export const dynamic = 'force-dynamic';

const statusOptions: { value: CollectedRecordStatus; label: string }[] = [
  { value: 'NEW', label: 'جديد' },
  { value: 'NEEDS_REVIEW', label: 'بحاجة لمراجعة' },
  { value: 'APPROVED', label: 'معتمد' },
  { value: 'REJECTED', label: 'مرفوض' },
  { value: 'MERGED', label: 'مدموج' },
];

const jobStatusLabels: Record<string, string> = {
  PENDING: 'قيد الانتظار', RUNNING: 'قيد التشغيل', COMPLETED: 'مكتملة', FAILED: 'فشلت', CANCELLED: 'أُلغيت',
};

function formatDateTime(value: string | null) {
  if (!value) return '—';
  return new Date(value).toLocaleString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

type SearchParams = { tab?: string; status?: string; search?: string; category?: string; area?: string; sort?: string };

export default async function DataCollectionAdminPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const tab = query.tab === 'duplicates' || query.tab === 'jobs' ? query.tab : 'records';

  const overview = await apiGet<DataCollectionOverview>('/api/admin/data-collection/overview', { admin: true })
    .catch(() => ({ statuses: {}, unresolvedDuplicates: 0, latestJobs: [] } as DataCollectionOverview));

  const totalRecords = Object.values(overview.statuses).reduce((sum, count) => sum + (count ?? 0), 0);

  let records: CollectedBusiness[] = [];
  let duplicates: DuplicateCandidate[] = [];

  if (tab === 'records') {
    const params = new URLSearchParams({ limit: '100' });
    if (query.status) params.set('status', query.status);
    if (query.search) params.set('search', query.search);
    records = await apiGet<CollectedBusiness[]>(`/api/admin/data-collection/records?${params.toString()}`, { admin: true }).catch(() => []);
    if (query.category) records = records.filter((r) => r.category?.toLowerCase().includes(query.category!.toLowerCase()));
    if (query.area) records = records.filter((r) => r.area?.toLowerCase().includes(query.area!.toLowerCase()));
    if (query.sort === 'date') records = [...records].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
  } else if (tab === 'duplicates') {
    duplicates = await apiGet<DuplicateCandidate[]>('/api/admin/data-collection/duplicates', { admin: true }).catch(() => []);
  }

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
          <option value="quality">ترتيب حسب جودة البيانات</option>
          <option value="date">ترتيب حسب تاريخ الإضافة</option>
        </select>
        <button type="submit">تصفية</button>
      </form>
      <RecordsPanel records={records} />
    </>}

    {tab === 'duplicates' && <section className="section"><DuplicatesPanel duplicates={duplicates} /></section>}

    {tab === 'jobs' && <section className="section surface table">
      {overview.latestJobs.length === 0 ? <p className="empty">لا توجد مهام استيراد حتى الآن.</p> : <table>
        <thead><tr><th>المصدر</th><th>الفئة</th><th>المنطقة</th><th>عدد الموجود</th><th>عدد المحفوظ</th><th>مكرر</th><th>فشل</th><th>الحالة</th><th>البداية</th><th>النهاية</th></tr></thead>
        <tbody>{overview.latestJobs.map((job) => <tr key={job.id}>
          <td>{job.sourceId ?? '—'}</td>
          <td>{job.category ?? '—'}</td>
          <td>{job.area ?? '—'}</td>
          <td>{job.foundCount}</td>
          <td>{job.savedCount}</td>
          <td>{job.duplicateCount}</td>
          <td>{job.failedCount}</td>
          <td><span className="badge">{jobStatusLabels[job.status] ?? job.status}</span></td>
          <td>{formatDateTime(job.startedAt)}</td>
          <td>{formatDateTime(job.finishedAt)}</td>
        </tr>)}</tbody>
      </table>}
    </section>}
  </section>;
}
