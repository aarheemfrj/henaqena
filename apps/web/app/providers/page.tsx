import { apiGet, type Provider } from '@/lib/api';
import { ProviderCard } from '../page';

export const dynamic = 'force-dynamic';

export default async function ProvidersPage() {
  const providers = await apiGet<Provider[]>('/api/providers').catch(() => []);
  return <section><span className="eyebrow">دليل قنا</span><h1 className="pageTitle">مين؟</h1><p className="pageLead">أماكن وخدمات مضافة ومراجعة من الإدارة، بنفس البيانات التي تظهر في تطبيق هنا قنا.</p><div className="section"><div className="providerGrid">{providers.map((provider) => <ProviderCard provider={provider} key={provider.id} />)}{providers.length === 0 && <div className="surface empty">لا توجد بيانات متاحة حالياً.</div>}</div></div></section>;
}
