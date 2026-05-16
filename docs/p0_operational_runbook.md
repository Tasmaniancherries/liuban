# P0 上线阻塞项执行手册

本手册对应 `release_readiness_checklist.md` 中的 **P0**，供研发、测试、产品在发版前逐项签收。客户端仓库内可自动验证项见文末「仓库内自动化」。

---

## 1. 双平台真机回归（iOS / Android）

**负责人**：测试（主）+ 研发（支持）  
**建议时长**：各平台 0.5～1 天  
**构建产物**：与发布渠道一致的 **Release** 包（勿仅用 debug 包签收）

### 1.1 准备

- [ ] 确认 `AppConfig` / `dart-define` 指向**预发或生产** API（非本机 mock）
- [ ] 准备至少 2 台 iOS、2 台 Android 真机（含不同系统大版本）
- [ ] 准备测试账号：访客、审核中、已认证、含好友关系各一

### 1.2 主路径用例（每平台必跑）

| # | 场景 | 通过 | 备注 |
|---|------|------|------|
| 1 | 冷启动 → 广場 Tab 加载 / 空态 / 错误提示 | | |
| 2 | 注册 + 上传证件 → 审核中状态 | | |
| 3 | 登录 → 个人页同步审核状态 | | |
| 4 | 发帖（公开 / 本校 / 好友可见各一次） | | |
| 5 | 动态详情、下拉刷新、本人删除 | | |
| 6 | 好友申请 → 同意 → 私讯收发 | | |
| 7 | 官方客服留言 | | |
| 8 | 推广列表 / 详情 | | |
| 9 | 设置：主题、语言、协议、屏蔽列表 | | |
| 10 | 深链接打开（登录、动态、私讯、重设密码） | | |
| 11 | 弱网：飞行模式 → 空态 + 可重试 | | |

### 1.3 签收

- [ ] 无 P0 级崩溃、无白屏、无「示例 / 占位数据」误展示
- [ ] 签字：测试 ______ 日期 ______

---

## 2. 后端联调签收

**负责人**：后端（主）+ 研发（客户端）  
**依赖**：预发 / 生产 API 可用，测试账号与数据已准备

### 2.1 契约对齐

- [ ] 客户端 `docs/backend_auth_contract.md`、`docs/backend_domain_apis_contract.md` 与当前后端实现一致
- [ ] 客户端 `LiubanInputLimits` 与契约中的「客户端防禦上限」一致

### 2.2 场景矩阵（每项：成功 / 4xx 业务错误 / 超时）

| 域 | 接口示例 | 成功 | 失败文案 | 空数据 |
|----|----------|------|----------|--------|
| Auth | login, register, refresh, me/verification | | | |
| Feed | public/school/friends, POST/PATCH post, report | | | |
| Friends | requests, inbox, dm messages, blocks | | | |
| Promotion | list, detail | | | |
| Support | messages | | | |

### 2.3 签收

- [ ] 后端确认生产环境配置（CORS、证书、限流、邮件重设）已就绪
- [ ] 签字：后端 ______ 客户端 ______ 日期 ______

---

## 3. 崩溃与错误监控接入

**负责人**：研发（主）+ 运维  
**当前仓库状态**：已集成 **Firebase Crashlytics**（`firebase_core` / `firebase_crashlytics`）；发版前需完成 Firebase 项目配置并验证控制台可见崩溃。见 [firebase_crashlytics_setup.md](firebase_crashlytics_setup.md)。

### 3.1 推荐方案（二选一）

1. **Firebase Crashlytics**（移动端常见，与商店分发配合方便）
2. **Sentry**（Flutter 支持成熟，便于关联 release 版本）

### 3.2 接入验收

- [ ] Release 包在监控后台可见 **versionName / buildNumber**（与 `pubspec.yaml` 一致）
- [ ] 人为触发一次测试崩溃或测试异常，平台能收到事件
- [ ] 符号表 / dSYM / mapping 上传流程已写入 CI 或发版文档
- [ ] 隐私政策已说明崩溃数据收集（若采集）

### 3.3 签收

- [ ] 监控仪表盘链接：________________
- [ ] 签字：研发 ______ 日期 ______

---

## 4. 发布构建链路验证

**负责人**：研发 / CI  
**仓库内命令**：

```bash
dart format .
make ci-quality    # 单测 + analyze + coverage
make ci-smoke      # web release + Android debug APK（烟测）
```

### 4.1 iOS（需在 macOS + Xcode 环境执行）

```bash
flutter build ipa --release
# 或 flutter build ios --release 后在 Xcode Archive
```

- [ ] 证书与 Provisioning Profile 有效
- [ ] Archive 成功，TestFlight 可安装

### 4.2 Android

```bash
flutter build appbundle --release
# 或 flutter build apk --release
```

- [ ] 签名 keystore 与 `key.properties` 配置正确（勿提交密钥仓库）
- [ ] AAB 可上传 Play Console 内部测试轨道

### 4.3 版本号

- [ ] `pubspec.yaml` 中 `version: x.y.z+build` 与商店、监控后台一致
- [ ] 签字：研发 ______ 日期 ______

---

## 5. 隐私与合规入口检查

**负责人**：产品 + 法务（如有）

- [ ] 设置 →「協議與隱私」可打开且文案为当前运营方版本（非长期占位）
- [ ] 注册流程说明证件用途与审核说明清晰
- [ ] 相册 / 相机权限用途说明（注册上传）符合商店审核要求
- [ ] 签字：产品 ______ 日期 ______

---

## 仓库内自动化（研发本机可完成）

| 检查项 | 命令 | 最近一次 |
|--------|------|----------|
| 格式 + 单测 + 分析 | `make ci-quality` | 2026-05-15 已通过（含 `dart format .`） |
| 编译烟测 | `make ci-smoke` | Web release 已通过；Android 需本机配置 `ANDROID_HOME` 与 SDK 后重跑 |

完成 P0 后，在 `release_readiness_checklist.md` 中勾选对应项，并归档本手册签字页扫描件或 PR 评论链接。
