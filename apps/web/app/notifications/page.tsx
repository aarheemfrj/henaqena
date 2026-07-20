import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { getUserApiToken } from '@/lib/user-session';
import { markNotificationRead, markAllNotificationsRead } from './actions';

type Notification = { id: string; title: string; body: string; readAt: string | null; createdAt: string };

export const dynamic = 'force-dynamic';

export default async function NotificationsPage() {
  if (!await getUserApiToken()) redirect('/account');
  const notifications = await apiGet<Notification[]>('/api/notifications', { user: true }).catch(() => []);
  const unreadCount = notifications.filter((item) => !item.readAt).length;
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">حسابي</span><h1 className="pageTitle">الإشعارات</h1></div>{unreadCount > 0 && <form action={markAllNotificationsRead}><button className="secondaryButton" type="submit">تحديد الكل كمقروء</button></form>}</div>
    <p className="pageLead">آخر التحديثات على مساهماتك وحسابك.</p>
    {notifications.length === 0 && <div className="surface empty">لا توجد إشعارات بعد.</div>}
    <div className="notificationList section">
      {notifications.map((item) => <article className={`surface notificationRow${item.readAt ? '' : ' unread'}`} key={item.id}>
        <div><strong>{item.title}</strong><p style={{ margin: '6px 0 0', color: 'var(--muted)', fontSize: 13 }}>{item.body}</p><small style={{ color: 'var(--teal)' }}>{new Date(item.createdAt).toLocaleString('ar-EG')}</small></div>
        {!item.readAt && <form action={markNotificationRead}><input type="hidden" name="id" value={item.id} /><button className="ghostButton" type="submit">تحديد كمقروء</button></form>}
      </article>)}
    </div>
    <Link className="quietLink" href="/account">العودة للحساب</Link>
  </section>;
}
