import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/session/app_session.dart';
import 'package:liuban/core/session/verification_phase_mapper.dart';

void main() {
  test('accountPhaseFromVerificationApi maps verified aliases', () {
    expect(
      accountPhaseFromVerificationApi('verified_student'),
      AccountPhase.verifiedStudent,
    );
    expect(
      accountPhaseFromVerificationApi('verified'),
      AccountPhase.verifiedStudent,
    );
  });

  test('accountPhaseFromVerificationApi maps pending aliases', () {
    expect(
      accountPhaseFromVerificationApi('pending_verification'),
      AccountPhase.pendingVerification,
    );
    expect(
      accountPhaseFromVerificationApi('pending'),
      AccountPhase.pendingVerification,
    );
  });

  test('accountPhaseFromVerificationApi maps unknown to guest', () {
    expect(accountPhaseFromVerificationApi(''), AccountPhase.guest);
    expect(accountPhaseFromVerificationApi('rejected'), AccountPhase.guest);
  });
}
