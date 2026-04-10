import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/app_container.dart';
import 'package:liuban/core/app_container_scope.dart';
import 'package:liuban/core/locale/app_locale_controller.dart';
import 'package:liuban/core/locale/app_locale_scope.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/app_session_scope.dart';
import 'package:liuban/core/theme/theme_mode_controller.dart';
import 'package:liuban/core/theme/theme_mode_scope.dart';

void main() {
  testWidgets('AppContainerScope.of returns provided container', (
    tester,
  ) async {
    final c = AppContainer(
      guestDeviceId: 'g',
      baseUrl: 'https://example.invalid',
      logHttpTraffic: false,
      sessionTokens: AuthSessionTokens(),
    );
    AppContainer? resolved;
    await tester.pumpWidget(
      AppContainerScope(
        container: c,
        child: Builder(
          builder: (context) {
            resolved = AppContainerScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(resolved, c), isTrue);
  });

  test('AppContainerScope.updateShouldNotify follows container identity', () {
    final c1 = AppContainer(
      guestDeviceId: 'g1',
      baseUrl: 'https://example.invalid',
      logHttpTraffic: false,
      sessionTokens: AuthSessionTokens(),
    );
    final c2 = AppContainer(
      guestDeviceId: 'g2',
      baseUrl: 'https://example.invalid',
      logHttpTraffic: false,
      sessionTokens: AuthSessionTokens(),
    );
    final oldScope = AppContainerScope(container: c1, child: const SizedBox());
    final newSame = AppContainerScope(container: c1, child: const SizedBox());
    final newDiff = AppContainerScope(container: c2, child: const SizedBox());

    expect(newSame.updateShouldNotify(oldScope), isFalse);
    expect(newDiff.updateShouldNotify(oldScope), isTrue);
  });

  testWidgets('ThemeModeScope.of returns provided controller', (tester) async {
    final ctrl = ThemeModeController();
    ThemeModeController? resolved;
    await tester.pumpWidget(
      ThemeModeScope(
        controller: ctrl,
        child: Builder(
          builder: (context) {
            resolved = ThemeModeScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(resolved, ctrl), isTrue);
  });

  testWidgets('AppLocaleScope.of returns provided controller', (tester) async {
    final ctrl = AppLocaleController();
    AppLocaleController? resolved;
    await tester.pumpWidget(
      AppLocaleScope(
        controller: ctrl,
        child: Builder(
          builder: (context) {
            resolved = AppLocaleScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(resolved, ctrl), isTrue);
  });

  testWidgets('AppSessionScope.of returns provided session', (tester) async {
    final s = AppSession();
    AppSession? resolved;
    await tester.pumpWidget(
      AppSessionScope(
        notifier: s,
        child: Builder(
          builder: (context) {
            resolved = AppSessionScope.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(identical(resolved, s), isTrue);
  });
}
