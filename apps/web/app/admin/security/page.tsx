import { hasAdminSession } from '@/lib/admin-session';
import { redirect } from 'next/navigation';

export const dynamic = 'force-dynamic';
const rows = [['OWNER', 'كل الصلاحيات، الحذف النهائي، الفريق، النسخ الاحتياطي'], ['CONTENT_EDITOR', 'إضافة وتعديل المحتوى، الاستيراد، إعلانات الرئيسية'], ['MODERATOR', 'المراجعة والاعتماد والبلاغات'], ['REVIEWER', 'قراءة البيانات ومراجعة أولية']];
export default async function SecurityPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  return <section><div className="sectionHead"><div><span className="eyebrow">صلاحيات الوصول</span><h1 className="pageTitle">الأمان والأدوار</h1></div></div><p className="pageLead">مصفوفة واضحة للصلاحيات تساعدك على توزيع العمل بأمان. العمليات الحساسة مثل الحذف النهائي محمية لمدير النظام.</p><section className="section surface table"><table><thead><tr><th>الدور</th><th>الصلاحيات</th></tr></thead><tbody>{rows.map(([role, permissions]) => <tr key={role}><td><span className="badge">{role}</span></td><td>{permissions}</td></tr>)}</tbody></table></section></section>;
}
