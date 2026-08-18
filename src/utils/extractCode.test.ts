import { describe, expect, it } from 'vitest'
import { extractVerificationCode } from './extractCode.js'

describe('extractVerificationCode', () => {
  it('提取「验证码为」后的 6 位数字', () => {
    expect(extractVerificationCode('您的验证码为：123456，请勿泄露')).toBe('123456')
  })

  it('提取字母+数字混合的 6 位验证码（cun.ai 实测格式）', () => {
    expect(extractVerificationCode('您的验证码为: <strong>a8d1e3</strong></p><p>验证码 10 分钟内有效')).toBe('a8d1e3')
  })

  it('提取英文 "verification code" 后的 6 位数字（大小写不敏感）', () => {
    expect(extractVerificationCode('Your Verification Code IS: 987654. Do not share.')).toBe('987654')
  })

  it('HTML 标签包裹数字时仍能提取', () => {
    const html = '<p>验证码为 <strong>456123</strong></p>'
    expect(extractVerificationCode(html)).toBe('456123')
  })

  it('多个「验证码为」时取最后一条标记后的验证码', () => {
    const html = '您的验证码为：111111。如需重发，再次验证码为：222222。'
    expect(extractVerificationCode(html)).toBe('222222')
  })

  it('标记后紧随的第一个 6 位数字优先（不被其他流水号干扰）', () => {
    const html = '验证码为：333333。本次交易流水号 444444'
    expect(extractVerificationCode(html)).toBe('333333')
  })

  it('无标记时取全文最后出现的 6 位数字', () => {
    expect(extractVerificationCode('订单 555555 已成功，参考号 666666')).toBe('666666')
  })

  it('无任何 6 位数字时返回 null', () => {
    expect(extractVerificationCode('这是一封没有验证码的邮件')).toBeNull()
    expect(extractVerificationCode('')).toBeNull()
  })

  it('有标记但标记后无有效验证码（已失效）时返回 null，不误取远处数字', () => {
    expect(extractVerificationCode('验证码为：****（已验证失效，请重新获取）。本文底部参考编号 777777')).toBeNull()
  })

  it('不匹配 6 位以上连续数字（避免截取长数字）', () => {
    expect(extractVerificationCode('验证码为：12345678')).toBeNull()
  })
})