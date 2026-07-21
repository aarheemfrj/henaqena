export type DataCollectionOption = { value: string; label: string };

// Starter category list for the job launcher. Extend by appending entries —
// values are free-text strings stored as-is on CollectedBusiness.category.
export const dataCollectionCategories: DataCollectionOption[] = [
  { value: 'مطاعم', label: 'مطاعم' },
  { value: 'كافيهات', label: 'كافيهات' },
  { value: 'صيدليات', label: 'صيدليات' },
  { value: 'مستشفيات', label: 'مستشفيات' },
  { value: 'عيادات', label: 'عيادات' },
  { value: 'أطباء', label: 'أطباء' },
  { value: 'معامل تحاليل', label: 'معامل تحاليل' },
  { value: 'مراكز أشعة', label: 'مراكز أشعة' },
  { value: 'استوديوهات تصوير', label: 'استوديوهات تصوير' },
  { value: 'قاعات أفراح', label: 'قاعات أفراح' },
  { value: 'فنادق', label: 'فنادق' },
  { value: 'شقق فندقية', label: 'شقق فندقية' },
  { value: 'سوبر ماركت', label: 'سوبر ماركت' },
  { value: 'مخابز', label: 'مخابز' },
  { value: 'حلواني', label: 'حلواني' },
  { value: 'محلات ملابس', label: 'محلات ملابس' },
  { value: 'محلات أحذية', label: 'محلات أحذية' },
  { value: 'محلات موبايلات', label: 'محلات موبايلات' },
  { value: 'صيانة موبايلات', label: 'صيانة موبايلات' },
  { value: 'أجهزة كهربائية', label: 'أجهزة كهربائية' },
  { value: 'أثاث', label: 'أثاث' },
  { value: 'أدوات منزلية', label: 'أدوات منزلية' },
  { value: 'شركات مقاولات', label: 'شركات مقاولات' },
  { value: 'تشطيبات وديكور', label: 'تشطيبات وديكور' },
  { value: 'مكاتب عقارات', label: 'مكاتب عقارات' },
  { value: 'مكاتب محاماة', label: 'مكاتب محاماة' },
  { value: 'محاسبون', label: 'محاسبون' },
  { value: 'مراكز تعليمية', label: 'مراكز تعليمية' },
  { value: 'حضانات', label: 'حضانات' },
  { value: 'مدارس خاصة', label: 'مدارس خاصة' },
  { value: 'جيمات', label: 'جيمات' },
  { value: 'صالونات تجميل', label: 'صالونات تجميل' },
  { value: 'حلاقين', label: 'حلاقين' },
  { value: 'مغاسل سيارات', label: 'مغاسل سيارات' },
  { value: 'صيانة سيارات', label: 'صيانة سيارات' },
  { value: 'قطع غيار سيارات', label: 'قطع غيار سيارات' },
  { value: 'خدمات نقل', label: 'خدمات نقل' },
  { value: 'خدمات منزلية', label: 'خدمات منزلية' },
  { value: 'أخرى', label: 'أخرى' },
];

// Qena governorate centers (مراكز محافظة قنا). "OTHER" is a sentinel the UI
// uses to reveal a free-text field for a village/area not in this list.
export const dataCollectionAreas: DataCollectionOption[] = [
  { value: 'مدينة قنا', label: 'مدينة قنا' },
  { value: 'قنا الجديدة', label: 'قنا الجديدة' },
  { value: 'أبو تشت', label: 'أبو تشت' },
  { value: 'فرشوط', label: 'فرشوط' },
  { value: 'نجع حمادي', label: 'نجع حمادي' },
  { value: 'دشنا', label: 'دشنا' },
  { value: 'الوقف', label: 'الوقف' },
  { value: 'قفط', label: 'قفط' },
  { value: 'قوص', label: 'قوص' },
  { value: 'نقادة', label: 'نقادة' },
];

export const OTHER_AREA_VALUE = '__other__';

export const dataCollectionAreaOptions: DataCollectionOption[] = [
  ...dataCollectionAreas,
  { value: OTHER_AREA_VALUE, label: 'منطقة أو قرية أخرى' },
];
