import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('welcome screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const HenaQenaApp());

    expect(find.text('هنا قنا'), findsOneWidget);
    expect(find.text('أهلًا بيك.. قنا كلها هنا'), findsOneWidget);
    expect(find.text('التكملة كزائر'), findsOneWidget);
  });
}
