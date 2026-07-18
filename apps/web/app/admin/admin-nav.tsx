import Link from 'next/link';

export function AdminNav() {
  return <nav className="adminNav"><span>المراكز:</span><Link href="/admin">الرئيسية</Link><Link href="/admin/team">الفريق</Link><Link href="/admin/providers">مين؟</Link><Link href="/admin/listings">عندك؟</Link><Link href="/admin/reviews">التقييمات</Link><Link href="/admin/reports">البلاغات</Link><Link href="/admin/ads">إعلانات الرئيسية</Link><Link href="/admin/prices">بكام؟</Link><Link href="/admin/now">دلوقتي</Link></nav>;
}
