import "package:flutter/material.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:flutter/services.dart";
import "package:liuban/app/liuban_app.dart";
import "package:liuban/core/app_container.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/bootstrap/session_hydrator.dart";
import "package:liuban/core/locale/app_locale_controller.dart";
import "package:liuban/core/locale/app_locale_scope.dart";
import "package:liuban/core/persistence/app_persistence.dart";
import "package:liuban/core/persistence/app_persistence_scope.dart";
import "package:liuban/core/session/app_session.dart";
import "package:liuban/core/session/app_session_scope.dart";
import "package:liuban/core/theme/theme_mode_controller.dart";
import "package:liuban/core/theme/theme_mode_scope.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final persistence = await AppPersistence.initialize();
  persistence.sessionTokens.addListener(() {
    unawaitedDebug("persistSessionTokens", persistence.persistSessionTokens());
  });

  final session = AppSession();
  final container = AppContainer(
    sessionTokens: persistence.sessionTokens,
    guestDeviceId: persistence.guestDeviceId,
  );
  final themeMode = ThemeModeController(persistence: persistence);
  final appLocale = AppLocaleController(persistence: persistence);
  runApp(
    AppPersistenceScope(
      persistence: persistence,
      child: AppSessionScope(
        notifier: session,
        child: AppContainerScope(
          container: container,
          child: ThemeModeScope(
            controller: themeMode,
            child: AppLocaleScope(
              controller: appLocale,
              child: SessionHydrator(
                session: session,
                child: LiubanApp(
                  session: session,
                  sessionTokens: persistence.sessionTokens,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
