/// 執行時可覆寫：`flutter run --dart-define=API_BASE_URL=https://dev.example.com`
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.liuban.example.com',
  );

  static const String apiPrefix = String.fromEnvironment(
    'API_PREFIX',
    defaultValue: '/v1',
  );

  /// 與 `pubspec.yaml` version 對齊；上線流程可改 `--dart-define=APP_VERSION=1.0.0`
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );

  /// 對外 H5／Universal Link 前綴，非 API host。
  static const String shareLinkOrigin = String.fromEnvironment(
    'SHARE_LINK_ORIGIN',
    defaultValue: 'https://liuban.app',
  );
}
