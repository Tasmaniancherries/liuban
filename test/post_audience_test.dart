import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/features/feed/post_models.dart';

void main() {
  test('postAudienceFromApiValue maps contract strings', () {
    expect(postAudienceFromApiValue('public'), PostAudience.publicSquare);
    expect(postAudienceFromApiValue('school'), PostAudience.schoolPeers);
    expect(postAudienceFromApiValue('friends'), PostAudience.friendsOnly);
    expect(postAudienceFromApiValue('private'), PostAudience.selfOnly);
  });

  test('postAudienceFromApiValue returns null for empty or unknown', () {
    expect(postAudienceFromApiValue(null), isNull);
    expect(postAudienceFromApiValue(''), isNull);
    expect(postAudienceFromApiValue('nope'), isNull);
  });

  test(
    'PostAudience apiValue round-trips through postAudienceFromApiValue',
    () {
      for (final a in PostAudience.values) {
        expect(postAudienceFromApiValue(a.apiValue), a);
      }
    },
  );

  test('PostAudience shortLabel and apiValue are non-empty', () {
    for (final a in PostAudience.values) {
      expect(a.shortLabel, isNotEmpty);
      expect(a.apiValue, isNotEmpty);
    }
  });
}
