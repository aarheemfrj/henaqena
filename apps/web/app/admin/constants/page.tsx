'use client';

import { useState, useEffect } from 'react';

type ConstantType = 'categories' | 'areas' | 'service-types' | 'listing-types' | 'news-types';

interface Constant {
  id: string;
  name: string;
  createdAt?: string;
}

function ConstantSection({
  title,
  description,
  type,
  icon,
}: {
  title: string;
  description: string;
  type: ConstantType;
  icon: string;
}) {
  const [constants, setConstants] = useState<Constant[]>([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formValue, setFormValue] = useState('');
  const [error, setError] = useState('');

  const labels: Record<ConstantType, { singular: string; plural: string }> = {
    'categories': { singular: 'فئة', plural: 'فئات' },
    'areas': { singular: 'منطقة', plural: 'مناطق' },
    'service-types': { singular: 'نوع خدمة', plural: 'أنواع خدمات' },
    'listing-types': { singular: 'نوع إعلان', plural: 'أنواع إعلانات' },
    'news-types': { singular: 'نوع خبر', plural: 'أنواع أخبار' },
  };

  const fetchConstants = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/constants/${type}`);
      if (!res.ok) throw new Error('Failed to fetch');
      const data = await res.json();
      setConstants(data.data || []);
      setError('');
    } catch (e) {
      setError((e instanceof Error ? e.message : 'خطأ في التحميل'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect -- initial load-on-mount fetch, not cascading render
    fetchConstants();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [type]);

  const handleSave = async () => {
    if (!formValue.trim()) {
      setError('الحقل مطلوب');
      return;
    }

    try {
      const url = `/api/admin/constants/${type}${editingId ? `/${editingId}` : ''}`;
      const method = editingId ? 'PUT' : 'POST';
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: formValue.trim() }),
      });
      if (!res.ok) throw new Error('Failed to save');
      await fetchConstants();
      setShowModal(false);
      setFormValue('');
      setEditingId(null);
      setError('');
    } catch (e) {
      setError((e instanceof Error ? e.message : 'خطأ في الحفظ'));
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm(`هل تريد حذف هذا ${labels[type].singular}؟`)) return;
    try {
      const res = await fetch(`/api/admin/constants/${type}/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Failed to delete');
      await fetchConstants();
      setError('');
    } catch (e) {
      setError((e instanceof Error ? e.message : 'خطأ في الحذف'));
    }
  };

  const handleEdit = (constant: Constant) => {
    setEditingId(constant.id);
    setFormValue(constant.name);
    setShowModal(true);
  };

  return (
    <div className="border rounded-lg p-6 space-y-4">
      <div className="flex items-center gap-3">
        <span className="text-2xl">{icon}</span>
        <div>
          <h2 className="text-xl font-semibold">{title}</h2>
          <p className="text-sm text-muted-foreground">{description}</p>
        </div>
      </div>

      <div className="space-y-3 max-h-64 overflow-y-auto">
        {loading ? (
          <p className="text-sm text-muted-foreground">جاري التحميل...</p>
        ) : constants.length === 0 ? (
          <p className="text-sm text-muted-foreground">لا توجد عناصر</p>
        ) : (
          constants.map((c) => (
            <div
              key={c.id}
              className="flex items-center justify-between gap-2 p-2 bg-secondary rounded"
            >
              <span className="text-sm">{c.name}</span>
              <div className="flex gap-1">
                <button
                  onClick={() => handleEdit(c)}
                  className="px-2 py-1 text-xs bg-blue-500 text-white rounded hover:bg-blue-600"
                >
                  تعديل
                </button>
                <button
                  onClick={() => handleDelete(c.id)}
                  className="px-2 py-1 text-xs bg-red-500 text-white rounded hover:bg-red-600"
                >
                  حذف
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      <button
        onClick={() => {
          setShowModal(true);
          setEditingId(null);
          setFormValue('');
        }}
        className="w-full px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90"
      >
        إضافة {labels[type].singular}
      </button>

      {error && <p className="text-sm text-red-500">{error}</p>}

      {showModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center">
          <div className="bg-white rounded-lg p-6 w-96 space-y-4">
            <h3 className="font-semibold text-lg">
              {editingId ? 'تعديل' : 'إضافة'} {labels[type].singular}
            </h3>
            <input
              type="text"
              value={formValue}
              onChange={(e) => setFormValue(e.target.value)}
              placeholder={`أدخل ${labels[type].singular}`}
              className="w-full px-3 py-2 border rounded-lg"
            />
            <div className="flex gap-2 justify-end">
              <button
                onClick={() => setShowModal(false)}
                className="px-4 py-2 border rounded-lg hover:bg-secondary"
              >
                إلغاء
              </button>
              <button
                onClick={handleSave}
                className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90"
              >
                حفظ
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default function ConstantsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold">الثوابت</h1>
        <p className="text-muted-foreground mt-2">إدارة ثوابت المنصة والمعلومات الثابتة</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <ConstantSection
          title="الفئات (Categories)"
          description="إدارة أنواع الخدمات والأنشطة"
          type="categories"
          icon="📂"
        />
        <ConstantSection
          title="المناطق (Areas)"
          description="إدارة مناطق التغطية"
          type="areas"
          icon="📍"
        />
        <ConstantSection
          title="أنواع الخدمات"
          description="تصنيفات الخدمات المتاحة"
          type="service-types"
          icon="🔧"
        />
        <ConstantSection
          title="أنواع الإعلانات"
          description="تصنيفات الإعلانات المتاحة"
          type="listing-types"
          icon="📰"
        />
        <ConstantSection
          title="أنواع الأخبار"
          description="تصنيفات الأخبار والتحديثات"
          type="news-types"
          icon="📢"
        />
      </div>
    </div>
  );
}
