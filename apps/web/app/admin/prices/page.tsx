import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { createPrice, moderatePrice } from '../actions';

export const dynamic = 'force-dynamic';
type Price = { id: string; name: string; category?: string | null; minPrice: string | number; maxPrice: string | number; unit?: string | null; status: string; outlier?: boolean; outlierRatio?: number | null; outlierReason?: string | null };

export default async function PricesAdminPage({ searchParams }: { searchParams?: Promise<{ outliersOnly?: string }> }) {
  if (!await hasAdminSession()) redirect('/admin/login');
  const filters = await searchParams;
  const outliersOnly = filters?.outliersOnly === 'true';
  const prices = await apiGet<Price[]>(`/api/admin/prices${outliersOnly ? '?outliersOnly=true' : ''}`, { admin: true }).catch(() => []);
  return <section><div className="sectionHead"><div><span className="eyebrow">دليل الأسعار</span><h1 className="pageTitle">إدارة «بكام؟»</h1></div><Link href="/admin">العودة للوحة</Link></div><p className="pageLead">أضف السعر المرجعي بعد المراجعة. التطبيق يعرض النطاق السعري بدل رقم مضلل.</p><form action={createPrice} className="surface formGrid"><label>اسم الخدمة أو المنتج<input name="name" required /></label><label>الفئة<input name="category" /></label><label>من<input name="minPrice" type="number" min="0.01" step="0.01" required /></label><label>إلى<input name="maxPrice" type="number" min="0.01" step="0.01" required /></label><label>الوحدة<input name="unit" placeholder="للوحدة" /></label><label>المصدر<input name="sourceNote" placeholder="رصد مجتمعي أو مصدر رسمي" /></label><button className="primaryButton" type="submit">نشر السعر</button></form><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><div><h2>الأسعار المسجلة</h2><span className="badge">{prices.length}</span></div><Link className="secondaryButton" href={outliersOnly ? '/admin/prices' : '/admin/prices?outliersOnly=true'}>{outliersOnly ? 'عرض كل الأسعار' : 'مراجعة الأسعار الشاذة'}</Link></div><table><thead><tr><th>العنصر</th><th>النطاق</th><th>الفئة</th><th>الحالة</th><th>إشارة المراجعة</th><th>إجراء</th></tr></thead><tbody>{prices.map((price) => <tr key={price.id}><td>{price.name}</td><td>{price.minPrice} — {price.maxPrice} {price.unit ?? 'جنيه'}</td><td>{price.category ?? '—'}</td><td><span className="badge">{price.status}</span></td><td>{price.outlier ? <span className="badge warningBadge" title={price.outlierReason ?? undefined}>شاذ ({price.outlierRatio}×)</span> : <span className="muted">طبيعي</span>}</td><td>{price.status === 'PENDING' && <div className="actionRow"><form action={moderatePrice}><input type="hidden" name="id" value={price.id} /><input type="hidden" name="status" value="APPROVED" /><button className="approveButton" type="submit">اعتماد</button></form><form action={moderatePrice}><input type="hidden" name="id" value={price.id} /><input type="hidden" name="status" value="REJECTED" /><button className="rejectButton" type="submit">رفض</button></form></div>}</td></tr>)}</tbody></table></section></section>;
}
