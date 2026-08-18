import { describe, expect, it } from 'vitest'
import type { EmailMeta } from '../types.js'
import { pickLatestEmail } from './pickEmail.js'

const emails: EmailMeta[] = [
  { message_id: '1', subject: 'other', received_at: '2026-08-18 10:00:00' },
  { message_id: '2', subject: 'CUN.AI邮箱验证邮件', received_at: '2026-08-18 10:02:00' },
  { message_id: '3', subject: 'CUN.AI邮箱验证邮件', received_at: '2026-08-18 10:05:00' },
  { message_id: '4', subject: 'other', received_at: '2026-08-18 10:03:00' },
]

describe('pickLatestEmail', () => {
  it('按主题过滤并返回日期最新的一封', () => {
    const hit = pickLatestEmail(emails, (e) => e.subject === 'CUN.AI邮箱验证邮件')
    expect(hit?.message_id).toBe('3')
  })

  it('无匹配时返回 null', () => {
    expect(pickLatestEmail(emails, (e) => e.subject === 'nope')).toBeNull()
  })

  it('兼容 ISO 格式日期', () => {
    const iso = [
      { message_id: 'a', subject: 's', received_at: '2026-08-18T10:00:00Z' },
      { message_id: 'b', subject: 's', received_at: '2026-08-18T11:00:00Z' },
      { message_id: 'c', subject: 's', received_at: '2026-08-18T09:00:00Z' },
    ]
    expect(pickLatestEmail(iso, (e) => e.subject === 's')?.message_id).toBe('b')
  })

  it('缺日期时按列表顺序取第一条匹配', () => {
    const noDate = [
      { message_id: 'x', subject: 's' },
      { message_id: 'y', subject: 's' },
    ]
    expect(pickLatestEmail(noDate, (e) => e.subject === 's')?.message_id).toBe('x')
  })
})