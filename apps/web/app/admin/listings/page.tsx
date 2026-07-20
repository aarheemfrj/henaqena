import Link from 'next/link'; import { redirect } from 'next/navigation'; import { apiGet, type Area, type Paginated } from '@/lib/api'; import { hasAdminSession } from '@/lib/admin-session'; import { moderateListing, createListingAdmin } from '../actions'; import { AreaPicker } from '@/components/pickers'; import { ImageUploadField } from '@/components/image-upload-field';
export const dynamic = 'force-dynamic';
type Listing = { id: string; title: string; description?: string | null; price: string | number; status: string; owner?: { name?: string | null }; area?: { name: string } };
export default async function ListingsAdminPage({ searchParams }: { searchParams: Promise<{ error?: string; created?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const [items, areasResult, categoriesResult] = await Promise.all([
    apiGet<Listing[]>('/api/admin/listings', { admin: true }).catch(() => []),
    apiGet<Paginated<Area>>('/api/areas', { cache: 'no-store' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
    apiGet<{ data: string[] }>('/api/listings/categories', { cache: 'no-store' }).catch(() => ({ data: [] as string[] })),
  ]);
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">عندك؟</span><h1 className="pageTitle">الإعلانات المحلية</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">راجع الإعلانات التي أضافها المجتمع، مع السعر والمنطقة وصاحب الإعلان.</p>

    <section className="section">
      <div className="sectionHead"><h2>إضافة إعلان مباشرة (يُنشر فورًا بدون مراجعة)</h2></div>
      <form action={createListingAdmin} className="surface formGrid publicForm">
        <label>عنوان الإعلان<input name="title" required minLength={3} /></label>
        <label>النوع<input name="category" list="listingCategoryOptions" required placeholder="اختر نوع موجود أو اكتب نوع جديد" /><datalist id="listingCategoryOptions">{categoriesResult.data.map((category) => <option value={category} key={category} />)}</datalist></label>
        <label>السعر<input name="price" type="number" min="1" step="0.01" required /></label>
        <AreaPicker areas={areasResult.data} />
        <label>مدة النشر (أيام)<input name="expiresInDays" type="number" min="1" max="365" defaultValue="90" /></label>
        <label className="wideField">الوصف<textarea name="description" maxLength={1200} /></label>
        <ImageUploadField name="images" uploadUrl="/api/admin/uploads/provider-images" max={5} label="صور الإعلان" />
        <button className="primaryButton wideField" type="submit">نشر الإعلان الآن</button>
        {query.error === 'images' && <p className="formError wideField">أضف صورة واحدة على الأقل.</p>}
        {query.error === '1' && <p className="formError wideField">تعذر إنشاء الإعلان، راجع البيانات.</p>}
        {query.created === '1' && <p className="wideField" style={{ color: 'var(--teal)', fontSize: 13 }}>تم نشر الإعلان بنجاح.</p>}
      </form>
    </section>

    <section className="section surface table"><table><thead><tr><th>الإعلان</th><th>السعر</th><th>المنطقة</th><th>صاحب الإعلان</th><th>الحالة</th><th>قرار</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}><td>{item.title}<small>{item.description}</small></td><td>{item.price} جنيه</td><td>{item.area?.name ?? '—'}</td><td>{item.owner?.name ?? '—'}</td><td><span className="badge">{item.status}</span></td><td>{item.status === 'PENDING' && <div className="actionRow"><form action={moderateListing}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="ACTIVE"/><button className="approveButton" type="submit">اعتماد</button></form><form action={moderateListing}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="REJECTED"/><button className="rejectButton" type="submit">رفض</button></form></div>}</td></tr>)}</tbody></table></section>
  </section>;
}
