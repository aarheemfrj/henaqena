import Link from 'next/link';
import { loginAdmin } from '../actions';

export default async function AdminLoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const query = await searchParams;
  return <section className="authPage"><div className="surface authCard"><span className="eyebrow">منصة هنا قنا</span><h1 className="pageTitle">دخول الإدارة</h1><p className="pageLead">استخدم حساب مدير الإدارة نفسه الموجود في التطبيق.</p><form action={loginAdmin}><label className="fieldLabel" htmlFor="email">البريد الإداري</label><input id="email" name="email" type="email" required autoFocus className="textInput" /><label className="fieldLabel" htmlFor="password">كلمة المرور</label><input id="password" name="password" type="password" required className="textInput" /><button className="primaryButton" type="submit">دخول آمن</button>{query.error && <p className="formError">بيانات الإدارة غير صحيحة.</p>}</form><Link className="quietLink" href="/">العودة للمنصة</Link></div></section>;
}
