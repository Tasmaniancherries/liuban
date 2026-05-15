import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/models/blocked_user_dto.dart';
import 'package:liuban/data/models/dm_message_dto.dart';
import 'package:liuban/data/models/feed_post_dto.dart';
import 'package:liuban/data/models/friend_inbox_item_dto.dart';
import 'package:liuban/data/models/friend_outgoing_request_dto.dart';
import 'package:liuban/data/models/friend_request_dto.dart';

void main() {
  test('FeedPostDto fixture feed sizes and audience tags are stable', () {
    final publicFeed = FeedPostDto.fixturePublicFeed();
    final schoolFeed = FeedPostDto.fixtureSchoolFeed();
    final friendsFeed = FeedPostDto.fixtureFriendsFeed();

    expect(publicFeed, hasLength(6));
    expect(schoolFeed, hasLength(5));
    expect(friendsFeed, hasLength(4));
    expect(publicFeed.every((e) => e.audience == 'public'), isTrue);
    expect(schoolFeed.every((e) => e.audience == 'school'), isTrue);
    expect(friendsFeed.every((e) => e.audience == 'friends'), isTrue);
  });

  test('FriendRequestDto.fixturePending has at least one pending request', () {
    final list = FriendRequestDto.fixturePending();
    expect(list, isNotEmpty);
    expect(list.first.id, isNotEmpty);
    expect(list.first.fromCustomId, isNotEmpty);
  });

  test('FriendOutgoingRequestDto.fixtureOutgoing defaults to pending', () {
    final list = FriendOutgoingRequestDto.fixtureOutgoing();
    expect(list, isNotEmpty);
    expect(list.first.status, 'pending');
    expect(list.first.toCustomId, isNotEmpty);
  });

  test('FriendInboxItemDto.fixtureInbox has preview text entries', () {
    final list = FriendInboxItemDto.fixtureInbox();
    expect(list, hasLength(2));
    expect(list.every((e) => (e.lastMessagePreview ?? '').isNotEmpty), isTrue);
  });

  test('BlockedUserDto.fixtureList has display label', () {
    final list = BlockedUserDto.fixtureList();
    expect(list, isNotEmpty);
    expect((list.first.displayLabel ?? '').isNotEmpty, isTrue);
  });

  test('DmMessageDto.fixtureThread alternates mine and peer', () {
    final list = DmMessageDto.fixtureThread();
    expect(list, hasLength(2));
    expect(list.any((e) => e.isMine), isTrue);
    expect(list.any((e) => !e.isMine), isTrue);
  });
}
