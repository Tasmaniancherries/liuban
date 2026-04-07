# 留伴 App — 認證與身分審核 API 契約

[← 文件索引](README.md)

客戶端實作見 `lib/data/api/auth_api.dart`、`lib/core/network/token_refresh_interceptor.dart`。實際 URL 為：

`{API_BASE_URL}` + `{API_PREFIX}` + 下路徑（預設 prefix：`/v1`）。

---

## 共用約定

### Content-Type

| 端點類型 | Content-Type |
|-----------|----------------|
| JSON body | `application/json` |
| 註冊 | `multipart/form-data`（欄位見下） |

### 錯誤回應（建議）

客戶端 [LiubanApiException](../lib/core/network/api_exception.dart) 會讀取：

- JSON object 的 `message` 或 `detail`（優先 `message`）
- 可選 `code`（字串，供除錯或對應文案）

非 2xx 時應回可解析之 JSON 或純文字；避免回 HTML。

### HTTP 標頭慣例（客戶端）

[`DioClient`](../lib/core/network/dio_client.dart) 對 **Session Dio** 預設：

| 標頭 | 值 |
|------|-----|
| `Accept` | `application/json` |

當記憶體中存有 access token 時，[`_AuthInterceptor`](../lib/core/network/dio_client.dart) 會附帶：

```http
Authorization: Bearer <access_token>
```

- **`Bearer` 與 token 之間為單一空白**（ASCII 0x20）；token 字串**不**應再内含字面 `Bearer ` 前綴。
- 無 token 或已清空時，**不**送 `Authorization`（後端視為匿名／訪客請求）。

送 JSON body 的 `POST`／`PATCH` 等，由 Dio 為 `data` 帶上 `Content-Type: application/json`（與上文「共用 Content-Type」一致）。

### 受保護資源與 401

除後端明定**公開**或**訪客可呼叫**的路徑外，缺證、過期或簽章無效的 access 建議一律 **401**，body 仍建議含 `message`／`detail`（見錯誤約定）。

客戶端對下列路徑（或子字串）**不**在 401 時觸發 refresh 重試，以避免循環：`/auth/login`、`/auth/register`、`/auth/refresh`（見 [`TokenRefreshInterceptor`](../lib/core/network/token_refresh_interceptor.dart)）。

常見**可不帶 Bearer**或由後端寬鬆處理者（以產品為準）：`POST …/auth/register`、`POST …/auth/login`、忘記密碼相關、`POST …/auth/refresh`、`GET …/feed/public`、`GET …/promotions`、`POST …/support/messages` 等。

### Token 回應體（TokenPair）

發放存取憑證時，建議與 [TokenPairDto](../lib/data/models/token_pair_dto.dart) 及 [AuthSessionTokens](../lib/core/network/auth_session_tokens.dart) 對齊（登入、refresh、**可選**之註冊成功）。

| JSON 欄位 | 建議 | 說明 |
|-----------|------|------|
| `access_token` | 登入／refresh **成功時必填** | 用於此後 `Authorization: Bearer …`。客戶端相容讀取別名 **`token`**、**`accessToken`**（以上擇一還原即可） |
| `refresh_token` | **強烈建議** | 用於 `POST …/auth/refresh` 的 body；客戶端相容別名 **`refreshToken`**。若始終不提供，App 無法在 access 過期後自動換發 |

**儲存策略**：客戶端僅在 HTTP **標頭**帶 **access**；**refresh 只出現在** refresh 請求 **JSON body**，不放在 `Authorization`。

**註冊**：若回應含上述欄位則登入憑證一併寫入；若 body 空或無 token 欄位，客戶端不解析 TokenPair（帳戶階段仍可能為 `pending_verification`，見註冊一節）。

### 刷新流程（401 與 refresh）

1. Session Dio 請求得 **401** 且 path 非 login／register／refresh 時，若本地有 `refresh_token`，客戶端以 **另一路徑的 Dio 實例（無 Auth 攔截）** 呼叫 `POST …/auth/refresh`，body：`{"refresh_token":"…"}`，**不依賴** `Authorization` 標頭。
2. **200**：回應與登入相同之 TokenPair；客戶端更新記憶體 token，並以**新 access** 重試**原請求一次**。
3. Refresh **再失敗**或無 refresh：清空 token，將錯誤交還 UI（需重新登入）。
4. 後端請避免 refresh 端點在「必失敗」情境仍回 200；建議與一般受保護 API 一致回 **401** 以利客戶端清 session。

---

## `POST {API_PREFIX}/auth/register`

建立帳號並提交**身分審核**材料（擇一檔案類型）。

### Request（`multipart/form-data`）

| 欄位名 | 類型 | 必填 | 說明 |
|--------|------|------|------|
| `custom_id` | text | 是 | 使用者自訂代號（App 端會正規化為 `@` 開頭顯示，傳給後端是否含 `@` 請與後端統一） |
| `school_name` | text | 是 | 學校名稱 |
| `student_id` | text | 是 | 學號 |
| `verification_document_kind` | text | 是 | **`offer`** 或 **`student_id_card`**，須與下方檔案欄位一致 |
| `offer` | file | 條件 | 當 `verification_document_kind=offer` 時**必填**：Offer 或正式錄取證明圖片 |
| `student_id_card` | file | 條件 | 當 `verification_document_kind=student_id_card` 時**必填**：學生證照片（須可辨識學籍資訊） |

**不變條件：**

- `verification_document_kind === "offer"` 時，請求內必須包含 part `offer`，**不**應同時要求 `student_id_card`。
- `verification_document_kind === "student_id_card"` 時，必須包含 part `student_id_card`。
- 若 kind 與檔案欄位不符，建議回 **400** 與明確 `message`。

檔案格式建議接受常見圖片（如 JPEG、PNG）；單檔大小上限由後端定義並在錯誤訊息中可選說明。

### Response（200，JSON）

客戶端 [RegistrationResponse](../lib/data/models/registration_response.dart) 解析欄位：

| JSON 欄位 | 說明 |
|-----------|------|
| `access_token` | 可選。若註冊後直接發放登入憑證則填入（亦相容別名 `token`） |
| `refresh_token` | 可選 |
| `account_phase` 或 `phase` | 帳戶階段；未回時客戶端預設視為 `pending_verification` |

建議註冊成功後至少回：

- `account_phase`: **`pending_verification`**（已進入審核、尚未通過）

若回應 body 為空或空 object，客戶端亦會將階段當成 `pending_verification`。

---

## `GET {API_PREFIX}/auth/me/verification`

（需 Bearer）查詢目前身分審核狀態。

### Response（200，JSON）

[VerificationStateDto](../lib/data/models/verification_state_dto.dart)：

| JSON 欄位 | 說明 |
|-----------|------|
| `phase`（或 `account_phase`） | 客戶端對應見下 |
| `message` | 可選；給使用者或除錯用之說明 |

**`phase` 與 App 行為對齊**（`lib/core/session/verification_phase_mapper.dart`）：

| 後端 `phase` 值 | App `AccountPhase` |
|-----------------|---------------------|
| `verified_student` 或 `verified` | 已通過（正式學生權限） |
| `pending_verification` 或 `pending` | 審核中（與訪客類似之限制） |
| 其他或未辨識 | 訪客／未通過視角 |

後端新增狀態時，應同步更新此文檔與 mapper。

---

## `GET {API_PREFIX}/auth/me`

（需 Bearer）目前登入使用者之公開／個人檔案資料。客戶端模型：[UserProfileDto](../lib/data/models/user_profile_dto.dart)；學籍列元素：[EducationEntryDto](../lib/data/models/education_entry_dto.dart)。

### Response（200，JSON）

#### 頂層欄位

| JSON 欄位 | 說明 | 別名（客戶端相容） |
|-----------|------|---------------------|
| `id` | 使用者內部 ID | `user_id` |
| `custom_id` | 自訂代號（@ 顯示用） | `username`, `login` |
| `display_name` | 顯示名稱 | `nickname` |
| `educations` | 學籍條目陣列 | `schools`, `degrees`（三者擇一作為來源） |

`educations` 缺省或 null 時客戶端視為空列表。

#### `educations[]` 元素

| JSON 欄位 | 說明 | 別名／衍生 |
|-----------|------|------------|
| `school_short_name` | 學校簡稱（晶片文案用） | `school`, `name` |
| `alumni` | 是否校友 | `is_alumni`；或 `status` 為 `alumni` / `graduated` 時視為 true |

---

## `POST {API_PREFIX}/auth/login`

- Content-Type: `application/json`
- Body: `account`, `password`（名稱若調整需同步改 App）

### Response（200）

見上方 **「Token 回應體（TokenPair）」**：至少需有可用之 `access_token`（或別名）；建議併回 `refresh_token`。

---

## `POST {API_PREFIX}/auth/refresh`

- Content-Type: `application/json`
- Body: `refresh_token`（目前儲存之 refresh；與標頭無關，見 **「刷新流程」**）

### Response（200）

與 login **相同**之 TokenPair 欄位慣例；可旋轉 refresh（回新 `refresh_token`）或沿用舊值（客戶端若未收到新 refresh 會保留舊值，見攔截器實作）。

此路徑須列入 **不可對 401 再觸發 refresh 重試**之白名單（見 `token_refresh_interceptor.dart`）。

---

## `POST {API_PREFIX}/auth/password`（已登入改密）

Body：`current_password`, `new_password`。

---

## 密碼重置（未登入）

皆為 `Content-Type: application/json`，**不**帶 `Authorization`。

### `POST …/auth/password/reset/request`

**Body**

| 欄位 | 類型 | 說明 |
|------|------|------|
| `email` | string | 使用者帳號綁定之信箱（trim 後送出） |

**Response（建議）**

- **200**：一律成功回應（**不**因信箱是否存在而回不同狀態碼），body 可為空或僅訊息，避免枚舉註冊信箱。客戶端 [requestPasswordResetEmail](../lib/data/api/auth_api.dart) 目前不解析 body。
- **4xx/5xx**：客戶端以 [LiubanApiException](../lib/core/network/api_exception.dart) 顯示 `message`／`detail`。

### `POST …/auth/password/reset/complete`

**Body**

| 欄位 | 類型 | 說明 |
|------|------|------|
| `token` | string | 郵件連結或 deep link 帶入之一次性 token |
| `new_password` | string | 新密碼 |

**Response（建議）**

- **200**：重設成功；body 可空。
- **400**：token 無效或過期、密碼不合規範等，附 `message`。

信件／網頁連結建議導向 App deep link：`/reset-password?token=...`（與路由一致）。

---

## 相關文件

- [廣場／好友／推廣／客服 API](backend_domain_apis_contract.md)
- [文件索引](README.md)

---

## 版本與變更

契約變更時請：

1. 更新本檔與對應 Dart model／API。
2. 若為 breaking change，請註明版本或日期與相容策略（例如短暫接受舊欄位名）。
