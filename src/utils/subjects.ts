/** 邮件主题过滤规则 */

/** 认证邮件主题前缀（完整形似 "Verify your email to claim $3.000000 额度 credits on CUN.AI"） */
export const isAuthEmailPrefix = 'Verify your email to claim'

/** 验证码邮件：精确主题 */
export function isVerificationEmail(subject: string): boolean {
  return subject === 'CUN.AI邮箱验证邮件'
}

/**
 * 认证邮件：按前缀/包含匹配，避免特殊字符（如全角 $、空格）差异导致漏匹配。
 * 兼容主题以 "Verify your email to claim" 开头的情形。
 */
export function isAuthEmail(subject: string): boolean {
  return subject.trim().startsWith(isAuthEmailPrefix)
}