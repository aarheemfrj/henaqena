# نشر هنا قنا على VPS

## الهدف

- الدومين: `https://henaqena.maalsoft.com`
- مسار المشروع: `/home/henaqena/htdocs/henaqena`
- مستخدم SSH: `henaqena`
- Next.js: `127.0.0.1:3100`
- API: `127.0.0.1:4000`
- إدارة العمليات: PM2
- تشغيل Next.js: ملف `.next/standalone/server.js` الناتج من بناء الإنتاج، وليس `next start`. يشغله Node 22 مع ملف البيئة الخاص بالسيرفر مباشرة.

الـAPI لا يُفتح على منفذ عام. منصة Next.js تمرر `/api/*` و`/uploads/*` إلى المنفذ الداخلي 4000، لذلك يكفي توجيه الدومين إلى المنفذ 3100.

## قبل أول نشر

1. وجّه DNS للدومين إلى `69.62.116.193`.
2. اضبط Reverse Proxy في لوحة الاستضافة من الدومين إلى `http://127.0.0.1:3100` مع SSL.
3. ثبّت Node.js 22 أو أحدث وPM2 وعميل PostgreSQL الذي يوفر `pg_dump`.
4. أنشئ قاعدة PostgreSQL مستقلة ومستخدمًا مستقلًا للمشروع، ولا تستخدم قاعدة أي مشروع آخر.
5. اربط مستخدم السيرفر بالمستودع الخاص عبر SSH deploy key أو GitHub credential helper. لا تضع Git token داخل رابط المستودع أو داخل أي ملف.

## الاستنساخ الأول

```bash
cd /home/henaqena/htdocs
git clone git@github.com:aarheemfrj/henaqena.git henaqena
cd /home/henaqena/htdocs/henaqena
bash deploy.sh
```

في أول تشغيل فقط سيطلب السكربت، دون إظهار المدخلات:

- `DATABASE_URL` لقاعدة PostgreSQL المستقلة.
- اسم وبريد وكلمة مرور أول حساب `OWNER`، إذا لم يكن موجودًا بالفعل.

بقية مفاتيح الإدارة والجلسات تُنشأ عشوائيًا على السيرفر، وتُحفظ بصلاحية `600` خارج Git.

إذا كانت القاعدة جديدة تمامًا ولا يمكن أخذ نسخة منها بعد، استخدم لأول مرة فقط:

```bash
ALLOW_FIRST_DEPLOY_WITHOUT_BACKUP=1 bash deploy.sh
```

## نشر كل تحديث تالٍ

```bash
cd /home/henaqena/htdocs/henaqena
git pull --ff-only origin main
bash deploy.sh
```

السكربت يرفض العمل إذا كان الفرع غير `main` أو توجد تعديلات غير محفوظة على السيرفر. قبل تغيير قاعدة البيانات يأخذ نسخة `pg_dump` ونسخة من الصور، ويحتفظ بآخر 14 يومًا.

## الفحص

```bash
pm2 status
curl -fsS http://127.0.0.1:4000/ready
curl -fsS http://127.0.0.1:3100/
curl -fsS http://127.0.0.1:3100/api/health
curl -I https://henaqena.maalsoft.com
```

## السجلات

```bash
pm2 logs henaqena-api --lines 100
pm2 logs henaqena-web --lines 100
```

## تنبيه أمني

أي كلمات مرور أو مفاتيح ظهرت سابقًا داخل نسخة قديمة من `deploy.sh` يجب اعتبارها مكشوفة وتغييرها في PostgreSQL وملفات البيئة على السيرفر. النسخة الحالية من السكربت لا تحتوي أسرارًا ثابتة.
