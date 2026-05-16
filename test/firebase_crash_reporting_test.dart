import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/monitoring/firebase_crash_reporting.dart';

void main() {
  group('resolveFirebaseCrashReportingEnabled', () {
    test('explicit true enables on mobile', () {
      expect(
        resolveFirebaseCrashReportingEnabled(
          enableEnv: 'true',
          isWeb: false,
          releaseMode: false,
        ),
        isTrue,
      );
    });

    test('explicit true still disabled on web', () {
      expect(
        resolveFirebaseCrashReportingEnabled(
          enableEnv: 'true',
          isWeb: true,
          releaseMode: true,
        ),
        isFalse,
      );
    });

    test('explicit false disables', () {
      expect(
        resolveFirebaseCrashReportingEnabled(
          enableEnv: 'false',
          isWeb: false,
          releaseMode: true,
        ),
        isFalse,
      );
    });

    test('default follows release mode on mobile', () {
      expect(
        resolveFirebaseCrashReportingEnabled(isWeb: false, releaseMode: true),
        isTrue,
      );
      expect(
        resolveFirebaseCrashReportingEnabled(isWeb: false, releaseMode: false),
        isFalse,
      );
    });

    test('default off on web', () {
      expect(
        resolveFirebaseCrashReportingEnabled(isWeb: true, releaseMode: true),
        isFalse,
      );
    });
  });
}
