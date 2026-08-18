import { AppError } from '../errors.js'

/** 默认退避间隔：1s/2s/4s/8s */
const DEFAULT_DELAYS = [1000, 2000, 4000, 8000]

export interface RetryOptions {
  /** 最大重试次数（默认 = delaysMs 长度，即 4 次） */
  maxRetries?: number
  /** 每次重试前的延迟（毫秒），按第几次重试取值 */
  delaysMs?: number[]
  /** 是否对该错误启用重试（默认：仅 AppError 且 retryable=true） */
  shouldRetry?: (error: unknown) => boolean
  /** 每次重试前回调，参数为第几次重试（从 1 开始） */
  onRetry?: (attempt: number, error: unknown) => void
}

/** 按退避策略重试异步操作；不可恢复错误或超限后抛出原错误 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  opts: RetryOptions = {},
): Promise<T> {
  const delays = opts.delaysMs ?? DEFAULT_DELAYS
  const maxRetries = opts.maxRetries ?? delays.length
  const shouldRetry =
    opts.shouldRetry ?? ((e: unknown) => e instanceof AppError && e.retryable)
  const onRetry = opts.onRetry

  let attempt = 0
  for (;;) {
    try {
      return await fn()
    } catch (error) {
      attempt++
      if (!shouldRetry(error) || attempt > maxRetries) throw error
      onRetry?.(attempt, error)
      const delay = delays[attempt - 1] ?? delays[delays.length - 1] ?? 1000
      await sleep(delay)
    }
  }
}

/** 延迟指定毫秒；传入 AbortSignal 可在中断时以 AbortError 拒绝 */
export function sleep(ms: number, signal?: AbortSignal): Promise<void> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(finish, ms)

    function cleanup() {
      clearTimeout(timer)
      signal?.removeEventListener('abort', onAbort)
    }

    function onAbort() {
      cleanup()
      reject(Object.assign(new Error('The operation was aborted'), { name: 'AbortError' }))
    }

    function finish() {
      cleanup()
      resolve()
    }

    if (signal?.aborted) {
      onAbort()
      return
    }
    signal?.addEventListener('abort', onAbort, { once: true })
  })
}