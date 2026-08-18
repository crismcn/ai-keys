/** 轻量 JSON 日志（脱敏版）。
 *  与规格中 winston/pino 二选一的基线一致：结构化为 JSON 行、
 *  支持级别过滤；核心安全要求是绝不让 refresh_token/password/正文落盘。 */

export type LogLevel = 'debug' | 'info' | 'warn' | 'error'
export type LogSink = (line: string) => void

export interface RedactOptions {
  /** 需要整体遮蔽的字段名（递归匹配），默认涵盖常见密钥 */
  secretKeys?: string[]
  /** 普通字符串字段超过该长度则截断，默认 800 */
  maxLength?: number
}

export type Fields = Record<string, unknown>

export interface Logger {
  debug(msg: string, fields?: Fields): void
  info(msg: string, fields?: Fields): void
  warn(msg: string, fields?: Fields): void
  error(msg: string, fields?: Fields): void
}

const SECRET_KEYS = new Set([
  'refresh_token',
  'refreshToken',
  'password',
  'token',
  'secret',
  'authorization',
  'Authorization',
])

/** 递归脱敏字段值：密钥字段遮蔽、超长字符串截断 */
export function redact(value: unknown, opts: RedactOptions = {}): unknown {
  const secretKeys = new Set(opts.secretKeys ?? [...SECRET_KEYS])
  const maxLength = opts.maxLength ?? 800
  return walk(value, secretKeys, maxLength)
}

function walk(value: unknown, secretKeys: Set<string>, maxLength: number): unknown {
  if (Array.isArray(value)) return value.map((v) => walk(v, secretKeys, maxLength))
  if (value && typeof value === 'object') {
    const out: Record<string, unknown> = {}
    for (const [key, val] of Object.entries(value as Record<string, unknown>)) {
      out[key] = secretKeys.has(key)
        ? '[REDACTED]'
        : walk(val, secretKeys, maxLength)
    }
    return out
  }
  if (typeof value === 'string' && value.length > maxLength) {
    return `${value.slice(0, maxLength)}…[truncated]`
  }
  return value
}

const LEVEL_PRIORITY: Record<LogLevel, number> = { debug: 0, info: 1, warn: 2, error: 3 }

export function createLogger(opts: { sink?: LogSink; level?: LogLevel; redact?: RedactOptions } = {}): Logger {
  const sink: LogSink = opts.sink ?? ((line) => console.log(line))
  const minPriority = LEVEL_PRIORITY[opts.level ?? 'info']
  const redactOpts = opts.redact ?? {}

  function emit(level: LogLevel, msg: string, fields?: Fields) {
    if (LEVEL_PRIORITY[level] < minPriority) return
    const payload = {
      ts: new Date().toISOString(),
      level,
      msg,
      ...(fields ? (redact(fields, redactOpts) as Fields) : {}),
    }
    sink(JSON.stringify(payload))
  }

  return {
    debug: (msg, fields) => emit('debug', msg, fields),
    info: (msg, fields) => emit('info', msg, fields),
    warn: (msg, fields) => emit('warn', msg, fields),
    error: (msg, fields) => emit('error', msg, fields),
  }
}