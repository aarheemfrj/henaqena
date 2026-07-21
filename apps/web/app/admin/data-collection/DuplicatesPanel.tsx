'use client';

import { useState, useTransition } from 'react';
import { resolveDuplicateRecord } from './actions';
import type { CollectedBusiness, DuplicateCandidate } from './types';

const diffFields: Array<{ key: keyof CollectedBusiness; label: string }> = [
  { key: 'name', label: 'الاسم' },
  { key: 'category', label: 'الفئة' },
  { key: 'phone', label: 'الهاتف' },
  { key: 'address', label: 'العنوان' },
  { key: 'area', label: 'المركز / المنطقة' },
];

export function DuplicatesPanel({ duplicates }: { duplicates: DuplicateCandidate[] }) {
  const [resolvedIds, setResolvedIds] = useState<Set<string>>(new Set());
  const [isPending, startTransition] = useTransition();
  const [toast, setToast] = useState<{ ok: boolean; text: string } | null>(null);

  const showToast = (ok: boolean, text: string) => {
    setToast({ ok, text });
    setTimeout(() => setToast(null), 3200);
  };

  const resolve = (id: string, resolution: 'MERGE_LEFT' | 'MERGE_RIGHT' | 'NOT_DUPLICATE', confirmText: string | null, successText: string) => {
    if (confirmText && !confirm(confirmText)) return;
    startTransition(async () => {
      try {
        await resolveDuplicateRecord(id, resolution);
        setResolvedIds((prev) => new Set(prev).add(id));
        showToast(true, successText);
      } catch {
        showToast(false, 'تعذر تنفيذ العملية، حاول مرة أخرى');
      }
    });
  };

  const visible = duplicates.filter((duplicate) => !resolvedIds.has(duplicate.id));

  if (visible.length === 0) return <section className="section surface"><p className="empty">لا توجد حالات تكرار بحاجة للمراجعة حاليًا.</p></section>;

  return <>
    {visible.map((duplicate) => <section className="surface duplicateGrid" key={duplicate.id}>
      <div className="duplicateMeta">
        <strong style={{ color: 'var(--deep)' }}>نسبة التشابه: {Math.round(duplicate.score * 100)}%</strong>
        <span>سبب الاشتباه: {duplicate.reason}</span>
      </div>
      <div>
        <h4>السجل الأول</h4>
        {diffFields.map((field) => <div className="diffField" key={field.key}>
          <b>{field.label}</b>
          <span className={duplicate.left[field.key] !== duplicate.right[field.key] ? 'diffMismatch' : undefined}>{String(duplicate.left[field.key] ?? '—')}</span>
        </div>)}
      </div>
      <div>
        <h4>السجل الثاني</h4>
        {diffFields.map((field) => <div className="diffField" key={field.key}>
          <b>{field.label}</b>
          <span className={duplicate.left[field.key] !== duplicate.right[field.key] ? 'diffMismatch' : undefined}>{String(duplicate.right[field.key] ?? '—')}</span>
        </div>)}
      </div>
      <div className="duplicateActions">
        <button className="approveButton" disabled={isPending} onClick={() => resolve(duplicate.id, 'MERGE_LEFT', 'سيتم اعتبار السجل الثاني مدمجًا داخل الأول. هل تريد المتابعة؟', 'تم الاحتفاظ بالسجل الأول ودمج الثاني')}>الاحتفاظ بالأول ودمج الثاني</button>
        <button className="approveButton" disabled={isPending} onClick={() => resolve(duplicate.id, 'MERGE_RIGHT', 'سيتم اعتبار السجل الأول مدمجًا داخل الثاني. هل تريد المتابعة؟', 'تم الاحتفاظ بالثاني ودمج الأول')}>الاحتفاظ بالثاني ودمج الأول</button>
        <button className="secondaryButton" disabled={isPending} onClick={() => resolve(duplicate.id, 'NOT_DUPLICATE', null, 'تم وسم السجلين كغير مكررين')}>ليسا مكررين</button>
      </div>
    </section>)}
    {toast && <div className="toastStack"><div className={`toast ${toast.ok ? 'toastOk' : 'toastErr'}`}>{toast.text}</div></div>}
  </>;
}
