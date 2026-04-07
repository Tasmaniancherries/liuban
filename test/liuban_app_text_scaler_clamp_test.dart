import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

import "liuban_test_harness.dart";

void main() {
  testWidgets("LiubanApp clamps large system text scale to 2.0", (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await pumpLiubanApp(tester, textScaler: const TextScaler.linear(3));
    final ctx = tester.element(find.byType(Scaffold).first);
    final out = MediaQuery.of(ctx).textScaler.scale(100);
    expect(out, closeTo(200, 0.01));
  });

  testWidgets("LiubanApp clamps small system text scale to 0.85", (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;

    await pumpLiubanApp(tester, textScaler: const TextScaler.linear(0.4));
    final ctx = tester.element(find.byType(Scaffold).first);
    final out = MediaQuery.of(ctx).textScaler.scale(100);
    expect(out, closeTo(85, 0.01));
  });
}
