/* eslint-disable @next/next/no-img-element -- provider photos are served from our own uploads host, not next/image's optimizer */
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';
import { toggleProviderFavorite, submitProviderReview } from './actions';

type Author = { id: string; name: string; avatarUrl?: string | null };
type Reply = { id: string; text: string; author: Author };
type ReviewItem = { id: string; quality: number; commitment: number; value: number; comment?: string | null; author: Author; replies: Reply[]; createdAt: string };
type Service = { id: string; name: string; description?: string | null; price?: number | null; priceNote?: string | null };
type Offer = { id: string; title: string; description?: string | null; endsAt: string };
type ProviderDetail = {
  id: string; name: string; description?: string | null; phone?: string | null; whatsapp?: string | null; address?: string | null;
  openingTime?: string | null; closingTime?: string | null; isVerified: boolean; serviceMode: 'LOCAL' | 'ONLINE';
  area: { name: string }; images: { url: string }[]; categories: { category: { name: string } }[];
  services: Service[]; offers: Offer[]; reviews: ReviewItem[]; _count: { favorites: number };
  viewer: { favorite: boolean };
};

export const dynamic = 'force-dynamic';

const stars = (value: number) => '★★★★★☆☆☆☆☆'.slice(5 - value, 10 - value);

export default async function ProviderDetailPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ error?: string; reviewed?: string }> }) {
  const { id } = await params;
  const query = await searchParams;
  const provider = await apiGet<ProviderDetail>(`/api/providers/${id}`, { optionalUser: true, cache: 'no-store' }).catch(() => null);
  if (!provider) return notFound();
  const signedIn = Boolean(await getUserApiToken());
  const averageRating = provider.reviews.length === 0 ? 0 : provider.reviews.reduce((sum, review) => sum + (review.quality + review.commitment + review.value) / 3, 0) / provider.reviews.length;

  return <section>
    <div className="detailHead">
      <div><span className="eyebrow">{provider.categories[0]?.category.name ?? 'خدمة محلية'}</span><h1 className="pageTitle">{provider.name}{provider.isVerified && <span className="badge" style={{ marginRight: 10 }}>موثق</span>}</h1></div>
      <Link href="/providers">للدليل كامل ←</Link>
    </div>
    <p className="detailMeta"><span>{provider.area.name}</span><span>·</span><span>{provider.serviceMode === 'ONLINE' ? 'أونلاين' : 'محلي'}</span>{provider.reviews.length > 0 && <><span>·</span><span>{stars(Math.round(averageRating))} ({provider.reviews.length} تقييم)</span></>}</p>
    <p className="pageLead">{provider.description || 'خدمة قريبة منك داخل قنا.'}</p>

    {provider.images.length > 0 && <div className="section gallery">{provider.images.map((image) => <img src={image.url} alt={provider.name} key={image.url} />)}</div>}

    <div className="detailActions">
      {provider.phone && <a className="callButton" href={`tel:${provider.phone}`}>📞 اتصال</a>}
      {provider.whatsapp && <a className="callButton" href={`https://wa.me/2${provider.whatsapp}`} target="_blank" rel="noreferrer">واتساب</a>}
      {signedIn ? <form action={toggleProviderFavorite}><input type="hidden" name="providerId" value={provider.id} /><button className="ghostButton" type="submit">{provider.viewer.favorite ? '★ في المفضلة' : '☆ أضف للمفضلة'}</button></form> : <Link className="ghostButton" href="/account">سجّل الدخول للمفضلة</Link>}
    </div>
    {query.error === 'login' && <p className="formError">سجّل الدخول أولاً لإتمام هذا الإجراء.</p>}

    <section className="section surface accountSummary">
      {provider.address && <p><strong>العنوان:</strong> {provider.address}</p>}
      {(provider.openingTime || provider.closingTime) && <p><strong>مواعيد العمل:</strong> {provider.openingTime ?? '—'} — {provider.closingTime ?? '—'}</p>}
    </section>

    {provider.services.length > 0 && <section className="section"><div className="sectionHead"><h2>الخدمات</h2></div><div className="section contentGrid">{provider.services.map((service) => <article className="surface contentCard" key={service.id}><div><h3>{service.name}</h3><p>{service.description}</p>{service.price != null && <strong>{service.price.toLocaleString('ar-EG')} جنيه {service.priceNote}</strong>}</div></article>)}</div></section>}

    {provider.offers.length > 0 && <section className="section"><div className="sectionHead"><h2>عروض سارية</h2></div><div className="section contentGrid">{provider.offers.map((offer) => <article className="surface contentCard" key={offer.id}><div><h3>{offer.title}</h3><p>{offer.description}</p><small>ينتهي {new Date(offer.endsAt).toLocaleDateString('ar-EG')}</small></div></article>)}</div></section>}

    <section className="section">
      <div className="sectionHead"><h2>التقييمات ({provider.reviews.length})</h2></div>
      {provider.reviews.length === 0 && <div className="surface empty">لا توجد تقييمات بعد. كن أول من يقيّم.</div>}
      <div className="timeline">
        {provider.reviews.map((review) => <article className="surface reviewCard" key={review.id}>
          <div className="providerTitle"><strong>{review.author.name}</strong><span className="reviewStars">{stars(Math.round((review.quality + review.commitment + review.value) / 3))}</span></div>
          {review.comment && <p>{review.comment}</p>}
          {review.replies.map((reply) => <p key={reply.id} style={{ marginRight: 16, color: 'var(--muted)' }}><strong>{reply.author.name}: </strong>{reply.text}</p>)}
        </article>)}
      </div>
      {signedIn ? <form action={submitProviderReview} className="surface formGrid publicForm">
        <input type="hidden" name="providerId" value={provider.id} />
        <label>الجودة<select name="quality" required defaultValue="5">{[5, 4, 3, 2, 1].map((n) => <option value={n} key={n}>{n}</option>)}</select></label>
        <label>الالتزام<select name="commitment" required defaultValue="5">{[5, 4, 3, 2, 1].map((n) => <option value={n} key={n}>{n}</option>)}</select></label>
        <label>القيمة مقابل السعر<select name="value" required defaultValue="5">{[5, 4, 3, 2, 1].map((n) => <option value={n} key={n}>{n}</option>)}</select></label>
        <label className="wideField">تعليقك (اختياري)<textarea name="comment" maxLength={1000} /></label>
        <button className="primaryButton wideField" type="submit">إرسال التقييم</button>
        {query.error === 'review' && <p className="formError wideField">تعذر إرسال التقييم، ربما قيّمت هذا المكان من قبل.</p>}
        {query.reviewed === '1' && <p className="wideField" style={{ color: 'var(--teal)', fontSize: 13 }}>شكرًا! تقييمك سيظهر بعد المراجعة.</p>}
      </form> : <p className="pageLead"><Link href="/account">سجّل الدخول</Link> لتضيف تقييمك.</p>}
    </section>
  </section>;
}
