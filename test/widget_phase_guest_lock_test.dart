import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/app/theme.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/widgets/guest_lock_overlay.dart';
import 'package:liuban/widgets/phase_badge.dart';

void main() {
  group('PhaseBadge', () {
    for (final phase in AccountPhase.values) {
      testWidgets('shows label for $phase', (tester) async {
        final session = AppSession()..setPhase(phase);
        await tester.pumpWidget(
          MaterialApp(
            theme: LiubanTheme.light(),
            home: AppSessionScope(
              notifier: session,
              child: const Scaffold(body: Center(child: PhaseBadge())),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final expected = switch (phase) {
          AccountPhase.guest => '訪客',
          AccountPhase.pendingVerification => '審核中',
          AccountPhase.verifiedStudent => '已認證',
        };
        expect(find.text(expected), findsOneWidget);
      });
    }
  });

  group('GuestLockOverlay', () {
    testWidgets('unlocked shows child only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LiubanTheme.light(),
          home: const GuestLockOverlay(
            locked: false,
            title: 'T',
            message: 'M',
            child: Text('VISIBLE'),
          ),
        ),
      );
      expect(find.text('VISIBLE'), findsOneWidget);
      expect(find.text('LOCK_TITLE'), findsNothing);
    });

    testWidgets('locked shows title and message over faded child', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: LiubanTheme.light(),
          home: const GuestLockOverlay(
            locked: true,
            title: 'LOCK_TITLE',
            message: 'LOCK_MSG',
            child: Text('FADED'),
          ),
        ),
      );
      expect(find.text('LOCK_TITLE'), findsOneWidget);
      expect(find.text('LOCK_MSG'), findsOneWidget);
      expect(find.text('FADED'), findsOneWidget);
    });

    testWidgets('locked with login callback taps button', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: LiubanTheme.light(),
          home: GuestLockOverlay(
            locked: true,
            title: 'T',
            message: 'M',
            child: const Text('X'),
            onGoToLogin: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('前往登入'));
      expect(tapped, isTrue);
    });
  });
}
