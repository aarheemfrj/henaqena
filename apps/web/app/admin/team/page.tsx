import Link from 'next/link';
import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { createTeamMember, updateTeamMember } from '../actions';

export const dynamic = 'force-dynamic';
type Member = { id: string; name: string; email: string; role: string; isActive: boolean; lastLoginAt?: string | null };
const roleLabels: Record<string, string> = { OWNER: 'مدير كامل', REVIEWER: 'مراجع بيانات', CONTENT_EDITOR: 'محرر محتوى', MODERATOR: 'مراقب مجتمع' };

export default async function TeamAdminPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const members = await apiGet<Member[]>('/api/admin/team', { admin: true }).catch(() => []);
  return <section><div className="sectionHead"><div><span className="eyebrow">فريق الإدارة</span><h1 className="pageTitle">الحسابات والأدوار</h1></div><Link href="/admin">العودة للوحة</Link></div><p className="pageLead">أضف أعضاء الفريق بصلاحيات واضحة. الحساب الرئيسي الحالي يظل بوابة الإعداد الأولى حتى تفعيل تسجيل الدخول الفردي.</p><form action={createTeamMember} className="surface formGrid"><label>الاسم<input name="name" required /></label><label>البريد<input name="email" type="email" required /></label><label>كلمة مرور مؤقتة<input name="password" type="password" minLength={10} required /></label><label>الدور<select name="role" defaultValue="REVIEWER"><option value="OWNER">مدير كامل</option><option value="REVIEWER">مراجع بيانات</option><option value="CONTENT_EDITOR">محرر محتوى</option><option value="MODERATOR">مراقب مجتمع</option></select></label><button className="primaryButton" type="submit">إضافة عضو</button></form><section className="section surface table"><div className="sectionHead" style={{ padding: '18px 18px 0' }}><h2>أعضاء الفريق</h2><span className="badge">{members.length}</span></div><table><thead><tr><th>الاسم</th><th>البريد</th><th>الدور</th><th>الحالة</th><th>تغيير</th></tr></thead><tbody>{members.map((member) => <tr key={member.id}><td>{member.name}</td><td>{member.email}</td><td>{roleLabels[member.role] ?? member.role}</td><td><span className="badge">{member.isActive ? 'نشط' : 'موقوف'}</span></td><td><form action={updateTeamMember} className="actionRow"><input type="hidden" name="id" value={member.id} /><select name="role" defaultValue={member.role}><option value="OWNER">مدير كامل</option><option value="REVIEWER">مراجع بيانات</option><option value="CONTENT_EDITOR">محرر محتوى</option><option value="MODERATOR">مراقب مجتمع</option></select><input type="hidden" name="isActive" value={member.isActive ? 'false' : 'true'} /><button className="secondaryButton" type="submit">{member.isActive ? 'إيقاف' : 'تفعيل'}</button></form></td></tr>)}</tbody></table></section></section>;
}
