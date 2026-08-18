import { describe, expect, it } from 'vitest'
import { redact, type RedactOptions, createLogger } from './logger.js'

describe('redact', () => {
  const opts: RedactOptions = {}

  it('遮蔽 refresh_token / password 等密钥字段', () => {
    const out = redact(
      { email: 'a@outlook.com', refresh_token: 'M.C542_...', password: 'pwd123' },
      opts,
    ) as Record<string, unknown>
    expect(out.refresh_token).toBe('[REDACTED]')
    expect(out.password).toBe('[REDACTED]')
    expect(out.email).toBe('a@outlook.com')
  })

  it('递归遮蔽嵌套对象中的密钥', () => {
    const out = redact(
      { data: { imap: { refresh_token: 'tok' }, email: 'a@o.com' } },
      opts,
    ) as Record<string, Record<string, unknown>>
    expect((out.data.imap as Record<string, unknown>).refresh_token).toBe('[REDACTED]')
    expect(out.data.email).toBe('a@o.com')
  })

  it('截断超长邮件正文字段', () => {
    const out = redact(
      { html: `<html>${'x'.repeat(5000)}</html>` },
      { maxLength: 200 },
    ) as Record<string, string>
    expect(out.html.length).toBeLessThanOrEqual(212) // maxLength + '…[truncated]' 长度
    expect(out.html).toContain('[truncated]')
  })

  it('不截断普通短字段', () => {
    const out = redact({ subject: 'CUN.AI邮箱验证邮件' }, { maxLength: 200 }) as Record<string, string>
    expect(out.subject).toBe('CUN.AI邮箱验证邮件')
  })
})

describe('createLogger', () => {
  it('输出 JSON 行且不包含密钥明文', () => {
    const lines: string[] = []
    const logger = createLogger({ sink: (l) => lines.push(l) })
    logger.info('注册开始', { email: 'a@outlook.com', refresh_token: 'secret' })
    expect(lines).toHaveLength(1)
    expect(lines[0]).toContain('a@outlook.com')
    expect(lines[0]).toContain('[REDACTED]')
    expect(lines[0]).not.toContain('secret')
  })

  it('按级别过滤', () => {
    const lines: string[] = []
    const logger = createLogger({ sink: (l) => lines.push(l), level: 'warn' })
    logger.info('hide me')
    logger.warn('show me')
    expect(lines).toHaveLength(1)
    expect(lines[0]).toContain('show me')
  })
})