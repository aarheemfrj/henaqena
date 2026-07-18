import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const HenaQenaApp());

    expect(find.text('هنا قنا'), findsOneWidget);
    expect(find.text('أهلًا بيك.. قنا كلها هنا'), findsOneWidget);
    expect(find.text('التكملة كزائر'), findsOneWidget);
  });

  testWidgets('login action opens an editable login form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HenaQenaApp());

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pumpAndSettle();

    expect(find.text('رقم الموبايل أو البريد الإلكتروني *'), findsOneWidget);
    expect(find.text('كلمة المرور *'), findsOneWidget);
    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
  });

  testWidgets('start action opens the region setup step', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HenaQenaApp());

    await tester.tap(find.text('ابدأ الآن'));
    await tester.pumpAndSettle();

    expect(find.text('اختار منطقتك'), findsOneWidget);
    expect(find.text('قنا كلها'), findsOneWidget);
    expect(find.text('استخدم موقعي الحالي'), findsOneWidget);
  });
}
