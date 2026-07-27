import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import type { Area, Paginated } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { cancelNotificationCampaign, createNotificationCampaign } from '../actions';

export const dynamic = 'force-dynamic';
type Campaign = { id: string; title: string; body: string; status: string; targetRole?: string | null; targetArea?: { name: string } | null; scheduledAt?: string | null; sentAt?: string | null };

export default async function NotificationsAdminPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const [campaigns, areas] = await Promise.all([
    apiGet<Campaign[]>('/api/admin/notification-campaigns', { admin: true }).catch(() => []),
    apiGet<Paginated<Area>>('/api/areas', { cache: 'no-store' }).catch(() => ({ data: [] as Area[], total: 0, limit: 0, offset: 0 })),
  ]);
  return <section><div className="sectionHead"><div><span className="eyebrow">تواصل مباشر</span><h1 className="pageTitle">حملات الإشعارات</h1></div></div><p className="pageLead">أرسل إشعارًا فورًا أو جدوله للمستخدمين حسب المنطقة أو الدور. الإرسال الحالي يظهر داخل مركز إشعارات التطبيق.</p>
    <form action={createNotificationCampaign} className="surface formGrid"><label>العنوان<input name="title" required maxLength={160} /></label><label>الفئة المستهدفة<select name="targetRole" defaultValue=""><option value="">كل المستخدمين</option><option value="PROVIDER">مقدمو الخدمات</option><option value="USER">المستخدمون</option></select></label><label>المنطقة<select name="targetAreaId" defaultValue=""><option value="">كل قنا</option>{areas.data.map((area) => <option key={area.id} value={area.id}>{area.name}</option>)}</select></label><label>موعد الإرسال<input name="scheduledAt" type="datetime-local" /></label><label className="wideField">نص الإشعار<textarea name="body" required maxLength={1000} rows={4} /></label><button className="primaryButton" type="submit">إنشاء وإرسال الحملة</button></form>
    <section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>الحملات السابقة</h2><span className="badge">{campaigns.length}</span></div><table><thead><tr><th>الحملة</th><th>الاستهداف</th><th>التوقيت</th><th>الحالة</th><th>إجراء</th></tr></thead><tbody>{campaigns.map((campaign) => <tr key={campaign.id}><td><strong>{campaign.title}</strong><br /><small>{campaign.body}</small></td><td>{campaign.targetArea?.name ?? 'كل قنا'}{campaign.targetRole ? ` · ${campaign.targetRole}` : ''}</td><td>{campaign.sentAt ? `أُرسلت ${new Date(campaign.sentAt).toLocaleString('ar-EG')}` : campaign.scheduledAt ? new Date(campaign.scheduledAt).toLocaleString('ar-EG') : 'فوري'}</td><td><span className="badge">{campaign.status}</span></td><td>{campaign.status === 'PENDING' && <form action={cancelNotificationCampaign}><input type="hidden" name="id" value={campaign.id} /><button className="rejectButton" type="submit">إلغاء</button></form>}</td></tr>)}</tbody></table></section>
  </section>;
}
