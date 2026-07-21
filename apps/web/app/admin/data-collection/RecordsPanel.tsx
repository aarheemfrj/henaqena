'use client';

import { useState, useTransition } from 'react';
import { updateCollectedRecord } from './actions';
import type { CollectedBusiness, CollectedRecordStatus } from './types';

const statusLabels: Record<CollectedRecordStatus, string> = {
  NEW: 'جديد',
  NEEDS_REVIEW: 'بحاجة لمراجعة',
  APPROVED: 'معتمد',
  REJECTED: 'مرفوض',
  MERGED: 'مدموج',
};

const statusColors: Record<CollectedRecordStatus, string> = {
  NEW: 'rgba(13,143,138,.11)',
  NEEDS_REVIEW: 'rgba(233,180,76,.22)',
  APPROVED: '#daf5e8',
  REJECTED: '#fde7e5',
  MERGED: 'rgba(31,41,51,.08)',
};

function formatDate(value: string) {
  return new Date(value).toLocaleDateString('ar-EG', { year: 'numeric', month: 'short', day: 'numeric' });
}

const socialFields: Array<{ key: keyof CollectedBusiness; label: string }> = [
  { key: 'website', label: 'الموقع' },
  { key: 'facebook', label: 'فيسبوك' },
  { key: 'instagram', label: 'إنستجرام' },
  { key: 'tiktok', label: 'تيك توك' },
  { key: 'googleMapsUrl', label: 'خرائط جوجل' },
];

export function RecordsPanel({ records }: { records: CollectedBusiness[] }) {
  const [selected, setSelected] = useState<CollectedBusiness | null>(null);
  const [note, setNote] = useState('');
  const [isPending, startTransition] = useTransition();
  const [toast, setToast] = useState<{ ok: boolean; text: string } | null>(null);

  const showToast = (ok: boolean, text: string) => {
    setToast({ ok, text });
    setTimeout(() => setToast(null), 3200);
  };

  const openRecord = (record: CollectedBusiness) => {
    setSelected(record);
    setNote(record.reviewNote ?? '');
  };

  const run = (status: CollectedRecordStatus, close: boolean, successText: string) => {
    if (!selected) return;
    const id = selected.id;
    startTransition(async () => {
      try {
        const updated = await updateCollectedRecord(id, status, note);
        showToast(true, successText);
        if (close) setSelected(null);
        else setSelected(updated);
      } catch {
        showToast(false, 'تعذر تنفيذ العملية، حاول مرة أخرى');
      }
    });
  };

  const handleReject = () => {
    if (!confirm('هل أنت متأكد من رفض هذا السجل؟')) return;
    run('REJECTED', true, 'تم رفض السجل');
  };

  return <>
    <section className="section surface table">
      {records.length === 0 ? <p className="empty">لا توجد سجلات مطابقة للفلاتر الحالية.</p> : <table>
        <thead><tr>
          <th>اسم النشاط</th><th>الفئة</th><th>المركز / المنطقة</th><th>الهاتف</th><th>العنوان</th><th>مصدر البيانات</th><th>جودة البيانات</th><th>الحالة</th><th>تاريخ الإضافة</th>
        </tr></thead>
        <tbody>{records.map((record) => <tr key={record.id} className="clickableRow" onClick={() => openRecord(record)}>
          <td>{record.name}</td>
          <td>{record.category ?? '—'}</td>
          <td>{record.area ?? record.city}</td>
          <td>{record.phone ?? '—'}</td>
          <td>{record.address ?? '—'}</td>
          <td>{record.sourceId ?? '—'}</td>
          <td>{record.qualityScore}</td>
          <td><span className="badge" style={{ background: statusColors[record.status] }}>{statusLabels[record.status]}</span></td>
          <td>{formatDate(record.createdAt)}</td>
        </tr>)}</tbody>
      </table>}
    </section>

    {selected && <div className="drawerOverlay" onClick={() => setSelected(null)}>
      <div className="drawer" onClick={(event) => event.stopPropagation()}>
        <div className="drawerHead">
          <div><span className="eyebrow">مراجعة سجل</span><h2 className="pageTitle" style={{ fontSize: 22 }}>{selected.name}</h2></div>
          <button className="drawerClose" onClick={() => setSelected(null)} aria-label="إغلاق">×</button>
        </div>

        <div className="drawerSection">
          <h4>البيانات الأساسية</h4>
          <div className="drawerRow"><span>الفئة</span><span>{selected.category ?? '—'}{selected.subcategory ? ` / ${selected.subcategory}` : ''}</span></div>
          <div className="drawerRow"><span>المدينة / المركز / القرية</span><span>{[selected.city, selected.area, selected.village].filter(Boolean).join(' / ')}</span></div>
          <div className="drawerRow"><span>العنوان</span><span>{selected.address ?? '—'}</span></div>
          <div className="drawerRow"><span>الهاتف</span><span>{selected.phone ?? '—'}</span></div>
          <div className="drawerRow"><span>واتساب</span><span>{selected.whatsapp ?? '—'}</span></div>
          <div className="drawerRow"><span>الإحداثيات</span><span>{selected.latitude && selected.longitude ? `${selected.latitude}, ${selected.longitude}` : '—'}</span></div>
          <div className="drawerRow"><span>التقييم</span><span>{selected.rating ? `${selected.rating} (${selected.reviewCount ?? 0} تقييم)` : '—'}</span></div>
          <div className="drawerRow"><span>مصدر البيانات</span><span>{selected.sourceId ?? '—'}</span></div>
          <div className="drawerRow"><span>درجة الجودة</span><span>{selected.qualityScore} / 100</span></div>
        </div>

        <div className="drawerSection">
          <h4>روابط التواصل</h4>
          {socialFields.some((field) => selected[field.key]) ? socialFields.map((field) => selected[field.key] ? (
            <div className="drawerRow" key={field.key}><span>{field.label}</span><span>{String(selected[field.key])}</span></div>
          ) : null) : <p style={{ color: 'var(--muted)', fontSize: 12 }}>لا توجد روابط تواصل مسجلة.</p>}
        </div>

        <div className="drawerSection">
          <h4>البيانات الخام (Raw Data)</h4>
          <pre className="rawDataBox">{JSON.stringify(selected.rawData ?? {}, null, 2)}</pre>
        </div>

        <div className="drawerSection">
          <h4>ملاحظة المراجع</h4>
          <textarea className="noteInput" value={note} onChange={(event) => setNote(event.target.value)} placeholder="اكتب ملاحظة للمراجعة..." />
        </div>

        <div className="drawerActions">
          <button className="approveButton" disabled={isPending} onClick={() => run('APPROVED', true, 'تم اعتماد السجل')}>اعتماد</button>
          <button className="rejectButton" disabled={isPending} onClick={handleReject}>رفض</button>
          <button className="returnButton" disabled={isPending} onClick={() => run('NEEDS_REVIEW', true, 'تم إرجاع السجل للمراجعة')}>إعادة للمراجعة</button>
          <button className="noteButton" disabled={isPending} onClick={() => run(selected.status, false, 'تم حفظ الملاحظة')}>حفظ ملاحظة المراجع</button>
        </div>
      </div>
    </div>}

    {toast && <div className="toastStack"><div className={`toast ${toast.ok ? 'toastOk' : 'toastErr'}`}>{toast.text}</div></div>}
  </>;
}
