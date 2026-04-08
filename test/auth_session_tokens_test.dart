import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/network/auth_session_tokens.dart';

void main() {
  test('accessToken setter does not notify when unchanged', () {
    final t = AuthSessionTokens(accessToken: 'x');
    var n = 0;
    t.addListener(() => n++);
    t.accessToken = 'x';
    expect(n, 0);
  });

  test('accessToken setter notifies when value changes', () {
    final t = AuthSessionTokens(accessToken: 'a');
    var n = 0;
    t.addListener(() => n++);
    t.accessToken = 'b';
    expect(t.accessToken, 'b');
    expect(n, 1);
  });

  test('refreshToken setter does not notify when unchanged', () {
    final t = AuthSessionTokens(refreshToken: 'r');
    var n = 0;
    t.addListener(() => n++);
    t.refreshToken = 'r';
    expect(n, 0);
  });

  test('bearer mirrors accessToken', () {
    final t = AuthSessionTokens();
    t.bearer = 'tok';
    expect(t.accessToken, 'tok');
    expect(t.bearer, 'tok');
    expect(t.refreshToken, isNull);
  });

  test('applyPair sets access and refresh when refresh non-empty', () {
    final t = AuthSessionTokens(accessToken: 'old', refreshToken: 'oldR');
    var n = 0;
    t.addListener(() => n++);
    t.applyPair(access: 'new', refresh: 'newR');
    expect(t.accessToken, 'new');
    expect(t.refreshToken, 'newR');
    expect(n, 1);
  });

  test('applyPair leaves refresh when refresh null or empty', () {
    final t = AuthSessionTokens(accessToken: 'a', refreshToken: 'keep');
    t.applyPair(access: 'b', refresh: '');
    expect(t.accessToken, 'b');
    expect(t.refreshToken, 'keep');

    t.applyPair(access: 'c');
    expect(t.accessToken, 'c');
    expect(t.refreshToken, 'keep');
  });

  test('clear nulls tokens and notifies', () {
    final t = AuthSessionTokens(accessToken: 'a', refreshToken: 'r');
    var n = 0;
    t.addListener(() => n++);
    t.clear();
    expect(t.accessToken, isNull);
    expect(t.refreshToken, isNull);
    expect(n, 1);
  });
}
