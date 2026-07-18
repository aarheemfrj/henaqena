# تشغيل هنا قنا عبر Docker

1. انسخ `.env.example` إلى `.env` داخل مجلد `infra` وضع قيمًا قوية.
2. شغّل `docker compose up -d --build`.
3. المنصة تعمل على `3100`، والـ API على `4000`، وقاعدة البيانات داخل شبكة Docker.
4. افحص الجاهزية من `/ready`.

في الإنتاج يجب وضع Reverse Proxy وHTTPS أمام المنفذين، وعدم نشر PostgreSQL للعامة. التخزين الحالي للصور Volume دائم؛ يُستبدل بـ Object Storage قبل التوسع.

ملفات التشغيل الإضافية:

- `Caddyfile`: HTTPS وReverse Proxy للدومين والمنصة وAPI.
- `backup.sh`: نسخة PostgreSQL يومية مع الاحتفاظ بآخر 14 يومًا.
- Compose يحتوي Health Checks متسلسلة حتى لا تبدأ المنصة قبل جاهزية قاعدة البيانات وAPI.
