import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/session/app_session.dart';

void main() {
  test('initial state is guest with guest-like permissions', () {
    final s = AppSession();
    expect(s.phase, AccountPhase.guest);
    expect(s.isGuestLike, isTrue);
    expect(s.canUseSchoolAndFriends, isFalse);
  });

  test('verified student can use school and friends', () {
    final s = AppSession()..setPhase(AccountPhase.verifiedStudent);
    expect(s.isGuestLike, isFalse);
    expect(s.canUseSchoolAndFriends, isTrue);
  });

  test('pending verification is guest-like', () {
    final s = AppSession()..setPhase(AccountPhase.pendingVerification);
    expect(s.isGuestLike, isTrue);
    expect(s.canUseSchoolAndFriends, isFalse);
  });

  test('setPhase does not notify when phase unchanged', () {
    final s = AppSession();
    var n = 0;
    s.addListener(() => n++);
    s.setPhase(AccountPhase.guest);
    expect(n, 0);
  });

  test('setPhase notifies when phase changes', () {
    final s = AppSession();
    var n = 0;
    s.addListener(() => n++);
    s.setPhase(AccountPhase.verifiedStudent);
    expect(s.phase, AccountPhase.verifiedStudent);
    expect(n, 1);
  });

  test('signOut resets to guest', () {
    final s = AppSession()..setPhase(AccountPhase.verifiedStudent);
    s.signOut();
    expect(s.phase, AccountPhase.guest);
  });
}
