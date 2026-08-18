# CUN.AI 注册机（Node.js + TypeScript）

自动完成 **CUN.AI** 邮箱验证注册的脚本/CLI：请求验证码 → 轮询 yovianna 邮箱收件 → 从邮件 HTML 提取 6 位验证码 → 提交注册 → 轮询认证邮件并请求其中的认证地址 → 将成功账号写入 `ACCOUNT.MD`。支持单账号与批量（并发控制）两种模式。

完整规格与接口细节见 [docs/cun-ai-register-spec.md](docs/cun-ai-register-spec.md)。**文档与代码不一致时以代码为准，并回写文档。**

## 技术基线

- Node.js 18+ / 20+；TypeScript；`npm` scripts：`dev`/`build`/`start`
- HTTP：内置 `fetch` 或 axios；日志：winston / pino；配置：JSON 文件 + dotenv
- 目录结构沿用规格文档 6.2 节（`src/` 布局）；模块单一职责，失败可独立排查

## 实现前必读的关键事实

### 端点

| 动作 | 请求 |
|---|---|
| 请求验证码 | `GET https://www.cun.ai/api/verification`，query：`email`、`turnstile` |
| 提交注册 | `POST https://www.cun.ai/api/user/register`，body：`username`、`password`、`email`、`verification_code`、`aff_code`、`turnstile` |
| 查邮件列表 | `POST https://yovianna.com/api/imap/fetch_emails`，body：`email`、`refresh_token`、`client_id`、`auth_method`、`folder`、`page`、`page_size` |
| 查邮件详情 | `POST https://yovianna.com/api/imap/fetch_email_detail`，body：`email`、`refresh_token`、`client_id`、`message_id`、`folder` |

- `username` = 邮箱 `@` 之前的部分
- 邮箱凭证（`email` / `refresh_token` / `client_id`）一律来自账号池配置文件，不硬编码

### 邮件主题筛选（两个阶段）

1. **验证码邮件**：`subject == "CUN.AI邮箱验证邮件"` → 详情 HTML 中提取验证码
2. **认证邮件**：subject 以 `Verify your email to claim` 开头（完整形似 `Verify your email to claim $3.000000 额度 credits on CUN.AI`）→ 详情中获得认证地址并请求之

> 注意：认证主题中美元符号曾记为全角 `＄`，请用**前缀/包含匹配**而非全等，避免特殊字符差异导致漏匹配。

### 轮询策略

- 间隔 60 秒（规格允许 30~60s），最长等待 5 分钟
- 按时间倒序取最新一封；超时仍未命中 → 抛可识别错误（如 `EMAIL_TIMEOUT`）
- 轮询的是两阶段邮件，各一次独立轮询

### 网络与代理（实测必需）

- `cun.ai` 需要直连可达或**走代理**；Node 全局 `fetch` **不读系统代理**，`httpClient` 已自动读取 env `HTTPS_PROXY`/`HTTP_PROXY`/`ALL_PROXY`，或 macOS `scutil --proxy` 系统代理（例如 Clash 127.0.0.1:7897），注入 undici ProxyAgent
- 单测注入假 fetch，不会触发代理探测；代理异常时忽略代理直连（更友好）
- 外部接口超时默认 30s；可恢复错误按 1s/2s/4s/8s 退避重试（见红线 3）

## 文件与数据

- 账号池（**真实数据，git 已忽略**）：仓库根目录 `EMAILS.JSON`，结构 `{ email, password, client_id, refresh_token, registered_at }`；批量数据样例在 `ignore/` 下，同样忽略
- 输出文件：根目录 `ACCOUNT.MD`（含 username/email/password，git 已忽略）
- 验证码提取：优先搜 `验证码为` 或 `verification code`，`[a-zA-Z0-9]{6}` 取最新匹配（实测为字母+数字混合，如 `a8d1e3`，非纯数字）

## 红线（不可违反）

1. 严禁在日志、输出、提交内容中打印/包含 `refresh_token`、`password`、邮件正文全文
2. **真实账号注册是对外动作**：未获用户明确同意不得注册。代码已内置保护——CLI 默认 **DRY-RUN**，需显式 `--live` 才真正发送注册/认证请求
3. 所有外部接口必须设超时；可恢复错误按 1s/2s/4s/8s 退避重试，最多 3~5 次
4. 不得把 `EMAILS.JSON`、`ignore/`、`.env`、`ACCOUNT.MD` 加进 git（见 `.gitignore`）
5. 批量并发要限速，避免触发目标平台风控

## 工程结构与命令

- `src/utils/`：`extractCode`（验证码）、`extractAuthUrl`（认证链接）、`retry`（退避重试）、`pickEmail`（最新邮件）、`logger`（脱敏日志）、`subjects`（主题匹配）、`accountFile`（写 ACCOUNT.MD）
- `src/services/`：`verificationService` / `emailService` / `registerService`（注入 `HttpClient`），`httpClient`（超时+错误映射+**自动代理**）、`emailParsers`（响应解析）
- `src/app/`：`index.ts`（单账号 CLI）、`scheduler.ts`（批量）、`flow.ts`（流程编排）、`cliArgs.ts`（参数解析）
- `src/errors.ts`：统一错误码与可重试标记；`src/config/`：`accounts`（账号池校验）、`constants`（端点/主题/轮询默认值）

## 常用任务速查

- 单账号 **DRY-RUN**（走完整流程、不真实注册）：`npm run dev`
- 单账号真实注册（红线，需手动确认）：`npm run dev -- --live`
- 指定邮箱 / 传参（turnstile、aff_code）：`npm run dev -- --email a@outlook.com --turnstile <t> --aff-code <r>`
- 批量注册（默认 dry-run，`--concurrency` 限速）：`npm run dev:batch -- --concurrency 3 [--live] [--email-filter?]`
- 跑测试：`npm test`；构建：`npm run build`；启动构建产物：`npm start`
- 排查验证码提取失败：先看日志中的 subject 与正文长度（**不打印正文**），再核对 `extractCode` 正则
- 改动接口字段：同步更新规格文档第 4 节与本文档端点表