import 'package:flutter_test/flutter_test.dart';

import 'liuban_test_harness.dart';

void main() {
  testWidgets('App boots and shows 廣場 tab', (tester) async {
    await pumpLiubanApp(tester);
    expect(find.textContaining('留伴'), findsWidgets);
    expect(find.text('廣場'), findsOneWidget);
  });
}
