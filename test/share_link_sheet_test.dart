import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liuban/core/share/share_link_sheet.dart';

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
}
