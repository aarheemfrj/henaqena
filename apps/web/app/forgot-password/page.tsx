import Link from 'next/link';
import { requestPasswordReset, confirmPasswordReset } from './actions';

export default async function ForgotPasswordPage({ searchParams }: { searchParams: Promise<{ step?: string; identifier?: string; channel?: string; error?: string }> }) {
  const query = await searchParams;
  if (query.step === 'confirm') {
    const channelLabel = query.channel === 'email' ? 'البريد' : query.channel === 'whatsapp' ? 'واتساب' : 'رسالة نصية';
    return <section className="authPage"><form action={confirmPasswordReset} className="surface authCard">
      <h2>أدخل رمز التأكيد</h2>
      <p className="pageLead">لو الرقم أو البريد مسجل عندنا، هيوصلك رمز مكوّن من 6 أرقام عبر {channelLabel}.</p>
      {query.error === '1' && <p className="formError">رمز غير صحيح أو منتهي.</p>}
      <input type="hidden" name="identifier" value={query.identifier ?? ''} />
      <input type="hidden" name="channel" value={query.channel ?? 'sms'} />
      <label className="fieldLabel" htmlFor="code">رمز التأكيد</label>
      <input className="textInput" id="code" name="code" required pattern="\d{6}" maxLength={6} inputMode="numeric" />
      <label className="fieldLabel" htmlFor="newPassword">كلمة المرور الجديدة</label>
      <input className="textInput" id="newPassword" name="newPassword" type="password" minLength={8} required />
      <button className="primaryButton" type="submit">تغيير كلمة المرور</button>
      <Link className="quietLink" href="/account">العودة لتسجيل الدخول</Link>
    </form></section>;
  }
  return <section className="authPage"><form action={requestPasswordReset} className="surface authCard">
    <h2>نسيت كلمة المرور؟</h2>
    <p className="pageLead">أدخل رقم هاتفك أو بريدك المسجل وسنرسل رمز تأكيد لتغيير كلمة المرور.</p>
    <label className="fieldLabel" htmlFor="identifier">البريد أو رقم الهاتف</label>
    <input className="textInput" id="identifier" name="identifier" required />
    <label className="fieldLabel" htmlFor="channel">طريقة الإرسال</label>
    <select className="textInput" name="channel" id="channel" defaultValue="sms"><option value="sms">رسالة نصية</option><option value="whatsapp">واتساب</option><option value="email">بريد إلكتروني</option></select>
    <button className="primaryButton" type="submit">إرسال رمز التأكيد</button>
    <Link className="quietLink" href="/account">العودة لتسجيل الدخول</Link>
  </form></section>;
}
