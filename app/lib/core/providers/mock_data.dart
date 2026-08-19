import '../models/email_account.dart';

/// 模拟数据：让页面在当前阶段即可运行预览。
/// TODO(逻辑接入)：真实数据来自后端 API / 本地持久化，届时删除本文件。
final List<EmailAccount> mockAccounts = [
  EmailAccount(
    email: 'alice2026@outlook.com',
    password: 'Kf9!mNp2',
    clientId: '2ac1f4b8-...',
    refreshToken: 'rt_alice_01',
    createdAt: DateTime(2026, 8, 1),
    activated: true,
  ),
  EmailAccount(
    email: 'bob.sunshine@outlook.com',
    password: 'Zx3@vQw7',
    clientId: '7de930aa-...',
    refreshToken: 'rt_bob_02',
    createdAt: DateTime(2026, 8, 2),
    activated: true,
  ),
  EmailAccount(
    email: 'carol.kevin@outlook.com',
    password: 'P@ssw0rd1',
    clientId: '5b1f20c9-...',
    refreshToken: 'rt_carol_03',
    createdAt: DateTime(2026, 8, 3),
  ),
  EmailAccount(
    email: 'david.night@outlook.com',
    password: 'h9&dK2pL',
    clientId: 'a3c88e11-...',
    refreshToken: 'rt_david_04',
    createdAt: DateTime(2026, 8, 5),
  ),
  EmailAccount(
    email: 'emma.wang@outlook.com',
    password: 'E1m@2026ab',
    clientId: 'c0d5f7a2-...',
    refreshToken: 'rt_emma_05',
    createdAt: DateTime(2026, 8, 6),
  ),
  EmailAccount(
    email: 'frank.lin@outlook.com',
    password: 'L8#nQ3xR',
    clientId: '90e2b4d7-...',
    refreshToken: 'rt_frank_06',
    createdAt: DateTime(2026, 8, 8),
  ),
  EmailAccount(
    email: 'grace.han@outlook.com',
    password: 'gH5@2026pd',
    clientId: '1fe9c30b-...',
    refreshToken: 'rt_grace_07',
    createdAt: DateTime(2026, 8, 10),
  ),
  EmailAccount(
    email: 'henry.zhao@outlook.com',
    password: 'Zh8#mK4t',
    clientId: 'd7a1e59c-...',
    refreshToken: 'rt_henry_08',
    createdAt: DateTime(2026, 8, 12),
  ),
  EmailAccount(
    email: 'iris.chen@outlook.com',
    password: 'iR4@2026qc',
    clientId: 'b3f8d2e6-...',
    refreshToken: 'rt_iris_09',
    createdAt: DateTime(2026, 8, 14),
  ),
  EmailAccount(
    email: 'jack.sun@outlook.com',
    password: 'Sj6#xQ1m',
    clientId: 'e4c9a1f3-...',
    refreshToken: 'rt_jack_10',
    createdAt: DateTime(2026, 8, 15),
  ),
];
