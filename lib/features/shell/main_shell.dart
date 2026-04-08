import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liuban/core/ui/api_dev_semantics.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Semantics(
        container: true,
        label: '主要導覽列',
        hint: ApiDevSemantics.mainShellBottomNavHint,
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onTap,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dynamic_feed_outlined, semanticLabel: '廣場動態'),
              selectedIcon: Icon(Icons.dynamic_feed, semanticLabel: '廣場動態'),
              label: '廣場',
              tooltip: '廣場動態與貼文列表',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined, semanticLabel: '推廣與活動'),
              selectedIcon: Icon(Icons.campaign, semanticLabel: '推廣與活動'),
              label: '推廣',
              tooltip: '推廣內容與活動',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline, semanticLabel: '訊息與客服'),
              selectedIcon: Icon(Icons.chat_bubble, semanticLabel: '訊息與客服'),
              label: '訊息',
              tooltip: '私訊收件匣與客服',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, semanticLabel: '個人與設定'),
              selectedIcon: Icon(Icons.person, semanticLabel: '個人與設定'),
              label: '我的',
              tooltip: '個人檔案與設定',
            ),
          ],
        ),
      ),
    );
  }
}
