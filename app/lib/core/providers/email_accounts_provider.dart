import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/email_account.dart';
import 'mock_data.dart';

/// 邮箱账号列表状态。
///
/// 当前为内存态 + 模拟数据，仅保证页面可预览。
/// TODO(逻辑接入)：替换为本地持久化（shared_preferences）或后端 API 数据源，
/// 页面层无需改动——所有写操作统一走这里的 public 方法。
class EmailAccountsNotifier extends Notifier<List<EmailAccount>> {
  @override
  List<EmailAccount> build() => mockAccounts;

  /// 已激活数量（首页「已用数量」）。
  int get activatedCount => state.where((e) => e.activated).length;

  /// 批量导入。
  void addAll(Iterable<EmailAccount> accounts) {
    state = [...state, ...accounts];
  }

  /// 删除单个账号。
  void remove(String email) {
    state = state.where((e) => e.email != email).toList();
  }

  /// 激活成功后标记为可用。
  void markActivated(String email) {
    state = [
      for (final e in state)
        if (e.email == email) e.copyWith(activated: true) else e,
    ];
  }
}

final emailAccountsProvider =
    NotifierProvider<EmailAccountsNotifier, List<EmailAccount>>(
  EmailAccountsNotifier.new,
);

/// 已激活（可用）账号数量。
final activatedCountProvider = Provider<int>((ref) {
  return ref.watch(emailAccountsProvider).where((e) => e.activated).length;
});
