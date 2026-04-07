import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:liuban/core/app_container_scope.dart";
import "package:liuban/core/debug/unawaited_debug.dart";
import "package:liuban/core/config/app_config.dart";
import "package:liuban/core/locale/app_locale_preference.dart";
import "package:liuban/core/locale/app_locale_scope.dart";
import "package:liuban/core/theme/theme_mode_scope.dart";
import "package:liuban/core/ui/api_dev_semantics.dart";
import "package:liuban/core/ui/liuban_snackbar.dart";
import "package:liuban/core/ui/scroll_constants.dart";

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String _themeModeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => "跟隨系統",
        ThemeMode.light => "淺色",
        ThemeMode.dark => "深色",
      };

  static String _localeLabel(AppLocalePreference p) => switch (p) {
        AppLocalePreference.system => "跟隨系統",
        AppLocalePreference.zhHK => "繁體中文（香港）",
        AppLocalePreference.zhTW => "繁體中文（台灣）",
        AppLocalePreference.english => "English",
      };

  Future<void> _pickThemeMode(BuildContext context) async {
    final ctrl = ThemeModeScope.of(context);
    final chosen = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: "選擇外觀主題",
        hint: ApiDevSemantics.settingsLocalUiPreferenceDialogHint,
        child: AlertDialog(
          title: const Text("外觀"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: "切換為跟隨系統主題",
                child: Semantics(
                  button: true,
                  label: "切換為跟隨系統主題",
                  hint: "選取後套用系統外觀",
                  excludeSemantics: true,
                  child: ListTile(
                    title: const SelectionArea(
                      child: Text("跟隨系統"),
                    ),
                    trailing: ctrl.mode == ThemeMode.system
                        ? const Icon(Icons.check, semanticLabel: "目前選取")
                        : null,
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.system),
                  ),
                ),
              ),
              Tooltip(
                message: "切換為淺色主題",
                child: Semantics(
                  button: true,
                  label: "切換為淺色主題",
                  hint: "選取後固定淺色外觀",
                  excludeSemantics: true,
                  child: ListTile(
                    title: const SelectionArea(
                      child: Text("淺色"),
                    ),
                    trailing: ctrl.mode == ThemeMode.light
                        ? const Icon(Icons.check, semanticLabel: "目前選取")
                        : null,
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.light),
                  ),
                ),
              ),
              Tooltip(
                message: "切換為深色主題",
                child: Semantics(
                  button: true,
                  label: "切換為深色主題",
                  hint: "選取後固定深色外觀",
                  excludeSemantics: true,
                  child: ListTile(
                    title: const SelectionArea(
                      child: Text("深色"),
                    ),
                    trailing: ctrl.mode == ThemeMode.dark
                        ? const Icon(Icons.check, semanticLabel: "目前選取")
                        : null,
                    onTap: () => Navigator.of(ctx).pop(ThemeMode.dark),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            Tooltip(
              message: "關閉，不改變主題",
              child: Semantics(
                button: true,
                label: "關閉，不改變主題",
                hint: "關閉對話框且不變更外觀",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("取消"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    await ctrl.setMode(chosen);
  }

  Future<void> _pickLocale(BuildContext context) async {
    final ctrl = AppLocaleScope.of(context);
    final chosen = await showDialog<AppLocalePreference>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: "選擇介面語言",
        hint: ApiDevSemantics.settingsLocalUiPreferenceDialogHint,
        child: AlertDialog(
          title: const Text("介面語言"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final opt in AppLocalePreference.values)
                Tooltip(
                  message: "切換語言：${_localeLabel(opt)}",
                  child: Semantics(
                    button: true,
                    label: "切換語言：${_localeLabel(opt)}",
                    hint: "選取後套用此介面語言",
                    excludeSemantics: true,
                    child: ListTile(
                      title: SelectionArea(
                        child: Text(_localeLabel(opt)),
                      ),
                      trailing: ctrl.preference == opt
                          ? const Icon(Icons.check, semanticLabel: "目前選取")
                          : null,
                      onTap: () => Navigator.of(ctx).pop(opt),
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            Tooltip(
              message: "關閉，不改變語言",
              child: Semantics(
                button: true,
                label: "關閉，不改變語言",
                hint: "關閉對話框且不變更語言",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("取消"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    try {
      await ctrl.setPreference(chosen);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        liubanSnackBarWithSemanticsHint(
          ApiDevSemantics.settingsPersistenceFailedMessage,
          semanticsHint: ApiDevSemantics.settingsPersistenceFailedSnackHint,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasToken =
        AppContainerScope.of(context).sessionTokens.accessToken != null &&
            AppContainerScope.of(context).sessionTokens.accessToken!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "設定",
          semanticsLabel: "應用程式設定",
        ),
        leading: Semantics(
          hint: "關閉設定並返回上一頁",
          child: IconButton(
            tooltip: "返回",
            icon: const Icon(Icons.arrow_back, semanticLabel: "返回"),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: ListView(
        cacheExtent: kLiubanListCacheExtent,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          Tooltip(
            message: "主題設定",
            child: Semantics(
              button: true,
              label: "主題設定",
              hint: "開啟淺色、深色或跟隨系統",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.palette_outlined,
                  semanticLabel: "主題",
                ),
                title: const Text("主題"),
                subtitle: SelectionArea(
                  child: Text(_themeModeLabel(ThemeModeScope.of(context).mode)),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebug(
                  "SettingsScreen._pickThemeMode",
                  _pickThemeMode(context),
                ),
              ),
            ),
          ),
          Tooltip(
            message: "介面語言設定",
            child: Semantics(
              button: true,
              label: "介面語言設定",
              hint: "開啟語言偏好選項",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.language_outlined,
                  semanticLabel: "介面語言",
                ),
                title: const Text("介面語言"),
                subtitle: SelectionArea(
                  child:
                      Text(_localeLabel(AppLocaleScope.of(context).preference)),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebug(
                  "SettingsScreen._pickLocale",
                  _pickLocale(context),
                ),
              ),
            ),
          ),
          if (hasToken) ...[
            Tooltip(
              message: "修改帳號密碼",
              child: Semantics(
                button: true,
                label: "修改帳號密碼",
                hint: "前往變更密碼頁面",
                excludeSemantics: true,
                child: ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    semanticLabel: "修改密碼",
                  ),
                  title: const Text("修改密碼"),
                  trailing: const Icon(
                    Icons.chevron_right,
                    semanticLabel: "前往詳情",
                  ),
                  onTap: () => unawaitedDebugFuture(
                    "SettingsScreen.pushChangePassword",
                    context.push("/account/password"),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: "查看或解除已屏蔽用戶",
              child: Semantics(
                button: true,
                label: "查看或解除已屏蔽用戶",
                hint: "管理已屏蔽名單",
                excludeSemantics: true,
                child: ListTile(
                  leading: const Icon(
                    Icons.person_off_outlined,
                    semanticLabel: "已屏蔽用戶",
                  ),
                  title: const Text("已屏蔽用戶"),
                  subtitle: const SelectionArea(
                    child: Text("查看或解除屏蔽"),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    semanticLabel: "前往詳情",
                  ),
                  onTap: () => unawaitedDebugFuture(
                    "SettingsScreen.pushBlockedUsers",
                    context.push("/settings/blocked-users"),
                  ),
                ),
              ),
            ),
          ],
          Tooltip(
            message: "忘記密碼與客服協助",
            child: Semantics(
              button: true,
              label: "忘記密碼與客服協助",
              hint: "郵箱重設或聯絡客服",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.lock_reset_outlined,
                  semanticLabel: "忘記密碼",
                ),
                title: const Text("忘記密碼"),
                subtitle: const SelectionArea(
                  child: Text("郵箱重設或客服"),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebugFuture(
                  "SettingsScreen.pushForgotPassword",
                  context.push("/forgot-password"),
                ),
              ),
            ),
          ),
          Tooltip(
            message: "前往意見與客服",
            child: Semantics(
              button: true,
              label: "前往意見與客服",
              hint: "開啟官方客服聊天",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.support_agent_outlined,
                  semanticLabel: "意見與客服",
                ),
                title: const Text("意見與客服"),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebugFuture(
                  "SettingsScreen.pushSupport",
                  context.push("/support"),
                ),
              ),
            ),
          ),
          Tooltip(
            message: "查看用戶協議與隱私",
            child: Semantics(
              button: true,
              label: "查看用戶協議與隱私",
              hint: "顯示協議與隱私說明",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.gavel_outlined,
                  semanticLabel: "用戶協議與隱私",
                ),
                title: const Text("用戶協議與隱私"),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebug(
                  "SettingsScreen._showLegalDialog",
                  _showLegalDialog(context),
                ),
              ),
            ),
          ),
          Tooltip(
            message: "查看開源許可",
            child: Semantics(
              button: true,
              label: "查看開源許可",
              hint: "顯示第三方套件授權頁",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.library_books_outlined,
                  semanticLabel: "開源許可",
                ),
                title: const Text("開源許可"),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => unawaitedDebugFuture(
                  "SettingsScreen.pushOpenSourceLicenses",
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (ctx) => Semantics(
                        container: true,
                        label: "開源套件授權",
                        hint: ApiDevSemantics.openSourceLicensesPageHint,
                        child: const LicensePage(
                          applicationName: "留伴",
                          applicationVersion: AppConfig.appVersion,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Tooltip(
            message: "查看關於留伴",
            child: Semantics(
              button: true,
              label: "查看關於留伴",
              hint: "顯示版本與簡介",
              excludeSemantics: true,
              child: ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  semanticLabel: "關於留伴",
                ),
                title: const Text("關於留伴"),
                subtitle: const SelectionArea(
                  child: Text("版本 ${AppConfig.appVersion}"),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  semanticLabel: "前往詳情",
                ),
                onTap: () => _showAbout(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showLegalDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Semantics(
        container: true,
        label: "用戶協議與隱私說明",
        hint: ApiDevSemantics.settingsLegalDialogContainerHint,
        child: AlertDialog(
          title: const Text("用戶協議與隱私"),
          content: SingleChildScrollView(
            child: SelectionArea(
              child: Text(
                ApiDevSemantics.settingsLegalPlaceholder,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
            ),
          ),
          actions: [
            Tooltip(
              message: "關閉",
              child: Semantics(
                button: true,
                label: "關閉",
                hint: "關閉協議與隱私說明",
                excludeSemantics: true,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("關閉"),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "留伴",
      applicationVersion: AppConfig.appVersion,
      applicationIcon: const Icon(
        Icons.favorite_outline,
        size: 40,
        semanticLabel: "留伴",
      ),
      children: [
        Semantics(
          container: true,
          label: ApiDevSemantics.aboutDialogSemanticsLabel,
          hint: "使用對話框關閉按鈕結束並返回上一頁",
          excludeSemantics: true,
          child: SelectionArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ApiDevSemantics.aboutDialogDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  ApiDevSemantics.aboutDialogApiFootnote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
