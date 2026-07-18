import 'package:flutter/material.dart';
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

  testWidgets('local listing form accepts title and price', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateListingPage()));
    await tester.pump(const Duration(milliseconds: 100));

    final title = find.widgetWithText(TextField, 'عنوان الإعلان');
    final price = find.widgetWithText(TextField, 'السعر *');
    expect(title, findsOneWidget);
    expect(price, findsOneWidget);
    await tester.enterText(title, 'منتج حقيقي للاختبار');
    await tester.enterText(price, '350');
    expect(find.text('منتج حقيقي للاختبار'), findsOneWidget);
    expect(find.text('350'), findsOneWidget);
  });

  testWidgets('activity form keeps all primary inputs editable', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AddActivityPage()));
    await tester.pump(const Duration(milliseconds: 100));

    final name = find.widgetWithText(TextFormField, 'اسم النشاط *');
    final phone = find.widgetWithText(TextFormField, 'رقم الهاتف *');
    final address = find.widgetWithText(TextFormField, 'العنوان بالتفصيل *');
    expect(name, findsOneWidget);
    expect(phone, findsOneWidget);
    expect(address, findsOneWidget);
    await tester.enterText(name, 'نشاط تجريبي');
    await tester.enterText(phone, '01012345678');
    await tester.enterText(address, 'وسط البلد');
    expect(find.text('نشاط تجريبي'), findsOneWidget);
    expect(find.text('01012345678'), findsOneWidget);
    expect(find.text('وسط البلد'), findsOneWidget);
  });
}
