'use client';

import { useState, useTransition } from 'react';
import { reviewSocialLink, updateCollectedRecord } from './actions';
import type { CollectedBusiness, CollectedRecordStatus, SocialLinkEvidence, SocialPlatform } from './types';

const socialPlatformHosts: Record<SocialPlatform, string[]> = {
  facebook: ['facebook.com', 'm.facebook.com', 'fb.com', 'fb.watch'],
  instagram: ['instagram.com', 'instagr.am'],
  tiktok: ['tiktok.com', 'vm.tiktok.com'],
};

const platformLabels: Record<SocialPlatform, string> = { facebook: 'فيسبوك', instagram: 'إنستجرام', tiktok: 'تيك توك' };

function isSafeLink(url: string | null | undefined, allowedHosts?: string[]): boolean {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') return false;
    if (!allowedHosts) return true;
    const host = parsed.hostname.toLowerCase();
    return allowedHosts.some((allowed) => host === allowed || host.endsWith(`.${allowed}`));
  } catch {
    return false;
  }
}

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

  const handleSocialAction = (platform: SocialPlatform, action: 'approve' | 'reject' | 'edit', url?: string) => {
    if (!selected) return;
    if (action === 'reject' && !confirm('هل أنت متأكد من رفض هذا الرابط؟')) return;
    startTransition(async () => {
      try {
        const formData = new FormData();
        formData.set('recordId', selected.id);
        formData.set('platform', platform);
        formData.set('action', action);
        if (url) formData.set('url', url);
        const updated = await reviewSocialLink(formData);
        setSelected(updated);
        showToast(true, action === 'approve' ? 'تم اعتماد الرابط' : action === 'reject' ? 'تم رفض الرابط' : 'تم تحديث الرابط');
      } catch (error) {
        showToast(false, error instanceof Error ? error.message : 'تعذر تنفيذ العملية');
      }
    });
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
          {selected.googleMapsUrl && isSafeLink(selected.googleMapsUrl) && (
            <a className="secondaryButton" href={selected.googleMapsUrl} target="_blank" rel="noopener noreferrer" style={{ display: 'inline-block', marginBottom: 10 }}>
              فتح في خرائط جوجل ↗
            </a>
          )}
          {selected.osmId && (
            <a
              className="secondaryButton"
              href={`https://www.openstreetmap.org/${selected.osmId}`}
              target="_blank"
              rel="noopener noreferrer"
              style={{ display: 'inline-block', marginBottom: 10, marginInlineStart: selected.googleMapsUrl ? 8 : 0 }}
            >
              فتح في OpenStreetMap ↗
            </a>
          )}
          {(['facebook', 'instagram', 'tiktok'] as SocialPlatform[]).map((platform) => {
            const url = selected[platform];
            if (!url) return null;
            const info = selected.socialEnrichment?.[platform];
            return <div className="drawerRow" key={platform}>
              <span>{platformLabels[platform]}</span>
              <span>
                {isSafeLink(url, socialPlatformHosts[platform])
                  ? <a href={url} target="_blank" rel="noopener noreferrer">{url}</a>
                  : url}
                {info && <span className="badge" style={{ marginInlineStart: 6 }}>ثقة {(info.confidence * 100).toFixed(0)}٪</span>}
              </span>
            </div>;
          })}
          {selected.website && <div className="drawerRow">
            <span>الموقع</span>
            <span>{isSafeLink(selected.website) ? <a href={selected.website} target="_blank" rel="noopener noreferrer">{selected.website}</a> : selected.website}</span>
          </div>}
          {!selected.facebook && !selected.instagram && !selected.tiktok && !selected.website && !selected.googleMapsUrl && !selected.osmId && (
            <p style={{ color: 'var(--muted)', fontSize: 12 }}>لا توجد روابط تواصل مسجلة.</p>
          )}
        </div>

        {selected.socialCandidates && Object.keys(selected.socialCandidates).length > 0 && (
          <div className="drawerSection">
            <h4>روابط مقترحة للمراجعة</h4>
            {(Object.entries(selected.socialCandidates) as [SocialPlatform, SocialLinkEvidence][]).map(([platform, info]) => (
              <div key={platform} style={{ border: '1px solid var(--line)', borderRadius: 10, padding: 10, marginBottom: 8 }}>
                <div className="drawerRow">
                  <span>{platformLabels[platform]}</span>
                  <span>{isSafeLink(info.url, socialPlatformHosts[platform]) ? <a href={info.url} target="_blank" rel="noopener noreferrer">{info.url}</a> : info.url}</span>
                </div>
                <div style={{ fontSize: 11, color: 'var(--muted)' }}>
                  الثقة: {(info.confidence * 100).toFixed(0)}٪ — الأدلة: {info.evidence.join('، ') || '—'} — المصدر: {info.source}
                </div>
                <div className="actionRow" style={{ marginTop: 8 }}>
                  <button className="approveButton" disabled={isPending} onClick={() => handleSocialAction(platform, 'approve')}>اعتماد الرابط</button>
                  <button className="rejectButton" disabled={isPending} onClick={() => handleSocialAction(platform, 'reject')}>رفض الرابط</button>
                  <button className="noteButton" disabled={isPending} onClick={() => {
                    const manualUrl = prompt('أدخل الرابط الصحيح', info.url);
                    if (manualUrl) handleSocialAction(platform, 'edit', manualUrl);
                  }}>تعديل يدويًا</button>
                </div>
              </div>
            ))}
          </div>
        )}

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
