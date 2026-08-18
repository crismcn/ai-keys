import { describe, expect, it } from 'vitest'
import { AppError, ERROR_CODE } from '../errors.js'
import { withRetry, sleep } from './retry.js'

describe('AppError', () => {
  it('可标记是否可重试', () => {
    const e = new AppError(ERROR_CODE.NETWORK_ERROR, 'timeout', { retryable: true })
    expect(e.code).toBe('NETWORK_ERROR')
    expect(e.retryable).toBe(true)
  })

  it('默认不可重试', () => {
    const e = new AppError(ERROR_CODE.CONFIG_INVALID, 'bad config')
    expect(e.retryable).toBe(false)
  })
})

describe('withRetry', () => {
  it('可恢复失败后重试，最终成功', async () => {
    let attempt = 0
    const fn = async () => {
      attempt++
      if (attempt <= 2) throw new AppError(ERROR_CODE.NETWORK_ERROR, 'fail', { retryable: true })
      return 'ok'
    }
    await expect(withRetry(fn, { delaysMs: [1, 1, 1] })).resolves.toBe('ok')
    expect(attempt).toBe(3)
  })

  it('重试次数耗尽后抛出最后一次错误', async () => {
    let attempt = 0
    const fn = async () => {
      attempt++
      throw new AppError(ERROR_CODE.NETWORK_ERROR, 'still failing', { retryable: true })
    }
    await expect(withRetry(fn, { maxRetries: 2, delaysMs: [1, 1] })).rejects.toThrow('still failing')
    expect(attempt).toBe(3) // 初始 1 次 + 重试 2 次
  })

  it('不可恢复错误不重试，直接抛出', async () => {
    let attempt = 0
    const fn = async () => {
      attempt++
      throw new AppError(ERROR_CODE.CONFIG_INVALID, 'bad')
    }
    await expect(withRetry(fn)).rejects.toThrow('bad')
    expect(attempt).toBe(1)
  })

  it('普通 Error 默认不重试', async () => {
    let attempt = 0
    const fn = async () => {
      attempt++
      throw new Error('plain')
    }
    await expect(withRetry(fn)).rejects.toThrow('plain')
    expect(attempt).toBe(1)
  })

  it('自定义 shouldRetry 只重试指定错误', async () => {
    let attempt = 0
    const fn = async () => {
      attempt++
      if (attempt === 1) throw new AppError(ERROR_CODE.NETWORK_ERROR, 'n', { retryable: true })
      throw new Error('boom')
    }
    await expect(
      withRetry(fn, {
        delaysMs: [1, 1],
        shouldRetry: (e) => e instanceof AppError && e.code === ERROR_CODE.NETWORK_ERROR,
      }),
    ).rejects.toThrow('boom')
    expect(attempt).toBe(2)
  })

  it('回调 onRetry 拿到重试次数', async () => {
    let attempt = 0
    const retries: number[] = []
    const fn = async () => {
      attempt++
      if (attempt < 3) throw new AppError(ERROR_CODE.NETWORK_ERROR, 'x', { retryable: true })
      return 'done'
    }
    await withRetry(fn, { delaysMs: [1, 1], onRetry: (n) => retries.push(n) })
    expect(retries).toEqual([1, 2])
  })
})

describe('sleep', () => {
  it('延迟后 resolve', async () => {
    const t0 = Date.now()
    await sleep(20)
    expect(Date.now() - t0).toBeGreaterThanOrEqual(15)
  })

  it('支持 AbortSignal 中断', async () => {
    const ac = new AbortController()
    const p = sleep(1000, ac.signal)
    ac.abort()
    const err = await p.then(() => null, (e) => e)
    expect(err?.name).toBe('AbortError')
  })
})