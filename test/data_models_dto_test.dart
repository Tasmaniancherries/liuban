import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/models/blocked_user_dto.dart';
import 'package:liuban/data/models/dm_message_dto.dart';
import 'package:liuban/data/models/education_entry_dto.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/data/models/friend_inbox_item_dto.dart';
import 'package:liuban/data/models/friend_outgoing_request_dto.dart';
import 'package:liuban/data/models/friend_request_dto.dart';
import 'package:liuban/data/models/promotion_dto.dart';
import 'package:liuban/data/models/registration_response.dart';
import 'package:liuban/data/models/token_pair_dto.dart';
import 'package:liuban/data/models/user_profile_dto.dart';
import 'package:liuban/data/models/verification_state_dto.dart';

void main() {
  group('TokenPairDto', () {
    test('fromJson prefers access_token', () {
      final p = TokenPairDto.fromJson({
        'access_token': 'a1',
        'refresh_token': 'r1',
      });
      expect(p.accessToken, 'a1');
      expect(p.refreshToken, 'r1');
    });

    test('fromJson accepts accessToken and refreshToken aliases', () {
      final p = TokenPairDto.fromJson({
        'accessToken': 'a2',
        'refreshToken': 'r2',
      });
      expect(p.accessToken, 'a2');
      expect(p.refreshToken, 'r2');
    });

    test('fromJson accepts token as access', () {
      final p = TokenPairDto.fromJson({'token': 't0'});
      expect(p.accessToken, 't0');
      expect(p.refreshToken, isNull);
    });

    test('fromJson throws when access missing or empty', () {
      expect(
        () => TokenPairDto.fromJson(<String, dynamic>{}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TokenPairDto.fromJson({'access_token': ''}),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromResponse unwraps map', () {
      final p = TokenPairDto.fromResponse({
        'access_token': 'x',
        'refresh_token': 'y',
      });
      expect(p.accessToken, 'x');
      expect(p.refreshToken, 'y');
    });
  });

  group('VerificationStateDto', () {
    test('fromJson uses phase and message', () {
      final v = VerificationStateDto.fromJson({
        'phase': 'pending_verification',
        'message': 'queued',
      });
      expect(v.phase, 'pending_verification');
      expect(v.message, 'queued');
    });

    test('fromJson falls back to account_phase and guest', () {
      expect(
        VerificationStateDto.fromJson({
          'account_phase': 'verified_student',
        }).phase,
        'verified_student',
      );
      expect(VerificationStateDto.fromJson({}).phase, 'guest');
    });
  });

  group('RegistrationResponse', () {
    test('fromJson uses account_phase and tokens', () {
      final r = RegistrationResponse.fromJson({
        'access_token': 'acc',
        'refresh_token': 'ref',
        'account_phase': 'verified_student',
      });
      expect(r.accessToken, 'acc');
      expect(r.refreshToken, 'ref');
      expect(r.accountPhase, 'verified_student');
    });

    test('fromJson falls back to token and phase', () {
      final r = RegistrationResponse.fromJson({'token': 't', 'phase': 'guest'});
      expect(r.accessToken, 't');
      expect(r.accountPhase, 'guest');
    });

    test('fromJson defaults account phase to pending_verification', () {
      final r = RegistrationResponse.fromJson({});
      expect(r.accountPhase, 'pending_verification');
    });
  });

  group('EducationEntryDto', () {
    test('fromJson uses school_short_name and alumni bool', () {
      final e = EducationEntryDto.fromJson({
        'school_short_name': '港大',
        'alumni': true,
      });
      expect(e.schoolShortName, '港大');
      expect(e.alumni, isTrue);
      expect(e.chipLabel.endsWith('校友'), isTrue);
    });

    test('chipLabel uses 在讀 when not alumni', () {
      expect(
        EducationEntryDto.fromJson({
          'school_short_name': '中大',
          'alumni': false,
        }).chipLabel,
        '中大 在讀',
      );
    });

    test('fromJson derives alumni from status string', () {
      expect(
        EducationEntryDto.fromJson({'school': '理大', 'status': 'alumni'}).alumni,
        isTrue,
      );
      expect(
        EducationEntryDto.fromJson({
          'name': '城大',
          'status': 'graduated',
        }).alumni,
        isTrue,
      );
    });

    test('listFromJson returns empty for non-list', () {
      expect(EducationEntryDto.listFromJson('x'), isEmpty);
    });

    test('listFromJson maps elements', () {
      final list = EducationEntryDto.listFromJson([
        {'school': 'A', 'alumni': false},
      ]);
      expect(list, hasLength(1));
      expect(list.single.schoolShortName, 'A');
    });
  });

  group('UserProfileDto', () {
    test('fromJson maps id aliases and nested schools', () {
      final u = UserProfileDto.fromJson({
        'user_id': '99',
        'username': 'river',
        'display_name': 'River',
        'schools': [
          {'school_short_name': '港大', 'alumni': true},
        ],
      });
      expect(u.userId, '99');
      expect(u.customId, 'river');
      expect(u.displayName, 'River');
      expect(u.educations, hasLength(1));
      expect(u.educations.single.schoolShortName, '港大');
    });

    test('fromResponse unwraps dynamic map', () {
      final u = UserProfileDto.fromResponse({'id': 1, 'custom_id': 'c'});
      expect(u.userId, '1');
      expect(u.customId, 'c');
    });

    test('previewFallback returns stable demo profile', () {
      final u = UserProfileDto.previewFallback();
      expect(u.userId, 'local');
      expect(u.educations.length, greaterThanOrEqualTo(1));
    });
  });

  group('BlockedUserDto', () {
    test('fromJson and listFromResponse', () {
      final one = BlockedUserDto.fromJson({'id': 7, 'custom_id': '@x'});
      expect(one.userId, '7');
      expect(one.displayLabel, '@x');

      final many = BlockedUserDto.listFromResponse({
        'items': [
          {'user_id': '1', 'label': 'A'},
        ],
      });
      expect(many.single.userId, '1');
      expect(many.single.displayLabel, 'A');
    });
  });

  group('FriendRequestDto', () {
    test('fromJson uses requester alias', () {
      final r = FriendRequestDto.fromJson({
        'id': 'rid',
        'requester_custom_id': 'q',
        'created_at': '2026-01-01',
      });
      expect(r.id, 'rid');
      expect(r.fromCustomId, 'q');
      expect(r.createdAt, '2026-01-01');
    });

    test('listFromResponse unwraps', () {
      final list = FriendRequestDto.listFromResponse([
        {'id': '1', 'from_custom_id': 'a'},
      ]);
      expect(list.single.fromCustomId, 'a');
    });
  });

  group('FriendOutgoingRequestDto', () {
    test('fromJson uses target_custom_id and default status', () {
      final o = FriendOutgoingRequestDto.fromJson({
        'id': 'o1',
        'target_custom_id': 't',
      });
      expect(o.toCustomId, 't');
      expect(o.status, 'pending');
    });
  });

  group('FriendInboxItemDto', () {
    test('fromJson uses preview alias', () {
      final i = FriendInboxItemDto.fromJson({
        'peer_id': 'p',
        'username': 'u',
        'preview': 'hello',
      });
      expect(i.peerId, 'p');
      expect(i.peerCustomId, 'u');
      expect(i.lastMessagePreview, 'hello');
    });
  });

  group('FeedPostDto', () {
    test('fromJson uses content and hide_school', () {
      final f = FeedPostDto.fromJson({
        'id': 10,
        'author_id': 'auth',
        'author': 'Name',
        'content': 'body',
        'audience': 'public',
        'hide_school': true,
      });
      expect(f.id, '10');
      expect(f.authorId, 'auth');
      expect(f.authorDisplay, 'Name');
      expect(f.body, 'body');
      expect(f.audience, 'public');
      expect(f.hideSchool, isTrue);
    });

    test('listFromResponse unwraps items', () {
      final list = FeedPostDto.listFromResponse({
        'items': [
          {'id': 'x', 'body': 'b'},
        ],
      });
      expect(list.single.id, 'x');
    });
  });

  group('PromotionDto', () {
    test('fromJson uses source and date aliases', () {
      final p = PromotionDto.fromJson({
        'id': 'pid',
        'title': 'T',
        'source': 'S',
        'date': '2026-04-01',
        'content': 'C',
      });
      expect(p.subtitle, 'S');
      expect(p.publishedAt, '2026-04-01');
      expect(p.body, 'C');
    });
  });

  group('DmMessageDto', () {
    test('fromJson uses text and mine aliases', () {
      final m = DmMessageDto.fromJson({
        'id': 'mid',
        'text': 'hi',
        'mine': true,
      });
      expect(m.body, 'hi');
      expect(m.isMine, isTrue);
    });

    test('listFromResponse', () {
      final list = DmMessageDto.listFromResponse([
        {'id': '1', 'body': 'x', 'is_mine': false},
      ]);
      expect(list.single.isMine, isFalse);
    });
  });
}
