import 'package:flutter/material.dart';
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

  testWidgets('settings -> support navigates to 官方客服', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/settings');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final supportTileFinder = find.widgetWithText(ListTile, '意見與客服');
    final supportTile = tester.widget<ListTile>(supportTileFinder);
    expect(supportTile.onTap, isNotNull);
    supportTile.onTap!.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expectLiubanAppBarTitle('官方客服');
  });
}
