# 留伴 App — 廣場／好友／推廣／客服 API 契約

[← 文件索引](README.md)

基底 URL、`API_PREFIX`、錯誤 JSON（`message` / `detail` / `code`）、**`Authorization: Bearer` 標頭**、**TokenPair 回應**與 **401／refresh** 行為同 [認證契約](backend_auth_contract.md)。下文路徑皆相對於 `{API_PREFIX}`。

---

## 列表回傳包裝

客戶端 [`asJsonObjectList`](../lib/data/models/json_utils.dart) 支援三種形狀（擇一即可）：

| 形狀 | 說明 |
|------|------|
| JSON 陣列 | `[ { ... }, ... ]` |
| 物件內 `items` | `{ "items": [ ... ] }` |
| 物件內 `data` | `{ "data": [ ... ] }` |

---

## 路徑參數與 URL 編碼

路徑中的資源 ID（或私訊對象 ID 等），客戶端以 **`Uri.encodeComponent`** 編碼後置入 URL；後端應對**單一路徑段**做 percent-decode 再查庫。JSON body 內之 `target_custom_id`、`user_id` 等不在此列。

| 區域 | 方法 | 路徑樣式 | 編碼之參數 |
|------|------|----------|------------|
| Feed | GET / PATCH / POST / DELETE | `…/feed/posts/{id}`（含 `…/report`） | 動態 `id` |
| Friends | POST | `…/friends/requests/{requestId}/respond` | `requestId` |
| Friends | GET / POST | `…/friends/dm/{peerId}/messages` | `peerId` |
| Promotions | GET | `…/promotions/{id}` | `id` |

---

## 廣場動態（Feed）

實作：`lib/data/api/feed_api.dart`  
單筆模型：[FeedPostDto](../lib/data/models/feed_post_dto.dart)（欄位見下表）。

### `GET …/feed/public`

公開廣場列表（訪客通路上客戶端亦會請求；後端可依政策決定是否強制 Bearer）。

**Query**

| 參數 | 預設 | 說明 |
|------|------|------|
| `page` | `1` | 分頁 |
| `page_size` | `20` | 每頁筆數 |

**Response（200）**：動態列表 → [FeedPostDto](#feedpost-json-欄位)。

---

### `GET …/feed/school`

本校可見動態。通常需 **已登入且通過身分審核**；實際授權以後端為準。

**Query**：同 `feed/public`。

**Response**：同上。

---

### `GET …/feed/friends`

雙向好友動態。**Query**、**Response** 同上。

---

### `GET …/feed/posts/{id}`

單篇動態。`{id}` 會經 URL encode（客戶端使用 `Uri.encodeComponent`）。

**Response（200）**：單一物件 → [FeedPostDto](#feedpost-json-欄位)。

---

### `POST …/feed/posts`

發佈動態（需 Bearer，且須符合發佈權限）。

**Body（JSON）**

| 欄位 | 類型 | 說明 |
|------|------|------|
| `body` | string | 正文 |
| `audience` | string | 可見範圍；目前 App 傳值見下表（與 `lib/features/feed/post_models.dart` 之 `PostAudience.apiValue` 一致） |
| `hide_school` | bool | 是否對同校隱藏學籍相關展示等（與 PRD 一致） |

**`audience` 枚舉（建議後端與列表／詳情回傳一致）**

| 值 | 意義（App 標籤） |
|----|------------------|
| `public` | 公開廣場 |
| `school` | 本校同學 |
| `friends` | 雙向好友 |
| `private` | 僅自己 |

解析列表與詳情時，App 以 [postAudienceFromApiValue](../lib/features/feed/post_models.dart) 還原；未知值視為無法對應之可見範圍（UI 顯示原始字串或預設）。

**Response（200）**：完整 [FeedPostDto](#feedpost-json-欄位)。若 body 為空或空 object，客戶端會以請求內容組最小可用 DTO（後端仍建議回完整資源）。

---

### `PATCH …/feed/posts/{id}`

更新本人動態。**Body** 與 `POST …/feed/posts` 相同。

---

### `POST …/feed/posts/{id}/report`

檢舉動態。

**Body（JSON）**：可選 `reason`（string）。App 內建分類會送出短代碼 `spam`、`harassment`；使用者選「其他」且填寫補充說明時，客戶端以 `other — {說明}` 形式併為單一字串（說明欄最多 480 字元；後端請以一般字串處理即可）。客戶端另以 **512** 字元為 `reason` 總長防禦上限，超長則不送出請求。

**Response**：204 或 200 空 body 皆可（客戶端目前不解析 body）。

---

### `DELETE …/feed/posts/{id}`

刪除本人動態。若後端改為 `POST …/delete` 等，需同步改 App。

---

### FeedPost JSON 欄位

客戶端解析優先序如下（略列主欄位）：

| JSON 欄位 | 說明 | 別名（客戶端相容） |
|-----------|------|---------------------|
| `id` | 動態 ID | — |
| `author_id` | 作者內部 ID | — |
| `author_display` | 顯示名稱 | `author` |
| `body` | 內文 | `content` |
| `created_at` | 建立時間（字串） | — |
| `audience` | 可見範圍 | — |
| `hide_school` | bool | — |

---

## 好友與私訊（Friends）

實作：`lib/data/api/friends_api.dart`。

### `GET …/friends/inbox`

好友會話列表（最後預覽）。

**Response（200）**：[FriendInboxItemDto](#friendinboxitem-json-欄位) 列表。

---

### `POST …/friends/requests`

發出好友申請。

**Body**：`target_custom_id`（string，對方自訂 ID）。

---

### `GET …/friends/requests/incoming`

待我處理的申請。

**Response（200）**：[FriendRequestDto](#friendrequest-json-欄位) 列表。

---

### `POST …/friends/requests/{requestId}/respond`

接受或拒絕。路徑中的 `{requestId}` 客戶端會以 **`Uri.encodeComponent`** 編碼後代入（與單篇動態 `GET …/feed/posts/{id}` 一致）；後端應對路徑段做對應解碼。

**Body**：`accept`（bool）。

---

### `GET …/friends/requests/outgoing`

我發出的申請。

**Response（200）**：[FriendOutgoingRequestDto](#friendoutgoingrequest-json-欄位) 列表。

---

### `GET …/friends/dm/{peerId}/messages`

與指定好友的私訊列表（HTTP 拉取）。`peerId` 經 URL encode。

**Response（200）**：[DmMessageDto](#dmmessage-json-欄位) 列表。

---

### `POST …/friends/dm/{peerId}/messages`

送出私訊。

**Body**：`text`（string）。客戶端以 **500** 字元為 `text` 防禦上限，超長則不送出請求。

---

### `POST …/friends/blocks`

屏蔽使用者。

**Body**：`user_id`（string）。

---

### `GET …/friends/blocks`

已屏蔽列表。

**Response（200）**：[BlockedUserDto](#blockeduser-json-欄位) 列表。若單筆格式不符，客戶端可能得到空列表（見實作）。

---

### `POST …/friends/blocks/remove`

解除屏蔽。

**Body**：`user_id`（string）。

---

### FriendInboxItem JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `peer_id` | 對方使用者 ID | `user_id` |
| `peer_custom_id` | 對方 @ 代號 | `custom_id`, `username` |
| `last_message` | 最後預覽字串 | `preview` |
| `updated_at` | 可選 | — |

---

### FriendRequest JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `id` | 申請 ID | — |
| `from_custom_id` | 申請人 | `requester_custom_id` |
| `created_at` | 可選 | — |

---

### FriendOutgoingRequest JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `id` | — | — |
| `to_custom_id` | 對象 | `target_custom_id` |
| `status` | 如 `pending` / `accepted` / `rejected` | 預設 `pending` |
| `created_at` | 可選 | — |

---

### DmMessage JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `id` | — | — |
| `body` | 文字 | `text`, `content` |
| `is_mine` | 是否為目前使用者送出 | `mine` |
| `created_at` | 可選 | — |

---

### BlockedUser JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `user_id` | — | `id` |
| 顯示用 | — | `custom_id`, `display`, `label` → `displayLabel` |

---

## 推廣（Promotions）

實作：`lib/data/api/promotion_api.dart`，模型 [PromotionDto](../lib/data/models/promotion_dto.dart)。

### `GET …/promotions`

已上線推廣列表。

**Response（200）**：`PromotionDto` 列表。

---

### `GET …/promotions/{id}`

單篇詳情。路徑中的 `{id}` 客戶端以 **`Uri.encodeComponent`** 編碼（與 `GET …/feed/posts/{id}` 一致）；後端應對路徑段解碼。

**Response（200）**：單一物件。

### Promotion JSON 欄位

| JSON 欄位 | 說明 | 別名 |
|-----------|------|------|
| `id` | — | — |
| `title` | — | — |
| `subtitle` | — | `source` |
| `published_at` | — | `date` |
| `body` | 正文 | `content` |

---

## 官方客服（Support）

實作：`lib/data/api/support_api.dart`。

### `POST …/support/messages`

訪客亦可呼叫（客戶端會傳裝置／訪客識別相關 token，便於後端併對話）。

**Body（JSON）**

| 欄位 | 必填 | 說明 |
|------|------|------|
| `text` | 是 | 使用者留言（客戶端防禦上限 **500** 字元，超長不送出） |
| `guest_token` | 否 | 訪客或未登入時識別 |
| `contact_hint` | 否 | 聯絡方式提示 |

**Response**：200 即可；客戶端不解析 body。

---

## 變更流程

與認證契約相同：調整路徑或欄位時，先更新本文與對應 `lib/data/api/*.dart`、`lib/data/models/*.dart`，並在 PR 註明是否 breaking change。
