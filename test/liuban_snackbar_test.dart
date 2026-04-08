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
  });
}
