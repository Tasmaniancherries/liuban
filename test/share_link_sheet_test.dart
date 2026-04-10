import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/share/share_link_sheet.dart';

const _shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

void main() {
  testWidgets('showShareLinkSheet shows url and primary actions', (
    tester,
  ) async {
    const url = 'https://liuban.app/post/abc';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showShareLinkSheet(context, url: url),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(url), findsOneWidget);
    expect(find.text('複製連結'), findsOneWidget);
    expect(find.text('分享至…'), findsOneWidget);
  });

  testWidgets(
    'copy action writes clipboard, closes sheet, and shows snackbar',
    (tester) async {
      const url = 'https://liuban.app/post/abc';
      String? clipboardText;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText = (call.arguments as Map)['text'] as String?;
          return null;
        }
        if (call.method == 'HapticFeedback.vibrate') {
          return null;
        }
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showShareLinkSheet(context, url: url),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('複製連結'));
      await tester.pumpAndSettle();

      expect(clipboardText, url);
      expect(find.text('已複製連結'), findsOneWidget);
      expect(find.text('分享至…'), findsNothing);
    },
  );

  testWidgets('copy failure shows error snackbar and keeps sheet open', (
    tester,
  ) async {
    const url = 'https://liuban.app/post/abc';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        throw PlatformException(code: 'clipboard-error');
      }
      if (call.method == 'HapticFeedback.vibrate') {
        return null;
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showShareLinkSheet(context, url: url),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('複製連結'));
    await tester.pumpAndSettle();

    expect(find.text('無法複製連結'), findsOneWidget);
    expect(find.text('分享至…'), findsOneWidget);
  });

  testWidgets('system share failure shows snackbar and closes sheet', (
    tester,
  ) async {
    const url = 'https://liuban.app/post/abc';
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_shareChannel, (call) async {
      if (call.method == 'share') {
        throw PlatformException(code: 'share-error');
      }
      return null;
    });
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        return null;
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(_shareChannel, null);
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showShareLinkSheet(context, url: url),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('分享至…'));
    await tester.pumpAndSettle();

    expect(find.text('無法開啟系統分享'), findsOneWidget);
    expect(find.text('分享至…'), findsNothing);
  });

  testWidgets('share sheet exposes key semantics labels', (tester) async {
    const url = 'https://liuban.app/post/abc';
    final handle = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () => showShareLinkSheet(context, url: url),
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('複製連結'), findsOneWidget);
      expect(find.bySemanticsLabel('分享至其他 App'), findsOneWidget);
    } finally {
      handle.dispose();
    }
  });
}
