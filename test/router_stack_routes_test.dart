import 'package:flutter_test/flutter_test.dart';
import 'pump_liuban_router.dart';

void main() {
  testWidgets('/forgot-password shows 忘記密碼', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/forgot-password');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('忘記密碼');
  });

  testWidgets('/register shows 註冊 · 身分審核', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/register');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('註冊 · 身分審核');
  });

  testWidgets('/support shows 官方客服', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/support');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('官方客服');
  });

  testWidgets('/reset-password shows 重設密碼', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/reset-password?token=t');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('重設密碼');
  });

  testWidgets('/login shows 登入', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/login');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('登入');
  });

  testWidgets('/post/:id shows 動態詳情', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/post/${Uri.encodeComponent('p1')}');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('動態詳情');
  });

  testWidgets('/promotion/:id shows 推廣詳情', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/promotion/1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('推廣詳情');
  });
}
