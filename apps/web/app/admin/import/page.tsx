import Link from 'next/link';
import { redirect } from 'next/navigation';
import { hasAdminSession } from '@/lib/admin-session';
import { importProvidersV2 } from '../actions';

type SearchParams = { created?: string; updated?: string; skipped?: string; failed?: string; error?: string };

export default async function ImportAdminPage({ searchParams }: { searchParams: Promise<SearchParams> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const hasResult = query.created !== undefined;
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">مركز البيانات</span><h1 className="pageTitle">استيراد البيانات</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">مكان واحد لإضافة وتحديث الأنشطة. يقبل Excel وCSV، ويطابق الأعمدة تلقائيًا، ويدعم التكرارات والنشر المباشر أو إدخال البيانات للمراجعة.</p>

    {hasResult && <div className="surface" style={{ padding: 18, marginBottom: 18, color: 'var(--deep)' }}>
      تمت العملية: <strong>{query.created ?? 0}</strong> إضافة، <strong>{query.updated ?? 0}</strong> تحديث، <strong>{query.skipped ?? 0}</strong> مكرر تم تجاوزه، <strong>{query.failed ?? 0}</strong> يحتاج مراجعة.
    </div>}
    {query.error && <div className="surface" style={{ padding: 18, marginBottom: 18, color: '#9b1c31' }}>تعذر تنفيذ الاستيراد. تأكد من اختيار ملف صحيح ثم حاول مرة أخرى.</div>}

    <section className="surface formGrid publicForm">
      <div className="wideField" style={{ display: 'flex', justifyContent: 'space-between', gap: 16, alignItems: 'center', flexWrap: 'wrap' }}>
        <div><h2 style={{ margin: 0, color: 'var(--deep)', fontSize: 19 }}>استيراد دفعة جديدة</h2><p className="pageLead" style={{ margin: '6px 0 0' }}>ابدأ من القالب الجاهز حتى تكون الأعمدة متوافقة من أول مرة.</p></div>
        <a className="secondaryButton" href="/admin/import/template.xlsx">تحميل قالب Excel</a>
      </div>
      <form action={importProvidersV2} className="formGrid wideField" encType="multipart/form-data">
        <label>ملف Excel أو CSV<input name="file" type="file" accept=".xlsx,.xls,.csv,text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" required /></label>
        <label>طريقة النشر<select name="publishMode" defaultValue="DIRECT"><option value="DIRECT">نشر مباشر — تمت مراجعته من الإدارة</option><option value="REVIEW">إدخال للمراجعة قبل النشر</option></select></label>
        <label>التعامل مع التكرارات<select name="duplicateMode" defaultValue="UPDATE"><option value="UPDATE">تحديث السجل الموجود</option><option value="SKIP">تخطي السجل الموجود</option><option value="CREATE">إنشاء سجل جديد</option></select></label>
        <button className="primaryButton" type="submit">رفع ومعالجة البيانات</button>
      </form>
    </section>

    <section className="surface" style={{ padding: 18, marginTop: 18 }}>
      <h2 style={{ marginTop: 0 }}>الأعمدة المدعومة</h2>
      <p className="pageLead">الأساسية: name, category, city, area, address, phone — والموسعة: whatsapp, email, website, social links, latitude, longitude, opening hours, image_1 إلى image_10، وبيانات التوثيق.</p>
      <p className="pageLead">بعد الاستيراد تظهر النتائج في الأنشطة وسجل العمليات، مع الاحتفاظ بالبيانات الناقصة والأخطاء للمراجعة.</p>
    </section>
  </section>;
}
