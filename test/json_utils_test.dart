import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/data/models/json_utils.dart';

void main() {
  group('asJsonMap', () {
    test('returns same instance for Map<String, dynamic>', () {
      final m = <String, dynamic>{'a': 1};
      expect(identical(asJsonMap(m), m), isTrue);
    });

    test('copies Map when value type is not dynamic', () {
      final m = <String, int>{'b': 2};
      final out = asJsonMap(m);
      expect(out, <String, dynamic>{'b': 2});
      expect(out, isA<Map<String, dynamic>>());
    });

    test('throws on non-map', () {
      expect(() => asJsonMap('string'), throwsA(isA<FormatException>()));
      expect(() => asJsonMap(42), throwsA(isA<FormatException>()));
      expect(() => asJsonMap(<String>['a']), throwsA(isA<FormatException>()));
    });
  });

  group('asJsonObjectList', () {
    test('maps list elements', () {
      final data = [
        {'id': '1'},
        <String, dynamic>{'id': '2'},
      ];
      expect(asJsonObjectList(data), <Map<String, dynamic>>[
        {'id': '1'},
        {'id': '2'},
      ]);
    });

    test('unwraps top-level items', () {
      final data = <String, dynamic>{
        'items': [
          {'x': true},
        ],
      };
      expect(asJsonObjectList(data), <Map<String, dynamic>>[
        {'x': true},
      ]);
    });

    test('unwraps top-level data', () {
      final data = <String, dynamic>{
        'data': [
          {'y': 0},
        ],
      };
      expect(asJsonObjectList(data), <Map<String, dynamic>>[
        {'y': 0},
      ]);
    });

    test('prefers list when both shapes could apply', () {
      final data = <dynamic>[
        {'id': 'a'},
      ];
      expect(asJsonObjectList(data), <Map<String, dynamic>>[
        {'id': 'a'},
      ]);
    });

    test('throws on invalid', () {
      expect(() => asJsonObjectList('[]'), throwsA(isA<FormatException>()));
      expect(() => asJsonObjectList(1), throwsA(isA<FormatException>()));
      expect(
        () => asJsonObjectList(<String, dynamic>{}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
