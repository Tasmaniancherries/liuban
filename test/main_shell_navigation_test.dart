import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_liuban_router.dart';

Future<void> tapBottomNav(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('MainShell bottom nav: feed → 推廣', (tester) async {
    await pumpLiubanRouter(tester);
    expect(find.text('留伴 · 廣場'), findsOneWidget);
    await tapBottomNav(tester, '推廣');
    expectLiubanAppBarTitle('推廣');
  });

  testWidgets('MainShell bottom nav: feed → 訊息', (tester) async {
    await pumpLiubanRouter(tester);
    await tapBottomNav(tester, '訊息');
    expectLiubanAppBarTitle('訊息');
  });

  testWidgets('MainShell bottom nav: feed → 我的', (tester) async {
    await pumpLiubanRouter(tester);
    await tapBottomNav(tester, '我的');
    expectLiubanAppBarTitle('我的');
  });

  testWidgets('MainShell bottom nav: 推廣 → 廣場', (tester) async {
    await pumpLiubanRouter(tester);
    await tapBottomNav(tester, '推廣');
    expectLiubanAppBarTitle('推廣');
    await tapBottomNav(tester, '廣場');
    expect(find.text('留伴 · 廣場'), findsOneWidget);
  });

  testWidgets('buildRouter /settings shows 設定 app bar', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/settings');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expectLiubanAppBarTitle('設定');
  });
}
