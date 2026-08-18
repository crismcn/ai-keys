import { access, appendFile, writeFile } from 'node:fs/promises'

/** 写入 ACCOUNT.MD 的账号记录 */
export interface AccountRecord {
  username: string
  email: string
  password: string
  registeredAt?: string
  status: string
}

/**
 * 把一条账号记录以 Markdown 列表块形式追加到 ACCOUNT.MD。
 * 文件不存在时先建文件并写入表头；追加不重复表头。
 */
export async function appendAccountToMd(filePath: string, record: AccountRecord): Promise<void> {
  if (!(await exists(filePath))) {
    await writeFile(filePath, '# Account Record\n\n', 'utf8')
  }
  const block = [`- Username: ${record.username}`, `- Email: ${record.email}`, `- Password: ${record.password}`, `- Registered At: ${record.registeredAt ?? 'N/A'}`, `- Status: ${record.status}`, '------------------------------------------------\n'].join('\n')
  await appendFile(filePath, block, 'utf8')
}

async function exists(path: string): Promise<boolean> {
  try {
    await access(path)
    return true
  } catch {
    return false
  }
}
