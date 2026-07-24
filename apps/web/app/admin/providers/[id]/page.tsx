import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet, type Area, type Category, type Paginated } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { updateProviderAdmin } from '../../actions';
import { ImageUploadField } from '@/components/image-upload-field';

export const dynamic = 'force-dynamic';
type Provider = {
  id: string; name: string; externalId?: string | null; description?: string | null; logoUrl?: string | null;
  phone?: string | null; whatsapp?: string | null; email?: string | null; website?: string | null;
  facebookUrl?: string | null; instagramUrl?: string | null; tiktokUrl?: string | null; socialPlatform?: string | null; socialUrl?: string | null;
  address?: string | null; latitude?: number | null; longitude?: number | null; serviceMode: string; phoneType: string;
  openingTime?: string | null; closingTime?: string | null; openingHours?: unknown; isVerified: boolean; status: string;
  area: { id: string; name: string }; images: { url: string; kind?: string }[];
  categories: { category: { id: string; name: string } }[];
  kidFriendly: boolean; accessible: boolean; hasParking: boolean; acceptsCards: boolean; homeService: boolean; needsBooking: boolean; open24h: boolean; hasDelivery: boolean;
};

const value = (item: string | number | null | undefined) => item ?? '';

export default async function ProviderEditPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ error?: string; updated?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const { id } = await params; const query = await searchParams;
  const [provider, areasResult, categoriesResult] = await Promise.all([
    apiGet<Provider>(`/api/admin/providers/${id}`, { admin: true }),
    apiGet<Paginated<Area>>('/api/areas', { cache: 'no-store' }),
    apiGet<Paginated<Category>>('/api/categories', { cache: 'no-store' }),
  ]);
  const selectedCategories = provider.categories.map(({ category }) => category.id);
  const openingHoursText = typeof provider.openingHours === 'string' ? provider.openingHours : provider.openingHours ? JSON.stringify(provider.openingHours) : '';
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">الدليل / تعديل</span><h1 className="pageTitle">تعديل بيانات النشاط</h1></div><Link href="/admin/providers">العودة للأنشطة</Link></div>
    <p className="pageLead">تحكم كامل في الهوية، بيانات التواصل، الموقع، التوثيق، الفئات والصور. الحفظ ينعكس مباشرة على التطبيق.</p>
    {query.updated === '1' && <p className="successNotice">تم تحديث النشاط بنجاح.</p>}
    {query.error && <p className="formError">تعذر حفظ التعديل. راجع الحقول والصور ثم حاول مرة أخرى.</p>}
    <form action={updateProviderAdmin} className="surface formGrid publicForm">
      <input type="hidden" name="id" value={provider.id} />
      <label>اسم النشاط<input name="name" defaultValue={provider.name} required minLength={2} /></label>
      <label>المعرف الخارجي<input name="externalId" defaultValue={value(provider.externalId)} /></label>
      <label className="wideField">الوصف<textarea name="description" defaultValue={value(provider.description)} maxLength={1200} /></label>
      <label>الفئة (يمكن اختيار أكثر من فئة)<select name="categoryIds" multiple defaultValue={selectedCategories} style={{ minHeight: 100 }}>{categoriesResult.data.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</select></label>
      <label>المنطقة<select name="areaId" defaultValue={provider.area.id} required>{areasResult.data.map((area) => <option key={area.id} value={area.id}>{area.name}</option>)}</select></label>
      <label>حالة النشر<select name="status" defaultValue={provider.status}><option value="APPROVED">معتمد</option><option value="PENDING">قيد المراجعة</option><option value="REJECTED">مرفوض</option></select></label>
      <label>طريقة التقديم<select name="serviceMode" defaultValue={provider.serviceMode}><option value="LOCAL">محلي</option><option value="ONLINE">أونلاين</option></select></label>
      <label>الهاتف<input name="phone" defaultValue={value(provider.phone)} inputMode="tel" pattern="01[0125][0-9]{8}" /></label>
      <label>واتساب<input name="whatsapp" defaultValue={value(provider.whatsapp)} inputMode="tel" pattern="01[0125][0-9]{8}" /></label>
      <label>نوع الرقم<select name="phoneType" defaultValue={provider.phoneType}><option value="BUSINESS">رقم النشاط</option><option value="PERSONAL">رقم شخصي</option></select></label>
      <label>البريد الإلكتروني<input name="email" type="email" defaultValue={value(provider.email)} /></label>
      <label>الموقع الإلكتروني<input name="website" defaultValue={value(provider.website)} /></label>
      <label>فيسبوك<input name="facebookUrl" defaultValue={value(provider.facebookUrl)} /></label>
      <label>إنستجرام<input name="instagramUrl" defaultValue={value(provider.instagramUrl)} /></label>
      <label>تيك توك<input name="tiktokUrl" defaultValue={value(provider.tiktokUrl)} /></label>
      <label>منصة اجتماعية<select name="socialPlatform" defaultValue={value(provider.socialPlatform)}><option value="">—</option><option value="facebook">Facebook</option><option value="instagram">Instagram</option><option value="x">X</option><option value="tiktok">TikTok</option><option value="youtube">YouTube</option></select></label>
      <label>رابط اجتماعي<input name="socialUrl" defaultValue={value(provider.socialUrl)} /></label>
      <label className="wideField">العنوان<input name="address" defaultValue={value(provider.address)} /></label>
      <label>خط العرض<input name="latitude" type="number" step="any" defaultValue={value(provider.latitude)} /></label>
      <label>خط الطول<input name="longitude" type="number" step="any" defaultValue={value(provider.longitude)} /></label>
      <label>يفتح<input name="openingTime" type="time" defaultValue={value(provider.openingTime)} /></label>
      <label>يغلق<input name="closingTime" type="time" defaultValue={value(provider.closingTime)} /></label>
      <label className="wideField">مواعيد العمل التفصيلية (نص أو JSON)<textarea name="openingHours" defaultValue={openingHoursText} /></label>
      <div className="wideField checkboxGrid">{[['kidFriendly','مناسب للأطفال'],['accessible','مهيأ لذوي الإعاقة'],['hasParking','يوجد موقف سيارات'],['acceptsCards','يقبل البطاقات'],['homeService','خدمة منزلية'],['needsBooking','يحتاج حجزًا'],['open24h','يعمل 24 ساعة'],['hasDelivery','يوفر توصيلًا']].map(([key, label]) => <label key={key}><input type="checkbox" name={key} defaultChecked={Boolean(provider[key as keyof Provider])} />{label}</label>)}</div>
      <label style={{ display: 'flex', alignItems: 'center', gap: 8 }}><input type="checkbox" name="isVerified" defaultChecked={provider.isVerified} style={{ width: 16, height: 16 }} /> موثق</label>
      <ImageUploadField name="logo" uploadUrl="/api/admin/uploads/provider-images" max={1} label="الشعار / الصورة الرئيسية" initialImages={provider.logoUrl ? [{ url: provider.logoUrl, kind: 'logo' }] : []} />
      <ImageUploadField name="images" uploadUrl="/api/admin/uploads/provider-images" max={10} label="صور النشاط (حتى 10 صور)" initialImages={provider.images} />
      <button className="primaryButton wideField" type="submit">حفظ كل التعديلات</button>
    </form>
  </section>;
}
