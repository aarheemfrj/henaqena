'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

type AdminNavItem = { href: string; label: string; icon: string; roles?: string[] };
type AdminNavGroup = { label: string; items: AdminNavItem[] };

const groups: AdminNavGroup[] = [
  {
    label: 'المتابعة',
    items: [
      { href: '/admin', label: 'ملخص اليوم', icon: '◉' },
      { href: '/admin/audit', label: 'سجل العمليات', icon: '≡' },
      { href: '/admin/analytics', label: 'التقارير والجودة', icon: '▥' },
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
      { href: '/admin/review-center', label: 'مركز الاعتماد', icon: '✓' },
      { href: '/admin/min-shater', label: 'مين شاطر؟', icon: '★' },
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
      { href: '/admin/archive', label: 'الأرشيف والاسترجاع', icon: '↺' },
      { href: '/admin/catalog', label: 'سجل البيانات', icon: '▤' },
      { href: '/admin/notifications', label: 'حملات الإشعارات', icon: '◌' },
    ],
  },
    {
      label: 'الإدارة',
      items: [
      { href: '/admin/maintenance', label: 'النسخ والصيانة', icon: '⟳', roles: ['OWNER'] },
      { href: '/admin/users', label: 'المستخدمون', icon: '◎', roles: ['OWNER', 'MODERATOR'] },
      { href: '/admin/team', label: 'فريق العمل', icon: '◉', roles: ['OWNER'] },
      { href: '/admin/security', label: 'الأمان والأدوار', icon: '⌑', roles: ['OWNER'] },
      { href: '/admin/settings', label: 'إعدادات التطبيق', icon: '⚙', roles: ['OWNER', 'CONTENT_EDITOR'] },
    ],
  },
];

export function AdminNav({ role = 'OWNER' }: { role?: string }) {
  const pathname = usePathname();
  return <aside className="adminSidebar" aria-label="مراكز الإدارة">
    <div className="adminSidebarHead"><span className="adminSidebarMark">⚙</span><div><strong>مركز التحكم</strong><small>هنا قنا</small></div></div>
    {groups.map((group) => <section className="adminNavGroup" key={group.label}>
      <small>{group.label}</small>
      {group.items.filter((item) => !item.roles || item.roles.includes(role) || role === 'OWNER').map((item) => {
        const active = pathname === item.href;
        return <Link key={item.href} href={item.href} className={active ? 'adminNavActive' : 'adminNavLink'}><span>{item.icon}</span>{item.label}</Link>;
      })}
    </section>)}
  </aside>;
}
