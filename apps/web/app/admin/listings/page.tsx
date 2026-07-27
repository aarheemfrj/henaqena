import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet, type Area, type Paginated } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { createListingAdmin, moderateListing, updateLifecycle, updateListingAdmin } from '../actions';
import { AreaPicker } from '@/components/pickers';
import { ImageUploadField } from '@/components/image-upload-field';

export const dynamic = 'force-dynamic';
type Listing = { id: string; title: string; description?: string | null; price: string | number; category: string; status: string; expiresAt?: string | null; images: { url: string }[]; owner?: { id: string; name?: string | null }; area?: { id: string; name: string } };
type User = { id: string; name: string; role: string };

export default async function ListingsAdminPage({ searchParams }: { searchParams: Promise<{ error?: string; created?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const query = await searchParams;
  const [items, areasResult, categoriesResult, users] = await Promise.all([
    apiGet<Listing[]>('/api/admin/listings', { admin: true }).catch(() => []),
    apiGet<Paginated<Area>>('/api/areas', { cache: 'no-store' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
    apiGet<{ data: string[] }>('/api/listings/categories', { cache: 'no-store' }).catch(() => ({ data: [] as string[] })),
    apiGet<User[]>('/api/admin/users', { admin: true }).catch(() => []),
  ]);
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">عندك؟</span><h1 className="pageTitle">الإعلانات المحلية</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">تحكم كامل في الإعلان: المحتوى، السعر، النوع، المنطقة، الصور، المالك، مدة النشر والحالة.</p>
    <section className="section">
      <div className="sectionHead"><h2>إضافة إعلان مباشرة</h2></div>
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
        {query.error === '1' && <p className="formError wideField">تعذر حفظ الإعلان، راجع البيانات.</p>}
        {query.created === '1' && <p className="wideField" style={{ color: 'var(--teal)', fontSize: 13 }}>تم نشر الإعلان بنجاح.</p>}
      </form>
    </section>
    <section className="section surface table"><table><thead><tr><th>التعديل الكامل</th><th>المنطقة/الانتهاء</th><th>الحالة والمالك</th><th>قرار</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}><td><form action={updateListingAdmin} className="compactForm"><input type="hidden" name="id" value={item.id}/><input name="title" defaultValue={item.title} required minLength={3}/><select name="category" defaultValue={item.category}>{categoriesResult.data.map((category) => <option value={category} key={category}>{category}</option>)}{!categoriesResult.data.includes(item.category) && <option value={item.category}>{item.category}</option>}</select><input name="price" type="number" min="1" step="0.01" defaultValue={item.price} required/><select name="areaId" defaultValue={item.area?.id ?? ''}>{areasResult.data.map((area) => <option value={area.id} key={area.id}>{area.name}</option>)}</select><select name="ownerId" defaultValue={item.owner?.id ?? ''}>{users.map((user) => <option value={user.id} key={user.id}>{user.name} · {user.role}</option>)}</select><input name="expiresAt" type="date" defaultValue={item.expiresAt ? item.expiresAt.slice(0, 10) : ''}/><textarea name="description" defaultValue={item.description ?? ''} maxLength={1200} placeholder="الوصف"/><ImageUploadField name="images" uploadUrl="/api/admin/uploads/provider-images" max={5} label="صور الإعلان" initialImages={item.images}/><button className="secondaryButton" type="submit">حفظ كل التعديلات</button></form></td><td>{item.area?.name ?? '—'}<small>{item.expiresAt ? `ينتهي ${new Date(item.expiresAt).toLocaleDateString('ar-EG')}` : 'بدون انتهاء'}</small></td><td><span className="badge">{item.status}</span><small>{item.owner?.name ?? '—'}</small></td><td><div className="actionRow"><form action={moderateListing}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="ACTIVE"/><button className="approveButton" type="submit">نشر</button></form><form action={moderateListing}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="ARCHIVED"/><button className="secondaryButton" type="submit">أرشفة</button></form><form action={updateLifecycle}><input type="hidden" name="entity" value="listing"/><input type="hidden" name="id" value={item.id}/><input type="hidden" name="action" value="DELETE"/><input type="hidden" name="reason" value="حذف إداري"/><button className="rejectButton" type="submit">حذف</button></form></div></td></tr>)}</tbody></table></section>
  </section>;
}
