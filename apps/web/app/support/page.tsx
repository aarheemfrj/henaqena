import Link from 'next/link';
import { redirect } from 'next/navigation';
import { getUserApiToken } from '@/lib/user-session';
import { submitSupportTicket } from './actions';

export default async function SupportPage({ searchParams }: { searchParams: Promise<{ error?: string; sent?: string }> }) {
  if (!await getUserApiToken()) redirect('/account');
  const query = await searchParams;
  if (query.sent) return <section className="authPage"><div className="surface successCard"><span className="successIcon">✓</span><h1 className="pageTitle">وصلتنا رسالتك</h1><p className="pageLead">فريق الدعم هيراجعها ويرد عليك في أقرب وقت.</p><Link className="primaryLink" href="/account">العودة للحساب</Link></div></section>;
  return <section>
    <span className="eyebrow">الدعم الفني</span><h1 className="pageTitle">تواصل معنا</h1><p className="pageLead">عندك استفسار أو مشكلة؟ ابعتلنا وهنرد عليك.</p>
    {query.error === '1' && <p className="formError">تعذر الإرسال، حاول مرة أخرى.</p>}
    <form action={submitSupportTicket} className="surface formGrid publicForm">
      <label className="wideField">الموضوع<input name="subject" required minLength={3} maxLength={120} /></label>
      <label className="wideField">تفاصيل الرسالة<textarea name="message" required minLength={5} maxLength={2000} /></label>
      <button className="primaryButton wideField" type="submit">إرسال</button>
    </form>
  </section>;
}
