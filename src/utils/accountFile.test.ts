import { describe, expect, it } from 'vitest'
import { readFile, mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { appendAccountToMd, type AccountRecord } from './accountFile.js'

const RECORD: AccountRecord = {
  username: 'vaigipskukv',
  email: 'vaigipskukv@outlook.com',
  password: 'ooudxgkbsu3166',
  registeredAt: '2026-08-18 12:00:00',
  status: 'Success',
}

async function withTempDir(fn: (dir: string) => Promise<void>) {
  const dir = await mkdtemp(join(tmpdir(), 'accountfile-'))
  try {
    await fn(dir)
  } finally {
    await rm(dir, { recursive: true, force: true })
  }
}

describe('appendAccountToMd', () => {
  it('首次写入自动创建文件并带表头', async () => {
    await withTempDir(async (dir) => {
      const file = join(dir, 'ACCOUNT.MD')
      await appendAccountToMd(file, RECORD)
      const content = await readFile(file, 'utf8')
      expect(content).toContain('# Account Record')
      expect(content).toContain('- Username: vaigipskukv')
    })
  })

  it('写入全部字段行', async () => {
    await withTempDir(async (dir) => {
      const file = join(dir, 'ACCOUNT.MD')
      await appendAccountToMd(file, RECORD)
      const content = await readFile(file, 'utf8')
      for (const line of [
        '- Email: vaigipskukv@outlook.com',
        '- Password: ooudxgkbsu3166',
        '- Registered At: 2026-08-18 12:00:00',
        '- Status: Success',
      ]) {
        expect(content).toContain(line)
      }
    })
  })

  it('再次追加不重复表头', async () => {
    await withTempDir(async (dir) => {
      const file = join(dir, 'ACCOUNT.MD')
      await appendAccountToMd(file, RECORD)
      await appendAccountToMd(file, RECORD)
      const content = await readFile(file, 'utf8')
      expect(content.match(/# Account Record/g)).toHaveLength(1)
      expect(content.match(/- Username: vaigipskukv/g)).toHaveLength(2)
    })
  })
})