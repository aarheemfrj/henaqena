# متطلبات خارجية قبل التفعيل الإنتاجي

هذه المتطلبات مسجلة للمالك، ولن نضع أي مفاتيح سرية داخل المستودع:

## الحسابات وتأكيد الهوية

- مزود WhatsApp لإرسال OTP.
- مزود SMS مصري كبديل.
- مزود بريد SMTP أو خدمة بريدية.
- اختيار سياسة القنوات: WhatsApp أساسي، SMS احتياطي، والبريد اختياري.

## تسجيل الدخول الاجتماعي

- Google Cloud OAuth Client لتطبيق Android.
- Apple Developer Team ID وService ID وKey لتسجيل الدخول على iOS.
- Bundle ID وPackage Name النهائيان قبل TestFlight وGoogle Play.

## الإشعارات

- مشروع Firebase.
- Firebase Cloud Messaging لـ Android.
- APNs Key أو Certificate لـ iOS.
- أسماء الحزم وبيئات development/production.

## الخرائط

- اختيار مزود الخرائط النهائي (Google Maps أو Mapbox أو بديل).
- مفاتيح iOS وAndroid وقيود النطاق/الحزمة.

## الإنتاج والتخزين

- دومين API العام.
- دومين المنصة `henaqena.malsoft.com`.
- VPS وشهادة HTTPS.
- Object Storage متوافق S3 للصور.
- بيانات النسخ الاحتياطي اليومية.

## طريقة التسليم

تُسلَّم القيم عبر ملف بيئة إنتاج خارج Git أو مدير أسرار. لا يتم إرسال المفاتيح داخل المحادثة أو وضعها في ملفات المشروع.
