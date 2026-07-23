import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';
import { createDatabaseBackup, deleteDatabaseBackup, factoryReset, fullFactoryReset, restoreDatabaseBackup, updateBackupSchedule } from '../actions';

export const dynamic = 'force-dynamic';
type Backup = { filename: string; size: number };
type Schedule = { enabled: boolean; interval: '3d' | '6d' | 'week' | 'month'; nextRunAt: string | null };
const labels: Record<Schedule['interval'], string> = { '3d': 'كل 3 أيام', '6d': 'كل 6 أيام', week: 'كل أسبوع', month: 'كل شهر' };
const scopes = [
  ['providers', 'الأنشطة والخدمات الأساسية'], ['listings', 'الإعلانات المحلية'], ['reviews', 'التقييمات والردود'],
  ['ads', 'إعلانات الرئيسية'], ['prices', 'دليل الأسعار'], ['now', 'دلوقتي'], ['users', 'حسابات المستخدمين'],
  ['notifications', 'الإشعارات'], ['audit', 'سجل العمليات'], ['uploads', 'الصور والملفات المرفوعة'], ['categories', 'الفئات غير المستخدمة'],
];

function formatBytes(bytes: number) { return `${(bytes / 1024 / 1024).toFixed(2)} MB`; }

export default async function MaintenancePage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const result = await apiGet<{ backups: Backup[]; schedule: Schedule }>('/api/admin/backups', { admin: true });
  const errorMessage = query.error === 'full-password'
    ? 'اكتب كلمة مرور الحساب الرئيسي.'
    : query.error === 'full-confirm'
    ? 'اكتب عبارة التأكيد كاملة قبل المسح الشامل.'
    : query.error === 'full-reset'
    ? 'تعذر تنفيذ المسح الشامل. تأكد من كلمة المرور وصلاحية المالك.'
    : query.error === 'confirm'
    ? 'عبارة تأكيد ضبط المصنع غير صحيحة.'
    : null;
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">الأمان والاستمرارية</span><h1 className="pageTitle">النسخ والصيانة</h1></div></div>
    {errorMessage && <p className="formError">{errorMessage}</p>}
    <p className="pageLead">كل عملية حساسة تحتاج صلاحية المالك وتُسجل في سجل العمليات. النسخ الاحتياطي لا يحذف أي بيانات.</p>
    <div className="adminLayout">
      <section className="surface section"><div className="sectionHead"><h2>نسخ احتياطي تلقائي</h2><span className="badge">{result.schedule.enabled ? 'مفعل' : 'متوقف'}</span></div>
        <form action={updateBackupSchedule} className="formGrid">
          <label><input type="checkbox" name="enabled" defaultChecked={result.schedule.enabled} /> تشغيل النسخ التلقائي</label>
          <label>التكرار<select name="interval" defaultValue={result.schedule.interval}>{Object.entries(labels).map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select></label>
          <button className="primaryButton" type="submit">حفظ الجدول</button>
        </form>
        <p className="muted">{result.schedule.nextRunAt ? `النسخة القادمة: ${new Date(result.schedule.nextRunAt).toLocaleString('ar-EG')}` : 'لم يتم تحديد نسخة قادمة.'}</p>
      </section>
      <section className="surface section"><div className="sectionHead"><h2>نسخة فورية</h2></div><p className="muted">ينشئ نسخة PostgreSQL كاملة بصيغة آمنة للاسترجاع.</p><form action={createDatabaseBackup}><button className="primaryButton" type="submit">إنشاء نسخة الآن</button></form></section>
    </div>
    <section className="surface section table"><div className="sectionHead"><h2>النسخ الموجودة</h2><span className="badge">{result.backups.length}</span></div>
      {result.backups.length === 0 ? <p className="empty">لا توجد نسخ محفوظة بعد.</p> : <table><thead><tr><th>الملف</th><th>الحجم</th><th>الإجراءات</th></tr></thead><tbody>{result.backups.map((backup) => <tr key={backup.filename}><td dir="ltr">{backup.filename}</td><td>{formatBytes(backup.size)}</td><td><div className="actionRow"><form action={restoreDatabaseBackup}><input type="hidden" name="filename" value={backup.filename} /><button className="approveButton" type="submit">استرجاع</button></form><form action={deleteDatabaseBackup}><input type="hidden" name="filename" value={backup.filename} /><button className="rejectButton" type="submit">حذف</button></form></div></td></tr>)}</tbody></table>}
    </section>
    <section className="surface section"><div className="sectionHead"><h2>ضبط المصنع — حذف اختياري</h2><span className="badge">خطر</span></div><p className="muted">اختر ما تريد حذفه فقط. الفئات غير المستخدمة فقط يتم حذفها؛ الفئات المرتبطة بأنشطة تظل محفوظة.</p>
      <form action={factoryReset} className="formGrid dangerPanel">
        {scopes.map(([value, label]) => <label key={value}><input type="checkbox" name="scopes" value={value} /> {label}</label>)}
        <label>للتأكيد اكتب <code>RESET_HENA_QENA</code><input name="confirm" required placeholder="RESET_HENA_QENA" /></label>
        <button className="rejectButton" type="submit">تنفيذ الحذف المحدد</button>
      </form>
    </section>
    <section className="surface section dangerPanel"><div className="sectionHead"><div><h2>مسح شامل لقاعدة البيانات</h2><p className="muted">يمسح كل الأنشطة والإعلانات والمستخدمين والإعدادات والملفات، ثم يعيد إنشاء حساب المدير الأساسي فقط.</p></div><span className="badge">خطر شديد</span></div>
      <p className="muted">سيبقى حساب المدير الأساسي محفوظًا للمنصة والتطبيق: <strong dir="ltr">aarheemfrj@gmail.com · 01092034981</strong>. سيتم إنهاء جلسة الإدارة بعد التنفيذ، وسجّل الدخول من جديد.</p>
      <form action={fullFactoryReset} className="formGrid">
        <label>كلمة مرور الحساب الرئيسي<input name="ownerPassword" type="password" required autoComplete="current-password" /></label>
        <label>للتأكيد اكتب <code>WIPE_HENA_QENA</code><input name="confirm" required placeholder="WIPE_HENA_QENA" /></label>
        <button className="rejectButton" type="submit">مسح شامل وإبقاء حساب المدير</button>
      </form>
    </section>
  </section>;
}
