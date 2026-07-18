import Link from 'next/link';
import { loginAdmin } from '../actions';

export default async function AdminLoginPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const query = await searchParams;
  return <section className="authPage"><div className="surface authCard"><span className="eyebrow">منصة هنا قنا</span><h1 className="pageTitle">دخول الإدارة</h1><p className="pageLead">للمراجعة والنشر وإدارة البيانات المشتركة مع التطبيق.</p><form action={loginAdmin}><label className="fieldLabel" htmlFor="password">كلمة مرور الإدارة</label><input id="password" name="password" type="password" required autoFocus className="textInput" /><button className="primaryButton" type="submit">دخول آمن</button>{query.error && <p className="formError">كلمة المرور غير صحيحة.</p>}</form><Link className="quietLink" href="/">العودة للمنصة</Link></div></section>;
}
