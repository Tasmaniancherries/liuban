import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/debug/unawaited_debug.dart';

void main() {
  test('unawaitedDebug does not rethrow rejected futures', () async {
    unawaitedDebug(
      'test.failure',
      Future<void>.error(StateError('boom'), StackTrace.empty),
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('unawaitedDebugFuture does not rethrow rejected futures', () async {
    unawaitedDebugFuture<int>(
      'test.failure.int',
      Future<int>.error(StateError('nope'), StackTrace.empty),
    );
    await Future<void>.delayed(Duration.zero);
  });

  test('unawaitedDebugFuture ignores successful completion values', () async {
    unawaitedDebugFuture<int>('test.success.int', Future<int>.value(42));
    await Future<void>.delayed(Duration.zero);
  });

  test('unawaitedDebugFuture handles multiple calls independently', () async {
    unawaitedDebugFuture<int>('test.multi.1', Future<int>.value(1));
    unawaitedDebugFuture<int>(
      'test.multi.2',
      Future<int>.error(StateError('multi'), StackTrace.empty),
    );
    unawaitedDebugFuture<int>('test.multi.3', Future<int>.value(3));
    await Future<void>.delayed(Duration.zero);
  });
}
