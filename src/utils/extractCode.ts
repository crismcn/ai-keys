/** 从邮件 HTML/正文中提取 6 位验证码 */

/** 优先标记：验证码为 / verification code */
const MARKERS = ['验证码为', 'verification code'] as const
/** 验证码为 6 位数字/字母组合（cun.ai 实测为字母数字混合，如 a8d1e3） */
const CODE_RE = /\b[a-zA-Z0-9]{6}\b/g

/**
 * 提取 6 位验证码（数字/字母组合）。
 * 规则：
 * 1. 找到最后一个出现验证码标记（验证码为 / verification code，忽略大小写）的位置
 * 2. 从该标记后取第一个独立的 6 位数字/字母（避免被其他流水号干扰）
 * 3. 无标记时，取全文最后一个 6 位独立数字/字母（即「最新匹配项」）
 * 4. 无候选返回 null
 */
export function extractVerificationCode(html: string): string | null {
  const { lastMarkerEnd } = findLastMarker(html)

  if (lastMarkerEnd >= 0) {
    // 剥掉标签后、在首个标点/换行边界内取首个独立 6 位数字/字母
    // （验证码通常紧跟标记出现；远处流水号/参考编号不应被误取）
    const text = html.slice(lastMarkerEnd).replace(/<[^>]*>/g, ' ')
    const boundary = text.search(/[。．.，,\n]/)
    const segment = boundary >= 0 ? text.slice(0, boundary) : text.slice(0, 80)
    const first = segment.match(CODE_RE)
    return first ? (first[0] ?? null) : null
  }

  const all = html.match(CODE_RE)
  return all && all.length > 0 ? (all[all.length - 1] ?? null) : null
}

/** 返回最后一个标记的结束位置；无标记时返回 -1 */
function findLastMarker(html: string): { lastMarkerEnd: number } {
  const lower = html.toLowerCase()
  let lastEnd = -1
  for (const marker of MARKERS) {
    const idx = lower.lastIndexOf(marker)
    if (idx >= 0) {
      const end = idx + marker.length
      if (end > lastEnd) lastEnd = end
    }
  }
  return { lastMarkerEnd: lastEnd }
}