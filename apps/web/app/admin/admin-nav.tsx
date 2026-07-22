'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

const groups = [
  {
    label: 'المتابعة',
    items: [
      { href: '/admin', label: 'ملخص اليوم', icon: '◉' },
      { href: '/admin/audit', label: 'سجل العمليات', icon: '≡' },
    ],
  },
  {
    label: 'المراجعة',
    items: [
      { href: '/admin/providers', label: 'الأنشطة', icon: '⌂' },
      { href: '/admin/listings', label: 'الإعلانات المحلية', icon: '◇' },
      { href: '/admin/reviews', label: 'التقييمات', icon: '☆' },
      { href: '/admin/reports', label: 'البلاغات والدعم', icon: '!' },
      { href: '/admin/services', label: 'الخدمات والعروض', icon: '◈' },
    ],
  },
  {
    label: 'محتوى التطبيق',
    items: [
      { href: '/admin/ads', label: 'إعلانات الرئيسية', icon: '▣' },
      { href: '/admin/prices', label: 'بكام؟', icon: '◇' },
      { href: '/admin/now', label: 'دلوقتي', icon: 'ϟ' },
      { href: '/admin/import', label: 'استيراد البيانات', icon: '⇩' },
      { href: '/admin/data-collection', label: 'تجميع البيانات', icon: '⌘' },
    ],
  },
    {
      label: 'الإدارة',
      items: [
      { href: '/admin/maintenance', label: 'النسخ والصيانة', icon: '⟳' },
      { href: '/admin/users', label: 'المستخدمون', icon: '◎' },
      { href: '/admin/team', label: 'فريق العمل', icon: '◉' },
    ],
  },
];

export function AdminNav() {
  const pathname = usePathname();
  return <aside className="adminSidebar" aria-label="مراكز الإدارة">
    <div className="adminSidebarHead"><span className="adminSidebarMark">⚙</span><div><strong>مركز التحكم</strong><small>هنا قنا</small></div></div>
    {groups.map((group) => <section className="adminNavGroup" key={group.label}>
      <small>{group.label}</small>
      {group.items.map((item) => {
        const active = pathname === item.href;
        return <Link key={item.href} href={item.href} className={active ? 'adminNavActive' : 'adminNavLink'}><span>{item.icon}</span>{item.label}</Link>;
      })}
    </section>)}
  </aside>;
}
