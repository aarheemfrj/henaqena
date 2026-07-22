'use client';

import { useState, useTransition } from 'react';
import { runCollectionJob } from './actions';
import type { CollectionJob } from './types';

const jobStatusLabels: Record<string, string> = {
  PENDING: 'قيد الانتظار', RUNNING: 'قيد التشغيل', COMPLETED: 'مكتملة', FAILED: 'فشلت', CANCELLED: 'أُلغيت',
};

function formatDateTime(value: string | null) {
  if (!value) return '—';
  return new Date(value).toLocaleString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function JobsTable({ jobs }: { jobs: CollectionJob[] }) {
  const [runningId, setRunningId] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  const [toast, setToast] = useState<{ ok: boolean; text: string } | null>(null);

  const showToast = (ok: boolean, text: string) => {
    setToast({ ok, text });
    setTimeout(() => setToast(null), 3800);
  };

  const handleRun = (jobId: string) => {
    setRunningId(jobId);
    startTransition(async () => {
      try {
        await runCollectionJob(jobId);
        showToast(true, 'بدأ تشغيل المهمة — تابع تقدمها هنا');
      } catch (error) {
        showToast(false, error instanceof Error ? error.message : 'تعذر تشغيل المهمة');
      } finally {
        setRunningId(null);
      }
    });
  };

  if (jobs.length === 0) return <p className="empty">لا توجد مهام استيراد حتى الآن.</p>;

  return <>
    <table>
      <thead><tr>
        <th>المصدر</th><th>الفئة</th><th>المنطقة</th><th>عدد الموجود</th><th>عدد المحفوظ</th><th>مكرر</th><th>فشل</th>
        <th>إثراء السوشيال</th><th>التقدم</th><th>الحالة</th><th>البداية</th><th>النهاية</th><th>إجراء</th>
      </tr></thead>
      <tbody>{jobs.map((job) => {
        const progress = job.metadata?.progress;
        const canRun = job.sourceId === 'google-maps' && job.status === 'PENDING';
        return <tr key={job.id}>
          <td>{job.sourceId ?? '—'}</td>
          <td>{job.category ?? '—'}</td>
          <td>{job.area ?? '—'}</td>
          <td>{job.foundCount}</td>
          <td>{job.savedCount}</td>
          <td>{job.duplicateCount}</td>
          <td>{job.failedCount}</td>
          <td>{progress ? progress.enrichedCount : '—'}</td>
          <td>{progress ? `${progress.processed} / ${progress.total}` : '—'}</td>
          <td>
            <span className="badge">{jobStatusLabels[job.status] ?? job.status}</span>
            {job.error && <div style={{ marginTop: 4, color: '#b42318', fontSize: 11 }}>{job.error}</div>}
          </td>
          <td>{formatDateTime(job.startedAt)}</td>
          <td>{formatDateTime(job.finishedAt)}</td>
          <td>
            {canRun && <button type="button" className="secondaryButton" disabled={isPending && runningId === job.id} onClick={() => handleRun(job.id)}>
              {isPending && runningId === job.id ? 'جارٍ البدء...' : 'تشغيل'}
            </button>}
          </td>
        </tr>;
      })}</tbody>
    </table>
    {toast && <div className="toastStack"><div className={`toast ${toast.ok ? 'toastOk' : 'toastErr'}`}>{toast.text}</div></div>}
  </>;
}
