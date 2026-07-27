import { redirect } from 'next/navigation';
import { apiGet } from '@/lib/api';
import { hasAdminSession } from '@/lib/admin-session';
import { updatePlatformSettings } from '../actions';

export const dynamic = 'force-dynamic';
type Settings = {
  adRotationSeconds: number; dataRefreshSeconds: number; maintenanceMode: boolean; maintenanceMessage: string;
  appName: string; appTagline: string; supportPhone?: string | null; supportWhatsapp?: string | null; supportEmail?: string | null;
  facebookUrl?: string | null; instagramUrl?: string | null; homeSections: string[]; enabledModules: Record<string, boolean>;
  privacyPolicy: string; termsOfUse: string; priceDefaultValidityDays: number; priceOutlierRatio: number;
};

const sections = [['providers', 'مين؟ — دليل الأنشطة'], ['prices', 'بكام؟ — الأسعار'], ['now', 'دلوقتي — التحديثات'], ['listings', 'عندك؟ — الإعلانات'], ['minShater', 'مين شاطر؟'], ['ads', 'إعلانات الرئيسية']];
const modules = [['providers', 'دليل الأنشطة'], ['prices', 'الأسعار'], ['now', 'دلوقتي'], ['listings', 'الإعلانات المحلية'], ['minShater', 'مين شاطر؟'], ['notifications', 'الإشعارات']];

export default async function SettingsPage() {
  if (!await hasAdminSession()) redirect('/admin/login');
  const settings = await apiGet<Settings>('/api/settings', { cache: 'no-store' });
  return <section>
    <div className="sectionHead"><div><span className="eyebrow">تحكم التطبيق</span><h1 className="pageTitle">إعدادات المنصة</h1></div></div>
    <p className="pageLead">كل تغيير هنا ينعكس على التطبيق بعد التحديث التالي، ويُسجل في سجل العمليات.</p>
    <form action={updatePlatformSettings} className="surface formGrid publicForm">
      <h2 className="wideField">الوضع والهوية</h2>
      <label className="wideField"><input type="checkbox" name="maintenanceMode" defaultChecked={settings.maintenanceMode} /> تفعيل وضع الصيانة ومنع استخدام التطبيق</label>
      <label className="wideField">رسالة الصيانة<textarea name="maintenanceMessage" defaultValue={settings.maintenanceMessage} maxLength={500} /></label>
      <label>اسم التطبيق<input name="appName" defaultValue={settings.appName} required /></label>
      <label>الشعار النصي<input name="appTagline" defaultValue={settings.appTagline} /></label>
      <label>هاتف الدعم<input name="supportPhone" defaultValue={settings.supportPhone ?? ''} /></label>
      <label>واتساب الدعم<input name="supportWhatsapp" defaultValue={settings.supportWhatsapp ?? ''} /></label>
      <label>بريد الدعم<input name="supportEmail" type="email" defaultValue={settings.supportEmail ?? ''} /></label>
      <label>فيسبوك<input name="facebookUrl" type="url" defaultValue={settings.facebookUrl ?? ''} /></label>
      <label>إنستجرام<input name="instagramUrl" type="url" defaultValue={settings.instagramUrl ?? ''} /></label>
      <h2 className="wideField">التوقيتات</h2>
      <label>تبديل الإعلانات (ثانية)<input name="adRotationSeconds" type="number" min="2" max="60" defaultValue={settings.adRotationSeconds} required /></label>
      <label>تحديث البيانات (ثانية)<input name="dataRefreshSeconds" type="number" min="60" max="3600" defaultValue={settings.dataRefreshSeconds} required /></label>
      <label>صلاحية السعر الافتراضية (يوم)<input name="priceDefaultValidityDays" type="number" min="1" max="365" defaultValue={settings.priceDefaultValidityDays} required /></label>
      <label>معامل تنبيه السعر الشاذ<input name="priceOutlierRatio" type="number" min="1.1" max="20" step="0.1" defaultValue={settings.priceOutlierRatio} required /></label>
      <h2 className="wideField">أقسام الصفحة الرئيسية وترتيبها</h2>
      <div className="wideField checkboxGrid">{sections.map(([key, label]) => <label key={key}><input type="checkbox" name="homeSections" value={key} defaultChecked={settings.homeSections.includes(key)} />{label}</label>)}</div>
      <h2 className="wideField">تشغيل الوحدات</h2>
      <div className="wideField checkboxGrid">{modules.map(([key, label]) => <label key={key}><input type="checkbox" name="enabledModules" value={key} defaultChecked={settings.enabledModules[key] !== false} />{label}</label>)}</div>
      <h2 className="wideField">النصوص القانونية</h2>
      <label className="wideField">سياسة الخصوصية<textarea name="privacyPolicy" defaultValue={settings.privacyPolicy} maxLength={20000} rows={10} /></label>
      <label className="wideField">شروط الاستخدام<textarea name="termsOfUse" defaultValue={settings.termsOfUse} maxLength={20000} rows={10} /></label>
      <button className="primaryButton wideField" type="submit">حفظ إعدادات المنصة</button>
    </form>
  </section>;
}
