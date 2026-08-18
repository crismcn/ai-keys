import type { EmailMeta } from '../types.js'

/**
 * 从邮件列表中挑出符合 predicate 的最新一封。
 * 按收到时间倒序（兼容 ISO 与 "YYYY-MM-DD HH:mm:ss"）；
 * 无法解析日期的条目视为最旧，保持列表原始顺序。
 */
export function pickLatestEmail<T extends EmailMeta>(
  emails: T[],
  predicate: (email: T) => boolean,
): T | null {
  const hits = emails.filter(predicate)
  if (hits.length === 0) return null
  return [...hits].sort((a, b) => dateRank(b.received_at) - dateRank(a.received_at))[0] ?? null
}

function dateRank(value?: unknown): number {
  if (value == null) return 0
  if (typeof value === 'number') return value
  if (typeof value === 'string') {
    const normalized = value.trim().replace(' ', 'T')
    const t = Date.parse(normalized)
    return Number.isNaN(t) ? 0 : t
  }
  return 0
}