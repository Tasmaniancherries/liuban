import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:liuban/core/app_container.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/bootstrap/session_hydrator.dart";
import "package:liuban/core/network/auth_session_tokens.dart";
import "package:liuban/core/session/app_session.dart";

void main() {
  testWidgets("SessionHydrator calls signOut when access token is cleared", (tester) async {
    final session = AppSession()..setPhase(AccountPhase.verifiedStudent);
    final tokens = AuthSessionTokens(accessToken: "a", refreshToken: "r");
    final container = AppContainer(
      sessionTokens: tokens,
      guestDeviceId: "t",
      baseUrl: "https://example.invalid",
      logHttpTraffic: false,
    );

    await tester.pumpWidget(
      AppContainerScope(
        container: container,
        child: SessionHydrator(
          session: session,
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump();
    // SessionHydrator 啟動時會非同步拉審核狀態；讓 Dio 連線逾時結束，避免測試結束時仍掛 Timer。
    await tester.pump(const Duration(seconds: 20));
    expect(session.phase, AccountPhase.verifiedStudent);

    tokens.clear();
    await tester.pump();

    expect(session.phase, AccountPhase.guest);
  });
}
