import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/ui/app_scroll_behavior.dart';

void main() {
  test('LiubanScrollBehavior enables drag scroll for pointer kinds', () {
    const behavior = LiubanScrollBehavior();
    expect(behavior.dragDevices, contains(PointerDeviceKind.touch));
    expect(behavior.dragDevices, contains(PointerDeviceKind.mouse));
    expect(behavior.dragDevices, contains(PointerDeviceKind.stylus));
    expect(behavior.dragDevices, contains(PointerDeviceKind.trackpad));
  });
}
