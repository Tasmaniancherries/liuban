import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/ui/liuban_snackbar.dart';

void main() {
  test('liubanSnackBar uses four second default duration', () {
    final bar = liubanSnackBar('msg');
    expect(bar.duration, const Duration(milliseconds: 4000));
    final wrap = bar.content as Semantics;
    expect(wrap.child, isA<Text>());
  });

  test('liubanSnackBarWithSemanticsHint wraps content in Semantics', () {
    final bar = liubanSnackBarWithSemanticsHint('hello', semanticsHint: 'hint');
    expect(bar.duration, const Duration(milliseconds: 4000));
    expect(bar.content, isA<Semantics>());
    final semantics = bar.content as Semantics;
    expect(semantics.properties.label, 'hello');
    expect(semantics.properties.hint, 'hint');
  });

  test('liubanSnackBar supports custom duration and action', () {
    final action = SnackBarAction(label: 'undo', onPressed: () {});
    final bar = liubanSnackBar(
      'msg',
      duration: const Duration(seconds: 1),
      action: action,
    );
    expect(bar.duration, const Duration(seconds: 1));
    expect(bar.action, same(action));
  });

  test(
    'liubanSnackBarContent wraps custom widget in live-region semantics',
    () {
      const content = Row(
        children: [
          Icon(Icons.info),
          SizedBox(width: 8),
          Text('rich message'),
        ],
      );
      final bar = liubanSnackBarContent(content);
      expect(bar.duration, const Duration(milliseconds: 4000));
      expect(bar.content, isA<Semantics>());
      final semantics = bar.content as Semantics;
      expect(semantics.properties.liveRegion, isTrue);
      expect(semantics.child, same(content));
    },
  );
}
