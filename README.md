# 留伴（Liuban）

在港留學生社交應用 — 使用 **Flutter** 同時支援 **iOS** 與 **Android**。

## 環境準備

1. 安裝 [Flutter SDK](https://docs.flutter.dev/get-started/install)（穩定版）。
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

## 開發與測試

```bash
flutter pub get
dart analyze
flutter test
```

若要只跑單一測試檔：

```bash
flutter test test/unawaited_debug_test.dart
```

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

## GitHub 自動化

- 已提供 CI：`.github/workflows/flutter.yml`
- 觸發時機：對 `main` 的 push 與 pull request
- 內容：`dart analyze` + `flutter test`

## 協作流程

- Issue：使用 `.github/ISSUE_TEMPLATE/` 內建模板
- PR：使用 `.github/pull_request_template.md`
- 建議每個 PR 專注單一主題，並附上測試計畫

## 上架提醒

- **iOS**：Apple Developer 帳號、App Store Connect、隱私政策與 UGC／舉報說明。
- **Android**：Google Play 帳號、資料安全表單、同樣需隱私與 UGC 政策。

## 授權

專有軟體或未指定 — 依你方需要自行加上 `LICENSE`。
