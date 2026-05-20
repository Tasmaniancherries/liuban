# Firebase Crashlytics 接入说明

客户端已集成 `firebase_core` + `firebase_crashlytics`。完成下列步骤后，Release 包会将崩溃上报到 Firebase 控制台。

## 1. 创建 Firebase 项目并注册应用

1. 打开 [Firebase Console](https://console.firebase.google.com/)，创建或选择项目。
2. 添加 **Android** 应用，包名与 `android/app/build.gradle.kts` 中 `applicationId` 一致（当前为 `com.example.liuban`，上线前请改为正式包名）。
3. 添加 **iOS** 应用，Bundle ID 与 Xcode 一致（当前为 `com.example.liuban`）。
4. 下载配置文件（不要提交含真实密钥的副本到公开仓库，除非团队策略允许）：
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

仓库提供示例：`android/app/google-services.json.example`。

## 2. FlutterFire 配置（推荐）

在仓库根目录执行：

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

会生成/覆盖 `lib/firebase_options.dart`，并在 Android 侧注册 Gradle 插件。若已手动放置 `google-services.json`，Android 构建会自动应用 Google Services 与 Crashlytics 插件。

## 3. 启用上报

| 场景 | 行为 |
|------|------|
| **Debug** 默认 | 不初始化 Firebase（避免未配置时干扰开发） |
| **Release** 默认 | 尝试初始化；未配置时静默跳过 |
| 强制开启 | `flutter run --dart-define=ENABLE_FIREBASE_CRASHLYTICS=true` |
| 强制关闭 | `--dart-define=ENABLE_FIREBASE_CRASHLYTICS=false` |

Release 构建示例：

```bash
flutter build apk --release
flutter build ipa --release
```

## 4. 验证首次上报

在真机 **Release** 或带 `ENABLE_FIREBASE_CRASHLYTICS=true` 的构建上，临时加入测试崩溃（例如按钮 `throw Exception()`），启动应用并触发一次崩溃。约 5 分钟内应在 [Crashlytics 控制台](https://console.firebase.google.com/) 看到事件。

自定义键 `app_version` 与 `AppConfig.appVersion` / `--dart-define=APP_VERSION` 对齐。

## 5. CI 说明

GitHub Actions 的 `make ci-quality` 不依赖 Firebase。`make ci-smoke` 的 Android 构建在未放置 `google-services.json` 时仍可编译（Gradle 插件仅在文件存在时应用）。

## 6. P0 签收

完成后在 [p0_operational_runbook.md](p0_operational_runbook.md) §3 填写监控仪表盘链接并签字。
