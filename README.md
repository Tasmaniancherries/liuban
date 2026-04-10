# 留伴（Liuban）

在港留學生社交應用 — 使用 **Flutter** 同時支援 **iOS** 與 **Android**。

[![Flutter CI](https://github.com/Tasmaniancherries/liuban/actions/workflows/flutter.yml/badge.svg)](https://github.com/Tasmaniancherries/liuban/actions/workflows/flutter.yml)
[![Meta lint](https://github.com/Tasmaniancherries/liuban/actions/workflows/meta-lint.yml/badge.svg)](https://github.com/Tasmaniancherries/liuban/actions/workflows/meta-lint.yml)
[![Dependency review](https://github.com/Tasmaniancherries/liuban/actions/workflows/dependency-review.yml/badge.svg)](https://github.com/Tasmaniancherries/liuban/actions/workflows/dependency-review.yml)

## 環境準備

1. 安裝 [Flutter SDK](https://docs.flutter.dev/get-started/install)（穩定版；建議與 CI 一致，見下方 GitHub 自動化中的 **`FLUTTER_VERSION`**）。`pubspec.yaml` 要求 **Dart `>=3.9.0 <4.0.0`**（隨 Flutter 內建 Dart 一併滿足即可）。
2. 在本專案根目錄執行（會自動補齊 `android/`、`ios/` 等平台目錄）：

   ```bash
   cd liuban
   flutter pub get
   flutter create . --project-name liuban
   ```

   若已存在平台資料夾，`flutter create .` 會與現有設定合併。

3. 檢查環境：

   ```bash
   flutter doctor
   ```

## 運行

```bash
flutter run
```

指定裝置：

```bash
flutter devices
flutter run -d ios
flutter run -d android
```

## Web 建置（可選）

```bash
flutter build web --release
```

輸出在 `build/web`。CI 會在 `main` 的 workflow 裡執行相同指令作為**編譯煙霧測試**（與上架無關，僅確認可編譯）。

本機 Android APK（需已安裝 Android SDK／`flutter doctor` 通過 Android 工具鏈）：

```bash
flutter build apk --debug
```

## 開發與測試

```bash
make ci-quality   # 與 CI quality job 完全一致（含 lockfile/format/analyze/test+coverage）
```

也可用 `make` 快捷（封裝同一組命令）：

```bash
make ci-quality
make ci-smoke
make meta-lint
```

產生覆蓋率報告（`coverage/lcov.info`；可本機用 IDE／[`lcov`](https://github.com/linux-test-project/lcov) 檢視；CI 將此檔上傳為 **artifact**）：

```bash
flutter test --coverage
```

變更 `pubspec.yaml` 後請執行 `flutter pub get` 並一併提交 `pubspec.lock`（CI 以 `flutter pub get --enforce-lockfile` 驗證）。

若要只跑單一測試檔：

```bash
flutter test test/unawaited_debug_test.dart
```

其他範例：`test/dio_client_test.dart`（記錄脫敏）、`test/dio_session_dio_test.dart`（`createSessionDio`／`createPlainDio` 與 Bearer）、`test/router_build_test.dart`（`buildRouter` 首屏與未知路徑錯誤頁）、`test/auth_session_tokens_test.dart`（`AuthSessionTokens`）、`test/liuban_api_exception_test.dart`（`LiubanApiException.fromDio`）、`test/json_utils_test.dart`（`asJsonMap`／`asJsonObjectList`）、`test/verification_phase_mapper_test.dart`（`accountPhaseFromVerificationApi`）、`test/api_dev_semantics_test.dart`（`GoRouter` 錯誤文案與無障礙標籤組字）、`test/token_refresh_interceptor_test.dart`（401 刷新與 `HttpClientAdapter` 迴路）。

其他（DTO／session／設定）：`test/data_models_dto_test.dart`（各資料模型 `fromJson`／`listFromResponse`）、`test/app_session_test.dart`（`AppSession` 階段與通知）、`test/post_audience_test.dart`（`PostAudience` 與 API 字串）、`test/app_config_test.dart`（`AppConfig` 預設編譯期常數）、`test/promotion_models_test.dart`（`PromotionItem.fromDto`／`promotionById`）。

其他（路由／門檻／UI 小件）：`test/auth_required_gate_test.dart`、`test/compose_access_gate_test.dart`、`test/widget_phase_guest_lock_test.dart`（`PhaseBadge`／`GuestLockOverlay`）、`test/scroll_behavior_test.dart`、`test/liuban_snackbar_test.dart`。

其他（登入與主殼）：`test/login_screen_test.dart`（返回／捨棄輸入／空表單驗證）、`test/main_shell_navigation_test.dart`（底部導航各分頁、`router.go('/settings')`）、`test/router_stack_routes_test.dart`（登入／忘記密碼／註冊／客服／重設密碼／動態詳情／推廣詳情、`/compose`/`/compose/edit`、`/dm` 標題與受保護路由 gate 等堆疊路由）、`test/pump_liuban_router.dart`（測試用 `pumpLiubanRouter` 輔助）。

## 專案結構（概要）

| 路徑 | 說明 |
|------|------|
| `lib/main.dart` | 入口 |
| `lib/app/` | 主題、`GoRouter` |
| `lib/features/shell/` | 底部導航主殼 |
| `lib/features/feed/` | 廣場／動態（公開／本校／好友 Tab） |
| `lib/features/promotion/` | 推廣列表與詳情 |
| `lib/features/messages/` | 訊息（好友／官方客服） |
| `lib/features/profile/` | 我的 |
| `lib/features/auth/` | 註冊／身分審核 |
| `lib/core/ui/api_dev_semantics.dart` | 無障礙／開發用 API 路徑說明（含 `API_PREFIX`） |
| `docs/README.md` | 契約文件索引 |
| `docs/backend_auth_contract.md` | 認證、TokenPair／Bearer、refresh、`/auth/me`、密碼重置等 |
| `docs/backend_domain_apis_contract.md` | 廣場、好友／私訊、推廣、客服 API |

目前 UI 為可運行的**前端殼子**；後端請依上列契約對接。

## 主要套件（路由／分享）

- [**go_router**](https://pub.dev/packages/go_router) **^17.x**：宣告式路由與 deep link（見 `lib/app/router.dart`）。
- [**share_plus**](https://pub.dev/packages/share_plus) **^12.x**：系統分享請用 **`SharePlus.instance.share(ShareParams)`**（已取代舊版 `Share.share`）。

其餘依賴以 `pubspec.yaml` / `pubspec.lock` 為準。開發依賴 **`test`** 需與 Flutter SDK 內建的 **`flutter_test`** 解析相容，勿手動升到與 SDK 釘選的 `test_api` 衝突的版本。

## GitHub 自動化

- 已提供 CI：`.github/workflows/flutter.yml`（兩個 job：**Format, analyze, test** 先跑；通過後才跑 **Web & Android smoke builds**，可較早失敗、少佔用 Android SDK 下載；Flutter 釘選 **3.41.6**（workflow 頂層 **`env.FLUTTER_VERSION`**，一處修改即可）以維持可重現建置）
- 觸發時機：對 `main` 的 push 與 pull request；亦可在 Actions 分頁 **Run workflow** 手動執行。純文件變更（如 `*.md`、Issue/PR 模板、`LICENSE`）預設略過此重型 workflow
- 內容：`dart format`（檢查）、`dart analyze --fatal-infos`、`flutter test --coverage`（上傳 `lcov` artifact）、`flutter build web --release` 與 **`flutter build apk --debug`**（安裝 **Android API 36** + **NDK 28.2.13676358**；並上傳 **debug APK** artifact 約 7 天供抽查）、`flutter pub get --enforce-lockfile`
- 對 `main` 的 PR 另跑依賴審查：`.github/workflows/dependency-review.yml`（僅在依賴相關檔案變更時觸發；也可手動觸發；需啟用 [Dependency graph](https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/about-the-dependency-graph)）
- 依賴更新：`.github/dependabot.yml` 每週檢查 **GitHub Actions** 與 **pub**（`pubspec.yaml`），並以 **groups** 盡量合併為較少筆 PR
- PR 標籤：`.github/workflows/pr-labeler.yml` 依路徑自動加上 `ci` / `docs` / `dependencies` / `android` / `ios` / `flutter`
- Label 同步：`.github/workflows/labels-sync.yml` 會自動建立/更新上述 labels（可手動觸發）
- Meta lint：`.github/workflows/meta-lint.yml` 會檢查 workflow 語法（actionlint）與 `tool/*.sh`（shellcheck）
- 安全性回報：見 `SECURITY.md`
- **Artifacts**（在 Actions 單次 run 頁面下載）：`coverage-lcov`（`lcov.info`）、`app-debug-apk`（CI 產生的 debug APK，預設約保留 7 日，非上架包）
- Workflow 入口（可直接查看）：[Flutter CI](https://github.com/Tasmaniancherries/liuban/actions/workflows/flutter.yml) / [Dependency review](https://github.com/Tasmaniancherries/liuban/actions/workflows/dependency-review.yml) / [Meta lint](https://github.com/Tasmaniancherries/liuban/actions/workflows/meta-lint.yml)

若 **Build Android APK** 失敗且訊息與 **NDK／CMake／platform** 相關，請對照 `.github/workflows/flutter.yml` 內 `setup-android` 的 `packages`（需與你使用的 Flutter stable 預設 `compileSdk`／`ndkVersion` 一致），或把該 job 的完整 log 附在 Issue／PR。

## 協作流程

- Issue：使用 `.github/ISSUE_TEMPLATE/` 內建模板
- PR：使用 `.github/pull_request_template.md`
- 參與開發：見 `CONTRIBUTING.md`
- 編輯器慣例：見專案根目錄 `.editorconfig`；使用 VS Code 時可參考 `.vscode/extensions.json` 建議的 Dart/Flutter 擴充
- Code owners：見 `.github/CODEOWNERS`
- 建議每個 PR 專注單一主題，並附上測試計畫

## 上架提醒

- **iOS**：Apple Developer 帳號、App Store Connect、隱私政策與 UGC／舉報說明。
- **Android**：Google Play 帳號、資料安全表單、同樣需隱私與 UGC 政策。

## 授權

本專案為**專有軟體**：見專案根目錄 `LICENSE`（All Rights Reserved）。若你未取得著作權人書面許可，不得任意使用、重製或散布程式碼。
