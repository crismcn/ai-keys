import { describe, expect, it } from 'vitest'
import { extractAuthUrl } from './extractAuthUrl.js'

describe('extractAuthUrl', () => {
  it('从 HTML 中提取含 verify 的链接', () => {
    const html = '<p>点击 <a href="https://www.cun.ai/verify?token=abc123">这里</a> 完成认证</p>'
    expect(extractAuthUrl(html)).toBe('https://www.cun.ai/verify?token=abc123')
  })

  it('优先提取 verify/auth/claim 相关链接', () => {
    const html =
      '欢迎阅读 <a href="https://blog.cun.ai/post/123">文章</a>，请点击 <a href="https://www.cun.ai/claim?code=z9">领取额度</a>'
    expect(extractAuthUrl(html)).toBe('https://www.cun.ai/claim?code=z9')
  })

  it('无链接时返回 null', () => {
    expect(extractAuthUrl('这是一封纯文本说明，没有链接')).toBeNull()
    expect(extractAuthUrl('')).toBeNull()
  })

  it('没有关键词时退回取第一个 http 链接', () => {
    const html = '详见 https://www.cun.ai/activate/9f2k，感谢'
    expect(extractAuthUrl(html)).toBe('https://www.cun.ai/activate/9f2k')
  })
})