import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// Drag-to-scroll with mouse and trackpad (e.g. desktop / web), not only wheel.
class LiubanScrollBehavior extends MaterialScrollBehavior {
  const LiubanScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
