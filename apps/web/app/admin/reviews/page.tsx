import Link from 'next/link'; import { redirect } from 'next/navigation'; import { apiGet } from '@/lib/api'; import { hasAdminSession } from '@/lib/admin-session'; import { moderateReview, deleteReview } from '../actions';
export const dynamic = 'force-dynamic'; type Review = { id: string; comment?: string | null; quality: number; commitment: number; value: number; status: string; author?: { name: string }; provider?: { name: string } };
export default async function ReviewsAdminPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const items = await apiGet<Review[]>('/api/admin/reviews', { admin: true }).catch(() => []);
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">المجتمع</span><h1 className="pageTitle">التقييمات</h1></div><Link href="/admin">العودة للوحة</Link></div>
    <p className="pageLead">التقييمات تُنشر فورًا للجمهور بدون مراجعة مسبقة. تقدر تحذف أي تقييم مخالف من هنا، مع إمكانية إبلاغ صاحبه بالسبب (اختياري).</p>
    <section className="section surface table"><table><thead><tr><th>التقييم</th><th>المكان</th><th>صاحب التقييم</th><th>الدرجات</th><th>الحالة</th><th>إجراء</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}>
      <td>{item.comment ?? 'بدون تعليق'}</td>
      <td>{item.provider?.name ?? '—'}</td>
      <td>{item.author?.name ?? '—'}</td>
      <td>{item.quality} / {item.commitment} / {item.value}</td>
      <td><span className="badge">{item.status}</span></td>
      <td>
        <div className="actionRow" style={{ flexWrap: 'wrap', alignItems: 'start' }}>
          {item.status === 'PENDING' && <>
            <form action={moderateReview}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="APPROVED"/><button className="approveButton" type="submit">اعتماد</button></form>
            <form action={moderateReview}><input type="hidden" name="id" value={item.id}/><input type="hidden" name="status" value="REJECTED"/><button className="rejectButton" type="submit">رفض</button></form>
          </>}
          <form action={deleteReview} style={{ display: 'flex', flexWrap: 'wrap', gap: 6, alignItems: 'center' }}>
            <input type="hidden" name="id" value={item.id}/>
            <input name="reason" placeholder="سبب الحذف (اختياري)" style={{ height: 32, padding: '0 8px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 12, minWidth: 140 }}/>
            <label style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, color: 'var(--muted)' }}><input type="checkbox" name="notify" value="true" style={{ width: 14, height: 14 }}/> إبلاغ صاحبه</label>
            <button className="rejectButton" type="submit">حذف</button>
          </form>
        </div>
      </td>
    </tr>)}</tbody></table></section>
  </section>;
}
