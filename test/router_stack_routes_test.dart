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

  testWidgets('/settings/blocked-users enters auth gate title', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/settings/blocked-users');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('已屏蔽用戶');
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });

  testWidgets('/account/password enters auth gate title', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/account/password');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('修改密碼');
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });

  testWidgets('/friend-requests enters auth gate title', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/friend-requests');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('好友申請');
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });

  testWidgets('/add-friend enters auth gate title', (tester) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/add-friend');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('添加好友');
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });

  testWidgets('/dm/:peerId decodes path and custom title in auth gate', (
    tester,
  ) async {
    final router = await pumpLiubanRouter(tester);
    router.go('/dm/${Uri.encodeComponent('u 1')}?custom=river_2026');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expectLiubanAppBarTitle('@river_2026');
    expect(find.text('請先登入以使用此功能'), findsOneWidget);
  });
}
