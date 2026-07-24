import Link from 'next/link'; import { redirect } from 'next/navigation'; import { apiGet, type Area, type Category, type Paginated } from '@/lib/api'; import { hasAdminSession } from '@/lib/admin-session'; import { moderateProvider, verifyProvider, createProviderAdmin, deleteProvider } from '../actions'; import { AreaPicker, CategoryPicker } from '@/components/pickers'; import { ImageUploadField } from '@/components/image-upload-field';
export const dynamic = 'force-dynamic'; type Provider = { id: string; name: string; status: string; isVerified: boolean; area: { name: string }; categories: { category: { name: string } }[] };
export default async function ProvidersAdminPage({ searchParams }: { searchParams: Promise<{ error?: string; created?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const [items, areasResult, categoriesResult] = await Promise.all([
    apiGet<Provider[]>('/api/admin/providers', { admin: true }).catch(() => []),
    apiGet<Paginated<Area>>('/api/areas', { cache: 'no-store' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
    apiGet<Paginated<Category>>('/api/categories', { cache: 'no-store' }).catch(() => ({ data: [] as Category[], total: 0, limit: 0, offset: 0 })),
  ]);
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">الدليل</span><h1 className="pageTitle">مقدمو الخدمات</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">راجع كل الأنشطة، مصدر الإضافة، المنطقة، وحالة التوثيق.</p>

    <section className="section">
      <div className="sectionHead"><h2>إضافة نشاط مباشرة (يُنشر فورًا بدون مراجعة)</h2></div>
      <form action={createProviderAdmin} className="surface formGrid publicForm">
        <label>اسم النشاط<input name="name" required minLength={2} /></label>
        <CategoryPicker categories={categoriesResult.data} />
        <AreaPicker areas={areasResult.data} />
        <label>طريقة تقديم الخدمة<select name="serviceMode" defaultValue="LOCAL"><option value="LOCAL">محلي</option><option value="ONLINE">أونلاين</option></select></label>
        <label>رقم الهاتف<input name="phone" inputMode="tel" pattern="01[0125][0-9]{8}" /></label>
        <label>واتساب<input name="whatsapp" inputMode="tel" pattern="01[0125][0-9]{8}" /></label>
        <label>نوع الرقم<select name="phoneType" defaultValue="BUSINESS"><option value="BUSINESS">رقم النشاط</option><option value="PERSONAL">رقم شخصي</option></select></label>
        <label>العنوان<input name="address" /></label>
        <label>يفتح<input name="openingTime" type="time" defaultValue="09:00" /></label>
        <label>يغلق<input name="closingTime" type="time" defaultValue="22:00" /></label>
        <label className="wideField">وصف مختصر<textarea name="description" maxLength={1000} /></label>
        <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}><input type="checkbox" name="isVerified" value="true" defaultChecked style={{ width: 16, height: 16 }} /> وسم &quot;موثق&quot;</label>
        <ImageUploadField name="images" uploadUrl="/api/admin/uploads/provider-images" label="صور النشاط" />
        <button className="primaryButton wideField" type="submit">نشر النشاط الآن</button>
        {query.error === 'images' && <p className="formError wideField">أضف صورة واحدة على الأقل.</p>}
        {query.error === '1' && <p className="formError wideField">تعذر إنشاء النشاط، راجع البيانات.</p>}
        {query.created === '1' && <p className="wideField" style={{ color: 'var(--teal)', fontSize: 13 }}>تم نشر النشاط بنجاح.</p>}
      </form>
    </section>

    <section className="section surface table"><table><thead><tr><th>النشاط</th><th>الفئة</th><th>المنطقة</th><th>التوثيق</th><th>الحالة</th><th>إدارة</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}><td><Link href={`/admin/providers/${item.id}`} style={{ color: 'var(--deep)', fontWeight: 700 }}>{item.name}</Link></td><td>{item.categories[0]?.category.name ?? '—'}</td><td>{item.area.name}</td><td>{item.isVerified ? 'موثق' : 'غير موثق'}</td><td><span className="badge">{item.status}</span></td><td><div className="actionRow" style={{ flexWrap: 'wrap' }}><Link className="secondaryButton" href={`/admin/providers/${item.id}`}>تعديل شامل</Link>{!item.isVerified && <form action={verifyProvider}><input type="hidden" name="id" value={item.id}/><button className="approveButton" type="submit">توثيق</button></form>}{item.status === 'PENDING' && <><form action={moderateProvider}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="APPROVED"/><button className="approveButton" type="submit">اعتماد</button></form><form action={moderateProvider}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="REJECTED"/><button className="rejectButton" type="submit">رفض</button></form></>}<form action={deleteProvider}><input type="hidden" name="id" value={item.id}/><button className="rejectButton" type="submit">حذف</button></form></div></td></tr>)}</tbody></table></section>
  </section>;
}
