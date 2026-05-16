import 'dart:async' show unawaited;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:liuban/core/config/app_config.dart';
import 'package:liuban/firebase_options.dart';

/// Whether Crashlytics should initialize for this process.
///
/// Override with `--dart-define=ENABLE_FIREBASE_CRASHLYTICS=true|false`.
/// When unset: enabled in [kReleaseMode] on mobile, disabled on web and in debug.
@visibleForTesting
bool resolveFirebaseCrashReportingEnabled({
  String enableEnv = const String.fromEnvironment(
    'ENABLE_FIREBASE_CRASHLYTICS',
  ),
  required bool isWeb,
  required bool releaseMode,
}) {
  if (enableEnv == 'true') return !isWeb;
  if (enableEnv == 'false') return false;
  if (isWeb) return false;
  return releaseMode;
}

bool get _shouldInitializeFirebaseCrashReporting =>
    resolveFirebaseCrashReportingEnabled(
      isWeb: kIsWeb,
      releaseMode: kReleaseMode,
    );

/// Set after a successful [initializeFirebaseCrashReporting] (e.g. debug test crash).
bool get isFirebaseCrashReportingActive => _initialized;
bool _initialized = false;

/// Initializes Firebase + Crashlytics when [resolveFirebaseCrashReportingEnabled] is true.
///
/// Safe to call without `google-services.json` / `flutterfire configure`: failures are
/// swallowed so local tests and CI keep working until Firebase is configured.
Future<void> initializeFirebaseCrashReporting() async {
  if (!_shouldInitializeFirebaseCrashReporting) return;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    await FirebaseCrashlytics.instance.setCustomKey(
      'app_version',
      AppConfig.appVersion,
    );

    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      return true;
    };

    _initialized = true;
  } on Object catch (e, st) {
    _initialized = false;
    if (kDebugMode) {
      debugPrint(
        'Firebase Crashlytics init skipped (configure Firebase first): $e\n$st',
      );
    }
  }
}
