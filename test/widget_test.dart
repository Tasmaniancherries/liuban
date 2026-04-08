import 'package:flutter_test/flutter_test.dart';

import 'liuban_test_harness.dart';

void main() {
  testWidgets('App boots and shows 廣場 tab', (tester) async {
    await pumpLiubanApp(tester);
    expect(find.textContaining('留伴'), findsWidgets);
    expect(find.text('廣場'), findsOneWidget);
  });

  testWidgets('Main shell bottom nav exposes tooltips for each tab', (
    tester,
  ) async {
    await pumpLiubanApp(tester);
    expect(find.byTooltip('廣場動態與貼文列表'), findsOneWidget);
    expect(find.byTooltip('推廣內容與活動'), findsOneWidget);
    expect(find.byTooltip('私訊收件匣與客服'), findsOneWidget);
    expect(find.byTooltip('個人檔案與設定'), findsOneWidget);
  });
}
