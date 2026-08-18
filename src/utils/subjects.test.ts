import { describe, expect, it } from 'vitest'
import { isVerificationEmail, isAuthEmail, isAuthEmailPrefix } from './subjects.js'

describe('isVerificationEmail', () => {
  it('匹配精确主题「CUN.AI邮箱验证邮件」', () => {
    expect(isVerificationEmail('CUN.AI邮箱验证邮件')).toBe(true)
  })

  it('不匹配其他主题', () => {
    expect(isVerificationEmail('Welcome to CUN.AI')).toBe(false)
    expect(isVerificationEmail('')).toBe(false)
  })
})

describe('isAuthEmail', () => {
  it('匹配以 Verify your email to claim 开头的完整主题', () => {
    expect(isAuthEmail('Verify your email to claim $3.000000 额度 credits on CUN.AI')).toBe(true)
  })

  it('仅前缀匹配也通过（容忍空格/字符差异）', () => {
    expect(isAuthEmail('Verify your email to claim')).toBe(true)
  })

  it('不匹配无关主题', () => {
    expect(isAuthEmail('Verify your account')).toBe(false)
    expect(isAuthEmail('CUN.AI邮箱验证邮件')).toBe(false)
  })

  it('忽略前后空白', () => {
    expect(isAuthEmail('  Verify your email to claim credits on CUN.AI  ')).toBe(true)
  })
})

describe('isAuthEmailPrefix', () => {
  it('返回约定的前缀常量', () => {
    expect(isAuthEmailPrefix).toBe('Verify your email to claim')
  })
})