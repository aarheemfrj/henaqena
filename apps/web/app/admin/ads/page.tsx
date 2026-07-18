import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { createAd, moderateAd } from '../actions';

export const dynamic = 'force-dynamic';

type Ad = { id: string; name: string; imageUrl: string; description?: string | null; targetUrl?: string | null; weight: number; status: string; startsAt: string; endsAt: string };

export default async function AdsAdminPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const ads = await apiGet<Ad[]>('/api/admin/ads', { admin: true }).catch(() => []);
  return <section><div className="sectionHead"><div><span className="eyebrow">إعلانات الرئيسية</span><h1 className="pageTitle">إدارة الحملات</h1></div><Link href="/admin">العودة للوحة</Link></div><p className="pageLead">أضف الإعلان وحدد مدة ظهوره ووزنه النسبي. لا يظهر للمستخدمين إلا بعد الاعتماد.</p><form action={createAd} className="surface formGrid"><label>اسم الإعلان<input name="name" required /></label><label>رابط الصورة<input name="imageUrl" type="url" required /></label><label>الوصف<input name="description" /></label><label>رابط الفتح<input name="targetUrl" type="url" /></label><label>الوزن %<input name="weight" type="number" min="1" max="100" defaultValue="100" required /></label><label>يبدأ<input name="startsAt" type="datetime-local" required /></label><label>ينتهي<input name="endsAt" type="datetime-local" required /></label><button className="primaryButton" type="submit">إضافة للمراجعة</button></form><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>الإعلانات الحالية</h2><span className="badge">{ads.length}</span></div><table><thead><tr><th>الإعلان</th><th>الوزن</th><th>المدة</th><th>الحالة</th><th>قرار</th></tr></thead><tbody>{ads.map((ad) => <tr key={ad.id}><td>{ad.name}</td><td>{ad.weight}%</td><td>{new Date(ad.startsAt).toLocaleDateString('ar-EG')} — {new Date(ad.endsAt).toLocaleDateString('ar-EG')}</td><td><span className="badge">{ad.status}</span></td><td>{ad.status === 'PENDING' && <div className="actionRow"><form action={moderateAd}><input type="hidden" name="id" value={ad.id} /><input type="hidden" name="status" value="APPROVED" /><button className="approveButton" type="submit">اعتماد</button></form><form action={moderateAd}><input type="hidden" name="id" value={ad.id} /><input type="hidden" name="status" value="REJECTED" /><button className="rejectButton" type="submit">رفض</button></form></div>}</td></tr>)}</tbody></table></section></section>;
}
