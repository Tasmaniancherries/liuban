import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';
import 'package:liuban/core/persistence/app_persistence.dart';
import 'package:liuban/core/persistence/app_persistence_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppPersistence> _buildPersistence(String guestDeviceId) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AppPersistence(prefs, AuthSessionTokens(), guestDeviceId);
}

void main() {
  testWidgets('of returns persistence from nearest scope', (tester) async {
    final persistence = await _buildPersistence('g1');
    late AppPersistence read;

    await tester.pumpWidget(
      MaterialApp(
        home: AppPersistenceScope(
          persistence: persistence,
          child: Builder(
            builder: (context) {
              read = AppPersistenceScope.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(identical(read, persistence), isTrue);
  });

  testWidgets('maybeOf returns null when no scope is mounted', (tester) async {
    AppPersistence? read;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            read = AppPersistenceScope.maybeOf(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(read, isNull);
  });

  testWidgets('of throws when scope is missing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            expect(() => AppPersistenceScope.of(context), throwsA(anything));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  test('updateShouldNotify checks persistence identity', () async {
    final p1 = await _buildPersistence('g1');
    final p2 = await _buildPersistence('g2');

    final oldWidget = AppPersistenceScope(
      persistence: p1,
      child: const SizedBox.shrink(),
    );
    final sameWidget = AppPersistenceScope(
      persistence: p1,
      child: const SizedBox.shrink(),
    );
    final changedWidget = AppPersistenceScope(
      persistence: p2,
      child: const SizedBox.shrink(),
    );

    expect(sameWidget.updateShouldNotify(oldWidget), isFalse);
    expect(changedWidget.updateShouldNotify(oldWidget), isTrue);
  });
}
