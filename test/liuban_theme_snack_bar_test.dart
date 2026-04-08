import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/app/theme.dart';

void main() {
  test('LiubanTheme snack bars use floating behavior', () {
    expect(
      LiubanTheme.light().snackBarTheme.behavior,
      SnackBarBehavior.floating,
    );
    expect(
      LiubanTheme.dark().snackBarTheme.behavior,
      SnackBarBehavior.floating,
    );
  });
}
