import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet, type Area, type Category, type Paginated } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';
import { ImageUploadField } from '@/components/image-upload-field';
import { submitActivity } from './actions';

export const revalidate = 3600;

export default async function AddActivityPage({ searchParams }: { searchParams: Promise<{ error?: string; sent?: string }> }) {
  if (!await getUserApiToken()) redirect('/account');
  const [areasResult, categoriesResult, query] = await Promise.all([
    apiGet<Paginated<Area>>('/api/areas', { revalidate: 86400, cache: 'force-cache' }),
    apiGet<Paginated<Category>>('/api/categories', { revalidate: 86400, cache: 'force-cache' }),
    searchParams
  ]);
  const areas = areasResult.data;
  const categories = categoriesResult.data;
  if (query.sent) return <section className="authPage"><div className="surface successCard"><span className="successIcon">✓</span><h1 className="pageTitle">وصلنا النشاط</h1><p className="pageLead">اتسجل في قاعدة البيانات وبقى في طابور الإدارة. هيوصلك إشعار بعد الاعتماد أو لو محتاج تعديل.</p><Link className="primaryLink" href="/account">العودة للحساب</Link></div></section>;
  return <section><span className="eyebrow">مساهمة المجتمع</span><h1 className="pageTitle">أضف نشاط</h1><p className="pageLead">الطلب يتسجل فعلياً في نفس قاعدة التطبيق ولا يظهر للجمهور قبل مراجعة الإدارة.</p>{query.error && <p className="formError">تعذر الإرسال. راجع البيانات وتأكد أن الاسم أو الرقم غير مكرر.</p>}<form action={submitActivity} className="surface formGrid publicForm"><label>اسم النشاط<input name="name" required minLength={2}/></label><label>نوع النشاط<select name="categoryId" required>{categories.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>المنطقة<select name="areaId" required>{areas.map(item => <option value={item.id} key={item.id}>{item.name}</option>)}</select></label><label>طريقة تقديم الخدمة<select name="serviceMode"><option value="LOCAL">محلي</option><option value="ONLINE">أونلاين</option></select></label><label>رقم الهاتف<input name="phone" inputMode="tel" pattern="01[0125][0-9]{8}"/></label><label>واتساب<input name="whatsapp" inputMode="tel" pattern="01[0125][0-9]{8}"/></label><label>نوع الرقم<select name="phoneType"><option value="BUSINESS">رقم النشاط</option><option value="PERSONAL">رقم شخصي</option></select></label><label>العنوان<input name="address"/></label><label>يفتح<input name="openingTime" type="time" defaultValue="09:00"/></label><label>يغلق<input name="closingTime" type="time" defaultValue="22:00"/></label><label className="wideField">وصف مختصر<textarea name="description" maxLength={1000}/></label><ImageUploadField name="images" uploadUrl="/api/community/uploads/provider-images" /><button className="primaryButton wideField" type="submit">إرسال النشاط للمراجعة</button></form></section>;
}
