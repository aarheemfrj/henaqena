# متطلبات خارجية قبل التفعيل الإنتاجي

هذه المتطلبات مسجلة للمالك، ولن نضع أي مفاتيح سرية داخل المستودع:

## الحسابات وتأكيد الهوية

- مزود WhatsApp لإرسال OTP.
- مزود SMS مصري كبديل.
- مزود بريد SMTP أو خدمة بريدية.
- اختيار سياسة القنوات: WhatsApp أساسي، SMS احتياطي، والبريد اختياري.

## تسجيل الدخول الاجتماعي

- المعرّف الموحد المحجوز في المشروع: `com.maalsoft.henaqena` لـ iOS وAndroid.
- Google Cloud: أنشئ OAuth Client لكل من iOS وAndroid وWeb، وضع Client IDs العامة في `GOOGLE_CLIENT_IDS` على الـ API.
- شغّل التطبيق مع `--dart-define=GOOGLE_CLIENT_ID=... --dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
- iOS: استخدم Client ID الخاص بـ iOS كـ `GOOGLE_CLIENT_ID`، وClient ID الخاص بـ Web كـ `GOOGLE_SERVER_CLIENT_ID`.
- Android: استخدم Client ID الخاص بـ Android كـ `GOOGLE_CLIENT_ID`، وClient ID الخاص بـ Web كـ `GOOGLE_SERVER_CLIENT_ID`.
- قيمة `GOOGLE_CLIENT_IDS` في الخادم تقبل قائمة مفصولة بفواصل وتشمل معرّفات Web وiOS وAndroid حتى يقبل الخادم أي منصة موثوقة.
- Apple Developer: فعّل Sign in with Apple للـ App ID، وأنشئ Service ID وKey وReturn URL على دومين HTTPS.
- ضع App ID وService ID المسموحين في `APPLE_CLIENT_IDS` على الـ API، وشغّل التطبيق مع `APPLE_SERVICE_ID` و`APPLE_REDIRECT_URI`.
- التطبيق يرسل Identity Token للخادم؛ الخادم يتحقق من التوقيع والمصدر و`audience` من مفاتيح Google/Apple العامة قبل إنشاء جلسة هنا قنا.
- Android/ويب يستخدمان تدفق المتصفح الآمن عند الحاجة، وiOS يستخدم شاشة النظام. لا تُقبل نتيجة الرجوع للتطبيق قبل تحقق الخادم.

## الإشعارات

- مشروع Firebase.
- Firebase Cloud Messaging لـ Android.
- APNs Key أو Certificate لـ iOS.
- أسماء الحزم وبيئات development/production.

## الخرائط

- تم اعتماد وتجهيز Google Maps، ويظل المفتاح فقط خارج Git.
- أنشئ مفتاح iOS مقيدًا بالـ Bundle ID `com.maalsoft.henaqena` ومفعلاً له Maps SDK for iOS فقط.
- أنشئ مفتاح Android منفصلاً مقيدًا باسم الحزمة وبصمات SHA-1/SHA-256 ومفعلاً له Maps SDK for Android فقط.
- ضع مفتاح Android في `~/.gradle/gradle.properties` باسم `GOOGLE_MAPS_API_KEY`، ومفتاح iOS في إعداد Build Setting بنفس الاسم.
- فعّل واجهة الخريطة داخل التطبيق وقت توافر المفتاح باستخدام `--dart-define=GOOGLE_MAPS_ENABLED=true`؛ من دون المفتاح يظل دليل المواقع وفتح الخرائط الخارجية شغالين.

## الإنتاج والتخزين

- دومين API العام.
- دومين المنصة `henaqena.malsoft.com`.
- VPS وشهادة HTTPS.
- Object Storage متوافق S3 للصور.
- بيانات النسخ الاحتياطي اليومية.

## طريقة التسليم

تُسلَّم القيم عبر ملف بيئة إنتاج خارج Git أو مدير أسرار. لا يتم إرسال المفاتيح داخل المحادثة أو وضعها في ملفات المشروع.
