import type { Area, Category } from '@/lib/api';

export function AreaPicker({ areas, name = 'area', required = false }: { areas: Area[]; name?: string; required?: boolean }) {
  return <label className="wideField pickerField">
    المنطقة
    <select name={`${name}Id`} defaultValue="" required={required && areas.length === 0}>
      <option value="">— اختر منطقة موجودة —</option>
      {areas.map((area) => <option value={area.id} key={area.id}>{area.name}</option>)}
    </select>
    <input name={`new${name.charAt(0).toUpperCase()}${name.slice(1)}Name`} placeholder="أو اكتب اسم منطقة جديدة لو المكان جديد" />
  </label>;
}

export function CategoryPicker({ categories, name = 'category', required = false }: { categories: Category[]; name?: string; required?: boolean }) {
  return <label className="wideField pickerField">
    نوع النشاط
    <select name={`${name}Id`} defaultValue="" required={required && categories.length === 0}>
      <option value="">— اختر فئة موجودة —</option>
      {categories.map((category) => <option value={category.id} key={category.id}>{category.name}</option>)}
    </select>
    <input name={`new${name.charAt(0).toUpperCase()}${name.slice(1)}Name`} placeholder="أو اكتب اسم فئة جديدة لو النشاط جديد" />
  </label>;
}
