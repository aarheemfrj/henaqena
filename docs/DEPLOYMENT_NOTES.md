# Hena Qena — بيانات النشر المعتمدة

> هذا الملف لا يحتوي كلمات مرور أو مفاتيح خاصة. احفظ الأسرار في مدير كلمات مرور أو في ملفات البيئة على السيرفر فقط.

## الموقع

- النطاق: `henaqena.maalsoft.com`
- عنوان الخادم: `69.62.116.193`
- نوع المنصة: CloudPanel / Node.js
- Node.js: `22 LTS`
- منفذ التطبيق: `3100`
- مجلد الموقع: `/home/maalsoft-henaqena/htdocs/henaqenawebapp`
- المستخدم الخاص بالموقع: `maalsoft-henaqena`
- مستخدم SSH الإداري: `henaqena`

## المشروع وGitHub

- المستودع: `git@github.com:aarheemfrj/henaqena.git`
- الفرع الإنتاجي: `main`
- مفتاح GitHub: Deploy Key باسم `henaqena-vps`، صلاحية قراءة فقط
- ملف إعداد SSH على السيرفر: `/root/.ssh/config`
- مفتاح السيرفر الخاص: `/root/.ssh/henaqena_github` — لا يُنسخ أو يُرفع إلى Git

## الخدمات

- Next.js: `127.0.0.1:3100`
- API الداخلي: `127.0.0.1:4000`
- إدارة العمليات: PM2
- أسماء عمليات المشروع: `henaqena-api` و`henaqena-web`
- Reverse proxy: الدومين يوجّه إلى `127.0.0.1:3100`

## قاعدة البيانات

- PostgreSQL مستقل باسم قاعدة المشروع `henaqena`
- العنوان المحلي على السيرفر: `localhost`
- المنفذ: `5432`
- اسم المستخدم: `henaqena`
- رابط الاتصال محفوظ فقط في `apps/api/.env` على السيرفر، ولا يُحفظ هنا أو في Git.

## النشر

```bash
cd /home/maalsoft-henaqena/htdocs/henaqenawebapp
git pull --ff-only origin main
bash deploy.sh
```

في أول تشغيل فقط ينشئ السكربت ملفات البيئة ويطلب رابط قاعدة البيانات وحساب OWNER عند الحاجة. بعد ذلك يحافظ على ملفات البيئة ولا يطلب الرابط مجددًا.

## ملاحظات أمنية

- لا تضع كلمات مرور SSH أو PostgreSQL أو مفاتيح الإدارة في هذا الملف أو داخل Git.
- بعد استقرار الإطلاق الرسمي، غيّر كلمة مرور SSH وكلمة مرور PostgreSQL ومفاتيح الإدارة القديمة.
- النسخ الاحتياطية والصور محفوظة خارج Git داخل `backups/` و`storage/`.
