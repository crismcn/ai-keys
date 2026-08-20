# AI Mails

一个简约、高级的邮箱与激活管理应用。支持导入邮箱账号、查看收取到的邮件、以及一键串行执行「发码 → 收码 → 注册 → 认证」的真实激活流程。

- 浅色 / 深色 / 跟随系统 三套主题
- 卡片化布局、柔和阴影、轻量动效、全局禁用滚动回弹
- 轻量多语言架构（当前内置简体中文）
- 全部流程由真实后端接口驱动（见 [API.MD](API.MD)）

---

## 目录

- [功能](#功能)
- [技术栈](#技术栈)
- [开发环境](#开发环境)
- [在模拟器上运行](#在模拟器上运行)
- [打包 Release APK](#打包-release-apk)
- [激活流程说明](#激活流程说明)
- [API 接口](#api-接口)
- [主题与国际化](#主题与国际化)
- [网络代理说明（开发用）](#网络代理说明开发用)

---

## 功能

### 邮箱（首页）

- 顶部大标题 **AI Mails** + 「导入邮箱」按钮。
- 两张统计卡片：**邮箱数量** / **已激活数量**。
- **邮箱列表**：分页展示（每页 12 条），下拉刷新、上拉加载；支持按邮箱或密码实时搜索。
- 每个邮箱项显示圆形字母头像、账号（邮箱前缀）、掩码密码、状态点（绿=可用 / 灰=未激活）；点击整行进入邮件列表，左滑出现删除（二次确认）。
- 右侧「激活」按钮进入激活详情页（仅未激活邮箱显示，已激活邮箱不显示）。

### 邮件列表

- 展示该邮箱收取到的邮件（分页，每页 10 条）。
- 未读邮件加粗 + 主色未读圆点；**点击邮件**查看正文详情（底部抽屉弹窗）并**标记已读**。
- 已读标记以 `md5(邮箱 + 邮件时间)` 为稳定键持久化，重新入列表能正确回填。
- 空态、加载态、网络失败「重试」均有覆盖。

### 导入邮箱

- 支持**拖拽 / 点击上传 CSV**，或**粘贴文本**。
- 字段格式（以 `----` 分隔）：

  ```
  邮箱----密码----client_id----refresh_token----创建时间
  user1@example.com----123456----xxxx----xxxx----2024-01-01 10:00:00
  ```

- 展示字段对照表与字数计数；导入完成进入**导入成功页**（统计新增 / 更新 / 失败 / 可用，带庆祝动效）。

### 激活详情

- 进入页面即**自动触发**真实激活流程，四步时间线由后端接口串行驱动，非模拟计时：
  1. **发送验证码阶段** → 向邮箱下发验证码。
  2. **收取验证码阶段** → 每 5 秒轮询收件（约 5 分钟），只接受晚于进入本页时间的「CUN.AI邮箱验证邮件」，提取 6 位验证码。
  3. **脚本注册阶段** → 提交邮箱 / 用户名 / 密码 / 验证码完成注册。
  4. **激活认证阶段** → 每 5 秒轮询（约 5 分钟），找到 `Verify your email to claim…` 邮件并提取认证链接。
- 认证链接卡片：点击进入**应用内 WebView** 完成认证；右侧**复制按钮**可将链接写入剪贴板。
- 任一步网络 / 后端失败 → 该步进入**失败态**（红色叉号 + 错误文案 + 重试），重试从该步继续。
- 认证成功播放彩色纸屑（confetti），返回列表后该邮箱变为「可用」。

### 设置

- 外观：浅色 / 深色 / 跟随系统。
- 语言：简体中文（English 预留）。
- 关于：版本号。

---

## 技术栈

- **[Dart Flutter](https://dart.dev)**（Material 3 风格的 Flutter 窗口组件库）
- Dart 3.13 SDK，`flutter` 工具链
- 依赖：`provider`（DI / ChangeNotifier）、`shared_preferences`（本地持久化）、`http`（网络）、`crypto`（md5）、`webview_flutter`（认证 WebView）、`file_picker`（CSV 导入）、`cupertino_icons`、`flutter_localizations`

---

## 开发环境

- Android 模拟器（`emulator-5554`）为当前开发目标；工程同时包含 iOS / Android 全平台构建配置。

## 在模拟器上运行

1. `flutter pub get`（首次拉取包），解析依赖。
2. 运行 `flutter run -d emulator-5554`，全量安装到模拟器。

> 注意：后台 `flutter run` 在安装完成后会脱离（日志出现 `Lost connection to device`），**热重载不会作用到已脱离的进程**——每次改代码后需重新安装才能看到改动。

## 打包 Release APK

打包 release APK（默认即 release 模式）：

```bash
flutter build apk --release

flutter build apk --release --split-per-abi
```

产物位于 `build/app/outputs/flutter-apk/` 下的 release APK；如需符号化堆栈，搭配 `--debug-info=<dir>`（见 `flutter build apk --help`）。debug 构建可用 `--debug`。

---

## 激活流程说明

激活会**真实调用外部接口并真实创建账号**：

- 向 `www.cun.ai` 发送验证码并提交注册（邮箱 / 用户名 / 密码 / 验证码会被上送）。
- 把邮箱的 `refresh_token / client_id` 上送给 `yovianna.com` 用于收取邮件。
- `turnstile`（人机验证）当前传空字符串。

任一步失败都会停留对应步骤并给出可重试的失败态，不自动推进后续步骤。

---

## API 接口

| #   | 阶段       | 方法 / 地址                                                               | 说明                                                         |
| --- | ---------- | ------------------------------------------------------------------------- | ------------------------------------------------------------ |
| 1   | 发送验证码 | `GET https://www.cun.ai/api/verification`                                 | query `{email, turnstile:""}`                                |
| 2   | 邮件列表   | `POST https://yovianna.com/api/imap/fetch_emails`                         | 收取验证码阶段每 5s 轮询                                     |
| 3   | 邮件详情   | `POST https://yovianna.com/api/imap/fetch_email_detail`                   | 读取正文提取验证码 / 认证链接                                |
| 4   | 注册       | `POST https://www.cun.ai/api/user/register`                               | body 含 email/username/password/message_id/verification_code |
| 5   | 认证链接   | 轮询 fetch_emails 找 `Verify your email to claim…` 邮件 → detail 提取链接 | 每 5s 轮询                                                   |

完整字段见 [API.MD](API.MD)。

---

## 主题与国际化

- **主题**：`app/lib/core/theme/app_palette.dart` 用 `ThemeExtension` 提供 `context.c` 语义色；`AppColors` 为品牌色常量（主色 `#3B6EF5`、成功 `#22C55E`、失败 `#EF4444`）。`app/lib/app/theme/app_theme.dart` 定义浅 / 深两套；设置页切换后经 `SettingsController` 持久化。
- **国际化**：`app/lib/core/l10n/app_strings.dart` 集中词条表，通过 `context.s` 访问；`SettingsController.strings` 决定当前语言。新增语言只需补一份词条。

---

## 代理说明（开发用）

开发和真机联调时，若宿主机网络需经代理（如 Clash），而模拟器又无法直接解析被污染 DNS 的目标域名（如 `www.cun.ai`），可用应用层代理绕过：

```bash
flutter run -d emulator-5554 --dart-define=DEV_PROXY=10.0.2.2:7897
```

- `DEV_PROXY` 为空时（常规发布），不安装任何代理，生产代码不受影响。
- 端口以宿主机实际 Clash 端口为准（示例 `7897`）。

---

本仓库共三份并行的设计 / 接口文档，保持一致：

- [PRODUCT.MD](PRODUCT.MD) — 产品说明与设计规范
- [API.MD](API.MD) — 激活 / 邮件后端接口约定
- [README.MD](README.MD) — 本项目工程说明（本文档）
