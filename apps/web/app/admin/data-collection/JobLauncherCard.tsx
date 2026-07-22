'use client';

import { useRef, useState, useTransition } from 'react';
import { createCollectionJob, runCollectionJob, uploadCsvForJob } from './actions';
import { dataCollectionAreaOptions, dataCollectionCategories, OTHER_AREA_VALUE } from '@/lib/data-collection-options';
import type { CsvImportOutcome, DataSourceOption, NewCollectionJob } from './types';

export function JobLauncherCard({ sources }: { sources: DataSourceOption[] }) {
  const firstActive = sources.find((source) => source.isActive) ?? sources[0];
  const [sourceId, setSourceId] = useState(firstActive?.id ?? '');
  const [category, setCategory] = useState(dataCollectionCategories[0]?.value ?? '');
  const [areaSelect, setAreaSelect] = useState(dataCollectionAreaOptions[0]?.value ?? '');
  const [areaOther, setAreaOther] = useState('');
  const [query, setQuery] = useState('');
  const [limit, setLimit] = useState(50);

  const [job, setJob] = useState<NewCollectionJob | null>(null);
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [csvResult, setCsvResult] = useState<CsvImportOutcome | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const [isPending, startTransition] = useTransition();
  const [isUploading, startUploadTransition] = useTransition();
  const [toast, setToast] = useState<{ ok: boolean; text: string } | null>(null);

  const showToast = (ok: boolean, text: string) => {
    setToast({ ok, text });
    setTimeout(() => setToast(null), 3800);
  };

  const isGoogleMaps = sourceId === 'google-maps';
  const isOsm = sourceId === 'osm';
  const isAutoRunSource = isGoogleMaps || isOsm;

  const handleCreate = () => {
    const area = areaSelect === OTHER_AREA_VALUE ? areaOther.trim() : areaSelect;
    if (!sourceId) return showToast(false, 'اختر مصدر البيانات');
    if (!category) return showToast(false, 'اختر الفئة');
    if (!area) return showToast(false, 'حدد المركز أو المنطقة');

    startTransition(async () => {
      try {
        const formData = new FormData();
        formData.set('sourceId', sourceId);
        formData.set('category', category);
        formData.set('area', area);
        formData.set('query', query);
        formData.set('limit', String(limit));
        const created = await createCollectionJob(formData);
        setJob(created);
        setCsvResult(null);
        setCsvFile(null);

        if (isAutoRunSource) {
          await runCollectionJob(created.id);
          showToast(true, `تم إنشاء المهمة رقم ${created.id} وبدأ التشغيل — تابع تقدمها من تبويب "مهام الاستيراد"`);
        } else {
          showToast(true, `تم إنشاء مهمة التجميع رقم ${created.id}`);
        }
      } catch (error) {
        showToast(false, error instanceof Error ? error.message : 'تعذر إنشاء المهمة');
      }
    });
  };

  const handleUpload = () => {
    if (!job || !csvFile) return;
    startUploadTransition(async () => {
      try {
        const formData = new FormData();
        formData.set('jobId', job.id);
        formData.set('file', csvFile);
        const result = await uploadCsvForJob(formData);
        setCsvResult(result);
        showToast(true, 'تم رفع ملف CSV وتنفيذ الاستيراد');
      } catch (error) {
        showToast(false, error instanceof Error ? error.message : 'تعذر رفع الملف');
      }
    });
  };

  return <section className="surface formGrid publicForm">
    <h2 className="wideField" style={{ margin: 0, color: 'var(--deep)', fontSize: 18 }}>بدء عملية تجميع جديدة</h2>

    <label>مصدر البيانات
      <select value={sourceId} onChange={(event) => setSourceId(event.target.value)}>
        {sources.map((source) => <option key={source.id} value={source.id} disabled={!source.isActive}>
          {source.name}{!source.isActive ? ' — قريبًا' : ''}
        </option>)}
      </select>
      {sourceId === 'manual-csv' && <small style={{ color: 'var(--muted)' }}>بعد إنشاء المهمة ارفع ملف CSV المرتبط بها.</small>}
      {isGoogleMaps && <small style={{ color: 'var(--muted)' }}>
        ⚠ نتائج Google Maps تستهلك حصة (quota) مدفوعة من حساب Google الخاص بالمنصة — الحد الأقصى الحالي لهذه المهمة: {Math.min(limit, 60)} نتيجة (السقف الأقصى لكل مهمة هو 60 نتيجة).
      </small>}
      {isOsm && <small style={{ color: 'var(--muted)' }}>
        ✅ مصدر مجاني بالكامل بدون أي مفتاح أو تكلفة — لكن اكتمال البيانات في قنا قد يكون أقل من الخرائط التجارية لأن OpenStreetMap يعتمد على متطوعين.
      </small>}
    </label>

    <label>الفئة
      <select value={category} onChange={(event) => setCategory(event.target.value)}>
        {dataCollectionCategories.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
      </select>
    </label>

    <label>المركز / المنطقة
      <select value={areaSelect} onChange={(event) => setAreaSelect(event.target.value)}>
        {dataCollectionAreaOptions.map((option) => <option key={option.value} value={option.value}>{option.label}</option>)}
      </select>
    </label>

    {areaSelect === OTHER_AREA_VALUE && <label>اسم المنطقة أو القرية
      <input value={areaOther} onChange={(event) => setAreaOther(event.target.value)} placeholder="اكتب اسم المنطقة أو القرية" />
    </label>}

    <label>كلمة بحث إضافية
      <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="اختياري" />
    </label>

    <label>الحد الأقصى للنتائج
      <input type="number" min={1} max={500} value={limit} onChange={(event) => setLimit(Number(event.target.value) || 50)} />
    </label>

    <button type="button" className="primaryButton wideField" disabled={isPending} onClick={handleCreate}>
      {isPending ? 'جارٍ التنفيذ...' : isAutoRunSource ? 'إنشاء وتشغيل المهمة' : 'إنشاء مهمة تجميع'}
    </button>

    {job && <div className="wideField" style={{ padding: 14, border: '1px solid var(--line)', borderRadius: 14, background: 'rgba(13,143,138,.04)' }}>
      <p style={{ margin: 0, fontSize: 13, color: 'var(--deep)', fontWeight: 700 }}>تم إنشاء المهمة رقم: {job.id}</p>
      {job.sourceId === 'manual-csv' && <div style={{ marginTop: 10, display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: 10 }}>
        <input ref={fileInputRef} type="file" accept=".csv" onChange={(event) => setCsvFile(event.target.files?.[0] ?? null)} />
        {csvFile && <small style={{ color: 'var(--muted)' }}>{csvFile.name}</small>}
        <button type="button" className="secondaryButton" disabled={!csvFile || isUploading} onClick={handleUpload}>
          {isUploading ? 'جارٍ الرفع...' : 'رفع ملف CSV'}
        </button>
      </div>}
      {csvResult && <p style={{ margin: '10px 0 0', fontSize: 12, color: 'var(--muted)' }}>
        النتيجة: {csvResult.found} صف، {csvResult.saved} محفوظ، {csvResult.duplicates} مكرر، {csvResult.failed} فشل.
      </p>}
    </div>}

    {toast && <div className="toastStack"><div className={`toast ${toast.ok ? 'toastOk' : 'toastErr'}`}>{toast.text}</div></div>}
  </section>;
}
