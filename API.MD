# 1. 请求验证码(发送验证码阶段)

Method: GET
Url: https://www.cun.ai/api/verification
query: { email: "所选的邮箱", turnstile: "" }

Response: { "message": "", "success": true }

# 2. 查邮件列表（收取验证码阶段 30秒轮训一次）

Method: POST
Url: https://yovianna.com/api/imap/fetch_emails
body: {
"email": "所选的邮箱",
"refresh_token": "导入邮箱时的字段",
"client_id": "导入邮箱时的字段",
"auth_method":"auto",
"folder":"inbox",
"page":1,
"page_size":10
}

Response: {
"email_id": "nubqmozjjfx@outlook.com",
"emails": [
{
"message_id": "INBOX-5",
"folder": "INBOX",
"subject": "[GitHub] A third-party OAuth application has been added to your\r\n account",
"from": "GitHub <noreply@github.com>",
"date": "2026-08-19T18:34:07-07:00",
"is_read": false
}
],
"has_more": false,
"total": 5
}

# 3. 查邮件详情（收取验证码阶段）

Method: POST
Url: https://yovianna.com/api/imap/fetch_email_detail
body: {
"email": "所选的邮箱",
"refresh_token": "导入邮箱时的字段",
"client_id": "导入邮箱时的字段","message_id":"INBOX-5",
"folder":"inbox"
}

Response: {
"message_id": "", // 从列表接口响应中获取
"subject": "[GitHub] A third-party OAuth application has been added to your\r\n account",
"from": "GitHub <noreply@github.com>",
"to": "nubqmozjjfx <nubqmozjjfx@outlook.com>",
"date": "2026-08-19T18:34:07-07:00",
"body": "Hey nubqmozjjfx!\r\n\r\nA third-party OAuth application (gorouter) with user:email scopes was recently authorized to access your account.\r\nVisit https://github.com/settings/connections/applications/Ov23lipc1Ups6bRqeQYE for more information.\r\n\r\nTo see this and other security events for your account, visit https://github.com/settings/security-log\r\n\r\nIf you run into problems, please contact support by visiting https://github.com/contact\r\n\r\nThanks,\r\nThe GitHub Team",
"html": ""
}

# 4. 注册接口（脚本注册阶段）

Method: POST
Url: https://www.cun.ai/api/user/register
body: {
"email": "所选的邮箱",
"username": "导入邮箱时的字段",
"password": "导入邮箱时的字段",
"message_id": "INBOX-5",
"verification_code": "", // **验证码邮件**：`subject == "CUN.AI邮箱验证邮件"` → 详情 HTML 中提取验证码
"utm_source": "linuxdo", // 固定
"utm_medium": "free", // 固定
"turnstile": ""
}

# 5. 注册提交后获取认证链接（激活认证阶段）

5.1 30秒轮训一次邮件列表接口里寻找：subject 以 `Verify your email to claim` 开头（完整形似 `Verify your email to claim $x.xxx 额度 credits on CUN.AI`）
5.2 邮件详情接口中获得认证地址
