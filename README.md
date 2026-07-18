# هنا قنا — Hena Qena

منصة خدمات المجتمع المحلي في محافظة قنا، مصر.

A local community services platform for Qena Governorate, Egypt.

---

## 📋 المتطلبات

- **Node.js** 18+ (لمنصة الويب وAPI)
- **Flutter** 3.12+ (للتطبيق الجوال)
- **PostgreSQL** 15+ (قاعدة البيانات)
- **Docker** (اختياري - لتشغيل PostgreSQL)

---

## 🚀 البدء السريع

### 1️⃣ إعداد قاعدة البيانات

#### الخيار أ: استخدام Docker
```bash
cd infra
docker-compose up -d
```

#### الخيار ب: PostgreSQL محلي
```sql
CREATE DATABASE henaqena;
CREATE USER henaqena WITH PASSWORD 'henaqena';
GRANT ALL PRIVILEGES ON DATABASE henaqena TO henaqena;
```

### 2️⃣ إعداد API

```bash
cd apps/api

# تثبيت المكتبات
npm install

# إنشء ملف البيئة
cp .env.example .env
# عدّل .env وأضف ADMIN_API_KEY الآمن

# تطبيق الهجرات
npm run prisma:migrate

# ملء البيانات الأولية (العناصر التجريبية)
npm run db:seed

# تشغيل الخادم
npm run dev
```

الخادم يعمل على: `http://localhost:4000`

### 3️⃣ إعداد منصة الويب والإدارة (Next.js — قيد البناء)

المنصة الرسمية والإدارة يجب أن تُبنى بـ Next.js + TypeScript، لتوحيد تجربة الويب مع MaalSoft. مجلد `apps/admin` الحالي نموذج مؤقت فقط وسيتم استبداله تدريجياً.

ثم أضف مفتاح الإدارة:
- اضغط على الإعدادات (Settings)
- أدخل `ADMIN_API_KEY` من ملف `.env`

### 4️⃣ إعداد التطبيق الجوال

```bash
cd apps/mobile

# تثبيت المكتبات
flutter pub get

# تشغيل على محاكي أو جهاز فعلي
flutter run
```

---

## 📁 بنية المشروع

```
HenaQena/
├── apps/
│   ├── api/              # خادم النوى (Node.js + Express + Prisma)
│   ├── web/              # منصة الويب والإدارة (Next.js — قيد البناء)
│   ├── admin/            # نموذج إدارة مؤقت قديم
│   ├── web/              # منصة الويب ولوحة الإدارة (Next.js)
│   └── mobile/           # تطبيق الجوال (Flutter)
├── infra/                # ملفات البنية التحتية (Docker, etc.)
└── HENA_QENA_PROJECT_MEMORY.md  # توثيق المشروع والمعايير
```

---

## 🔐 متغيرات البيئة

### `apps/api/.env`

```env
# قاعدة البيانات
# Postgres.app على macOS (قاعدة مستقلة باسم henaqena)
DATABASE_URL="postgresql://YOUR_MAC_USER@127.0.0.1:5432/henaqena?schema=public"

# الخادم
PORT=4000

# الأمان (غيّر في الإنتاج!)
ADMIN_API_KEY="dev-henaqena-admin"

# البيئة
NODE_ENV=development
```

---

## 🧪 الاختبار

### API
```bash
cd apps/api
npm run build     # فحص TypeScript
```

### منصة الويب

```bash
cd apps/web
npm install
npm run dev
```

### التطبيق الجوال
```bash
cd apps/mobile
flutter analyze   # فحص Dart
flutter test      # اختبارات الوحدة
```

---

## 📊 الوثائق الإضافية

- [HENA_QENA_PROJECT_MEMORY.md](./HENA_QENA_PROJECT_MEMORY.md) — معايير المنتج والمعمارية
- [QA_CHECKLIST.md](./QA_CHECKLIST.md) — قائمة التحقق قبل الإطلاق
- [apps/api/prisma/schema.prisma](./apps/api/prisma/schema.prisma) — نموذج قاعدة البيانات
- [infra/README.md](./infra/README.md) — إعداد البنية التحتية

---

## 🛠️ الأوامر الشائعة

```bash
# API
cd apps/api
npm run dev              # تشغيل في وضع التطوير
npm run build            # بناء للإنتاج
npm run start            # تشغيل الإنتاج المُبني
npm run prisma:migrate  # تطبيق هجرات قاعدة البيانات
npm run db:seed         # ملء البيانات الأولية

# الجوال
cd apps/mobile
flutter pub get          # تثبيت المكتبات
flutter run              # تشغيل التطبيق
flutter analyze          # فحص الكود
flutter test             # تشغيل الاختبارات
```

---

## 🚨 الأمان

قبل الإطلاق العام:

- ✅ استخدم متغير `ADMIN_API_KEY` الآمن (غيّر عن القيمة الافتراضية)
- ✅ استخدم HTTPS في الإنتاج
- ✅ صدّق مفتاح قاعدة البيانات وكلمات المرور
- ✅ راجع سياسات الخصوصية وشروط الاستخدام
- ✅ فعّل تسجيل الأحداث والمراقبة

---

## 📱 الـ API Endpoints الرئيسية

### المصادقة
- `POST /api/auth/register` — تسجيل حساب جديد
- `POST /api/auth/login` — تسجيل الدخول
- `POST /api/auth/verification/request` — طلب كود التحقق
- `POST /api/auth/verification/confirm` — تأكيد الكود

### المحتوى العام
- `GET /api/providers` — قائمة مقدمي الخدمات
- `GET /api/categories` — الفئات المتاحة
- `GET /api/areas` — المناطق الجغرافية
- `GET /api/listings` — الإعلانات المصنفة
- `GET /api/reviews` — المراجعات المعتمدة

### المراجعات والإجراءات
- `POST /api/reviews` — إضافة مراجعة جديدة (يتطلب مصادقة)
- `POST /api/reviews/:id/replies` — الرد على مراجعة (يتطلب مصادقة)
- `POST /api/providers` — إضافة مقدم خدمة (يتطلب مصادقة)

### الإدارة (تتطلب `x-admin-key`)
- `GET /api/admin/overview` — ملخص الإحصائيات
- `GET /api/admin/reviews` — قائمة المراجعات المعلقة
- `GET /api/admin/listings` — قائمة الإعلانات المعلقة
- `PATCH /api/admin/reviews/:id` — اعتماد/رفض مراجعة
- `PATCH /api/admin/listings/:id` — اعتماد/رفض إعلان

---

## 🤝 المساهمة

انظر إلى [HENA_QENA_PROJECT_MEMORY.md](./HENA_QENA_PROJECT_MEMORY.md) لمعايير المشروع والاتفاقيات.

---

## 📞 الدعم

للأسئلة والتقارير، تواصل مع فريق هنا قنا.

---

**آخر تحديث:** يوليو 2026
