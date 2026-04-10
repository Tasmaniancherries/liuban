import 'package:flutter_test/flutter_test.dart';

import 'pump_liuban_router.dart';

void main() {
  testWidgets('settings -> forgot password navigates to 忘記密碼', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('忘記密碼'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expectLiubanAppBarTitle('忘記密碼');
  });
}
