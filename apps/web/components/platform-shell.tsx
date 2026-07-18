'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import type { ReactNode } from 'react';

const navigation = [
  { href: '/', label: 'الرئيسية', icon: '⌂' },
  { href: '/providers', label: 'مين؟', icon: '⌕' },
  { href: '/prices', label: 'بكام؟', icon: '◈' },
  { href: '/now', label: 'دلوقتي', icon: 'ϟ' },
  { href: '/listings', label: 'عندك؟', icon: '◇' },
];

export function PlatformShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  return <div className="shell" dir="rtl">
    <header className="topbar">
      <Link href="/" className="brand"><span className="brandMark">⌖</span><span><strong>هنا قنا</strong><small>كل ما تحتاجه.. قريب منك</small></span></Link>
      <nav className="desktopNav" aria-label="الأقسام الرئيسية">{navigation.map((item) => <Link key={item.href} href={item.href} className={pathname === item.href ? 'navActive' : 'navLink'}>{item.label}</Link>)}</nav>
      <div className="topActions"><button className="iconButton" aria-label="بحث">⌕</button><button className="iconButton" aria-label="الإشعارات">♧</button><Link className="accountButton" href="/account">حسابي</Link></div>
    </header>
    <main className="pageTransition">{children}</main>
    <footer className="siteFooter"><Link href="/privacy">الخصوصية</Link><Link href="/terms">شروط الاستخدام</Link><Link href="/delete-account">حذف الحساب</Link></footer>
    <Link className="quickAdd" href="/add-activity" aria-label="إضافة نشاط"><b>+</b><span>أضف نشاط</span></Link>
    <nav className="mobileNav" aria-label="الأقسام الرئيسية">{navigation.map((item) => <Link key={item.href} href={item.href} className={pathname === item.href ? 'mobileActive' : 'mobileLink'}><span>{item.icon}</span><small>{item.label}</small></Link>)}</nav>
  </div>;
}
