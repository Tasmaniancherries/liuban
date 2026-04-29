# 後端 API 契約（索引）

與 Flutter 客戶端對齊的 REST 約定，依域拆成兩份主文件：

| 文件 | 內容 |
|------|------|
| [backend_auth_contract.md](backend_auth_contract.md) | 註冊（multipart）、登入、refresh、**TokenPair／Bearer 標頭**、401 刷新、`/auth/me`、`/auth/me/verification`、密碼與重設 |
| [backend_domain_apis_contract.md](backend_domain_apis_contract.md) | 廣場 Feed、`audience` 枚舉、路徑參數編碼、好友／私訊、推廣、客服 |
| [release_readiness_checklist.md](release_readiness_checklist.md) | 上線前檢查清單（P0/P1/P2 與最終核對） |
| [release_notes_launch_candidate.md](release_notes_launch_candidate.md) | 上線候選版本說明（面向產品／測試／運營） |
| [release_notes_public_short.md](release_notes_public_short.md) | 對外精簡更新公告（應用商店／社群可直接使用） |
| [release_execution_runbook.md](release_execution_runbook.md) | 發布執行順序（T-3 至 T+7 的角色與文檔對應） |
| [release_rollout_and_rollback_guide.md](release_rollout_and_rollback_guide.md) | 灰度放量與回滾判定指南（發布當天決策用） |

實作入口：`lib/data/api/*.dart`、[`lib/core/network/token_refresh_interceptor.dart`](../lib/core/network/token_refresh_interceptor.dart)。

畫面上功能／無障礙用 API 說明集中於 [`lib/core/ui/api_dev_semantics.dart`](../lib/core/ui/api_dev_semantics.dart)（含 `AppConfig.apiPrefix` 與 docs 尾註）。另含分享連結底部表、訪客鎖定層 hint。已接入之主要畫面含：登入／註冊、`AuthRequiredGate`（須登入門檻）、廣場與發佈／單篇、檢舉／屏蔽／刪除對話框、撰寫權限門檻頁、好友收件匣與私訊／申請、推廣列表與詳情、設定（協議與關於）、屏蔽列表、個人檔（含同步審核與除錯說明）、改密與重設密碼、客服、路由錯誤頁等。

變更 API 時請**先改契約與 Dart**，再在 PR 註明是否 breaking change。
