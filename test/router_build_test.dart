import 'package:flutter_test/flutter_test.dart';

import 'pump_liuban_router.dart';

void main() {
  testWidgets('buildRouter initial location shows feed app bar title', (
    tester,
  ) async {
    await pumpLiubanRouter(tester);
    expect(find.text('留伴 · 廣場'), findsOneWidget);
  });

  testWidgets('buildRouter unknown location shows user-facing message', (
    tester,
  ) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/not-registered-route-xyz');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('沒有符合此路徑'), findsOneWidget);
  });
}
