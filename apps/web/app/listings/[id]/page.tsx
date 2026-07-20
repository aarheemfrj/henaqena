/* eslint-disable @next/next/no-img-element -- listing photos are served from our own uploads host, not next/image's optimizer */
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';
import { toggleListingFavorite, toggleListingInterest, reportListing } from './actions';

type ListingDetail = {
  id: string; title: string; description?: string | null; category: string; price: number;
  area?: { name: string } | null; images: { url: string }[]; owner?: { name?: string | null; phone?: string | null } | null;
  _count: { favorites: number; interests: number }; viewer: { favorite: boolean; interested: boolean };
};

export const dynamic = 'force-dynamic';

export default async function ListingDetailPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ error?: string; reported?: string }> }) {
  const { id } = await params;
  const query = await searchParams;
  const listing = await apiGet<ListingDetail>(`/api/listings/${id}`, { optionalUser: true, cache: 'no-store' }).catch(() => null);
  if (!listing) return notFound();
  const signedIn = Boolean(await getUserApiToken());

  return <section>
    <div className="detailHead">
      <div><span className="eyebrow">{listing.category}</span><h1 className="pageTitle">{listing.title}</h1></div>
      <Link href="/listings">لكل الإعلانات ←</Link>
    </div>
    <p className="detailMeta"><span>{listing.area?.name ?? 'قنا'}</span><span>·</span><span>{listing.owner?.name ?? 'قناوي'}</span></p>
    <strong style={{ display: 'block', margin: '10px 0', color: 'var(--deep)', fontSize: 26 }}>{listing.price.toLocaleString('ar-EG')} جنيه</strong>
    <p className="pageLead">{listing.description || 'بدون وصف إضافي'}</p>

    {listing.images.length > 0 && <div className="section gallery">{listing.images.map((image) => <img src={image.url} alt={listing.title} key={image.url} />)}</div>}

    <div className="detailActions">
      {listing.owner?.phone && <a className="callButton" href={`tel:${listing.owner.phone}`}>📞 اتصال بصاحب الإعلان</a>}
      {signedIn ? <>
        <form action={toggleListingFavorite}><input type="hidden" name="listingId" value={listing.id} /><button className="ghostButton" type="submit">{listing.viewer.favorite ? '★ في المفضلة' : '☆ أضف للمفضلة'}</button></form>
        <form action={toggleListingInterest}><input type="hidden" name="listingId" value={listing.id} /><button className="ghostButton" type="submit">{listing.viewer.interested ? '✓ أنا مهتم' : 'أنا مهتم'}</button></form>
      </> : <Link className="ghostButton" href="/account">سجّل الدخول للتفاعل</Link>}
    </div>
    {query.error === 'login' && <p className="formError">سجّل الدخول أولاً لإتمام هذا الإجراء.</p>}

    {signedIn && <section className="section surface accountSummary">
      <h2 style={{ marginTop: 0 }}>الإبلاغ عن الإعلان</h2>
      <form action={reportListing} className="publicForm">
        <input type="hidden" name="listingId" value={listing.id} />
        <label className="fieldLabel" htmlFor="reason">السبب</label>
        <textarea className="textInput" id="reason" name="reason" required minLength={3} maxLength={300} style={{ height: 'auto', padding: 10 }} />
        <button className="secondaryButton" type="submit" style={{ marginTop: 10 }}>إرسال بلاغ</button>
        {query.error === 'report' && <p className="formError">تعذر إرسال البلاغ.</p>}
        {query.reported === '1' && <p style={{ color: 'var(--teal)', fontSize: 13, marginTop: 8 }}>تم إرسال البلاغ للمراجعة.</p>}
      </form>
    </section>}
  </section>;
}
