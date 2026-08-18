/** 从邮件 HTML/正文中提取认证链接 */

const URL_RE = /https?:\/\/[^\s"'<>\\]+/g
/** 认证链接关键词，按优先级依次尝试 */
const AUTH_KEYWORDS = ['verify', 'auth', 'claim', 'activate'] as const

/**
 * 提取认证地址：
 * 1. 收集所有 http(s) 链接
 * 2. 优先返回含 verify/auth/claim/activate 关键词的链接
 * 3. 否则返回首个链接；无链接返回 null
 */
export function extractAuthUrl(text: string): string | null {
  const urls = (text.match(URL_RE) ?? [])
    .map(cleanUrl)
    .filter((u): u is string => u.length > 0)
  if (urls.length === 0) return null

  const lowers = urls.map((u) => u.toLowerCase())
  for (const keyword of AUTH_KEYWORDS) {
    const hit = urls.find((_, i) => lowers[i]!.includes(keyword))
    if (hit) return hit
  }
  return urls[0] ?? null
}

/** 去掉 URL 尾部的中英文标点与无关字符 */
function cleanUrl(url: string): string {
  return url.replace(/[^A-Za-z0-9_\-/:%?&=._~+#@]*$/, '')
}