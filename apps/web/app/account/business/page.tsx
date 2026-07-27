import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';
import { addBusinessOffer, addBusinessService } from '../actions';

export const dynamic = 'force-dynamic';
type Business = { id: string; name: string; status: string; area?: { name: string }; services?: { id: string; name: string; status: string; price?: string | number | null }[]; offers?: { id: string; title: string; status: string; startsAt: string; endsAt: string }[] };

export default async function BusinessPage({ searchParams }: { searchParams: Promise<{ error?: string; updated?: string }> }) {
  if (!await getUserApiToken()) redirect('/account');
  const query = await searchParams;
  const contributions = await apiGet<{ providers: Business[] }>('/api/me/contributions', { user: true }).catch(() => ({ providers: [] }));
  return <section><div className="sectionHead"><div><span className="eyebrow">صاحب نشاط</span><h1 className="pageTitle">إدارة أنشطتي</h1></div><Link href="/account">العودة للحساب</Link></div><p className="pageLead">أضف خدمات وعروضًا لنشاطك. كل إضافة تمر بالمراجعة قبل ظهورها للمستخدمين.</p>{query.updated === '1' && <p style={{ color: 'var(--teal)' }}>تم الإرسال للمراجعة.</p>}{query.error && <p className="formError">تعذر إرسال البيانات، راجع الحقول.</p>}
    {contributions.providers.length === 0 ? <section className="surface empty"><p>لا توجد أنشطة مرتبطة بحسابك بعد.</p><Link className="primaryLink" href="/add-activity">إضافة نشاط</Link></section> : contributions.providers.map((provider) => <section className="section surface" key={provider.id}><div className="sectionHead"><div><h2>{provider.name}</h2><small>{provider.area?.name ?? 'قنا'} · {provider.status}</small></div></div><div className="authColumns"><form action={addBusinessService} className="authCard"><h3>إضافة خدمة</h3><input type="hidden" name="providerId" value={provider.id} /><label>اسم الخدمة<input name="name" required /></label><label>الوصف<textarea name="description" /></label><label>السعر<input name="price" type="number" min="0" step="0.01" /></label><label>ملاحظة السعر<input name="priceNote" /></label><button className="primaryButton" type="submit">إرسال للمراجعة</button></form><form action={addBusinessOffer} className="authCard"><h3>إضافة عرض</h3><input type="hidden" name="providerId" value={provider.id} /><label>عنوان العرض<input name="title" required /></label><label>الوصف<textarea name="description" /></label><label>يبدأ<input name="startsAt" type="datetime-local" required /></label><label>ينتهي<input name="endsAt" type="datetime-local" required /></label><button className="primaryButton" type="submit">إرسال للمراجعة</button></form></div><p><strong>الخدمات:</strong> {provider.services?.length ?? 0} · <strong>العروض:</strong> {provider.offers?.length ?? 0}</p></section>)}
  </section>;
}
