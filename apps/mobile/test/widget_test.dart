import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/main.dart';
import 'package:mobile/core/theme/app_theme.dart';

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

  testWidgets('all five primary tabs are available from the shared shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeController.theme(AppThemeController.current),
        home: const HomeShell(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['مين؟', 'بكام؟', 'دلوقتي', 'عندك؟', 'الرئيسية']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('directory search renders safely as a standalone route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeController.theme(AppThemeController.current),
        home: const DirectoryPage(initialQuery: 'صيدلية'),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ActionChip), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'theme chooser exposes all saved palettes and persists a choice',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeController.theme(AppThemeController.current),
          home: const SettingsPage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.scrollUntilVisible(
        find.text('الثيم والألوان'),
        260,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('الثيم والألوان'));
      await tester.pumpAndSettle();
      expect(find.text('اختاري شكل التطبيق'), findsOneWidget);
      expect(find.text('نسمة النيل'), findsOneWidget);
      expect(find.text('توت قنا'), findsOneWidget);

      await tester.tap(find.text('نسمة النيل'));
      await tester.pumpAndSettle();
      expect(AppThemeController.selectedId.value, 'nile');
    },
  );
}
