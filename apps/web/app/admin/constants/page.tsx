'use client';

export default function ConstantsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">الثوابت</h1>
        <p className="text-muted-foreground mt-2">إدارة ثوابت المنصة والمعلومات الثابتة</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Categories */}
        <div className="border rounded-lg p-6 space-y-4">
          <h2 className="text-xl font-semibold">الفئات (Categories)</h2>
          <p className="text-sm text-muted-foreground">إدارة أنواع الخدمات والأنشطة</p>
          <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
            عرض / تعديل
          </button>
          {/* TODO: Fetch from /api/admin/constants/categories */}
        </div>

        {/* Areas */}
        <div className="border rounded-lg p-6 space-y-4">
          <h2 className="text-xl font-semibold">المناطق (Areas)</h2>
          <p className="text-sm text-muted-foreground">إدارة مناطق التغطية</p>
          <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
            عرض / تعديل
          </button>
          {/* TODO: Fetch from /api/admin/constants/areas */}
        </div>

        {/* Service Types */}
        <div className="border rounded-lg p-6 space-y-4">
          <h2 className="text-xl font-semibold">أنواع الخدمات</h2>
          <p className="text-sm text-muted-foreground">تصنيفات الخدمات المتاحة</p>
          <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
            عرض / تعديل
          </button>
          {/* TODO: Fetch from /api/admin/constants/service-types */}
        </div>

        {/* Listing Types */}
        <div className="border rounded-lg p-6 space-y-4">
          <h2 className="text-xl font-semibold">أنواع الإعلانات</h2>
          <p className="text-sm text-muted-foreground">تصنيفات الإعلانات المتاحة</p>
          <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
            عرض / تعديل
          </button>
          {/* TODO: Fetch from /api/admin/constants/listing-types */}
        </div>

        {/* News Types */}
        <div className="border rounded-lg p-6 space-y-4">
          <h2 className="text-xl font-semibold">أنواع الأخبار</h2>
          <p className="text-sm text-muted-foreground">تصنيفات الأخبار والتحديثات</p>
          <button className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90">
            عرض / تعديل
          </button>
          {/* TODO: Fetch from /api/admin/constants/news-types */}
        </div>
      </div>

      <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 text-sm text-amber-900">
        <p className="font-semibold">ملاحظة تطوير:</p>
        <ul className="list-disc list-inside mt-2 space-y-1">
          <li>تحتاج endpoints API في /api/admin/constants/* لكل نوع</li>
          <li>كل endpoint يجب أن يرجع CRUD operations (Get, Create, Update, Delete)</li>
          <li>Validation وأذونات admin مطلوبة</li>
          <li>Integration مع database schema (Categories, Areas, Listings.category, etc.)</li>
        </ul>
      </div>
    </div>
  );
}
