import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/email_account.dart';
import '../../core/providers/email_accounts_provider.dart';

/// 邮箱列表的页内状态：搜索关键词 + 已加载条数 + 加载标志。
class EmailListState {
  const EmailListState({
    this.query = '',
    this.limit = EmailListController.pageSize,
    this.isRefreshing = false,
    this.isLoadingMore = false,
  });

  /// 搜索关键词（已 trim）。
  final String query;

  /// 当前已加载条数（上拉加载递增）。
  final int limit;

  /// 下拉刷新中。
  final bool isRefreshing;

  /// 上拉加载中。
  final bool isLoadingMore;

  EmailListState copyWith({
    String? query,
    int? limit,
    bool? isRefreshing,
    bool? isLoadingMore,
  }) =>
      EmailListState(
        query: query ?? this.query,
        limit: limit ?? this.limit,
        isRefreshing: isRefreshing ?? this.isRefreshing,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// 邮箱列表控制器：管理搜索、下拉刷新、上拉加载。
class EmailListController extends Notifier<EmailListState> {
  /// 单批加载条数。
  static const int pageSize = 8;

  @override
  EmailListState build() => const EmailListState();

  /// 更新搜索关键词；关键词变化时重置已加载条数。
  void setQuery(String query) {
    final q = query.trim();
    if (q == state.query) return;
    state = state.copyWith(query: q, limit: pageSize);
  }

  /// 清除搜索。
  void clearQuery() => setQuery('');

  /// 下拉刷新：重置到第一批，重新拉取。
  /// TODO(逻辑接入)：接入真实数据源刷新。
  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(isRefreshing: false, limit: pageSize);
  }

  /// 上拉加载：追加下一批。
  /// [total] 为当前过滤后的总条数。
  /// TODO(逻辑接入)：接入真实分页接口。
  Future<void> loadMore(int total) async {
    if (state.isLoadingMore || state.limit >= total) return;
    state = state.copyWith(isLoadingMore: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final next = (state.limit + pageSize).clamp(0, total);
    state = state.copyWith(isLoadingMore: false, limit: next);
  }
}

final emailListControllerProvider =
    NotifierProvider<EmailListController, EmailListState>(
  EmailListController.new,
);

/// 按搜索关键词模糊过滤后的邮箱列表（账号 / 邮箱 忽略大小写包含匹配）。
final filteredEmailsProvider = Provider<List<EmailAccount>>((ref) {
  final query = ref.watch(emailListControllerProvider).query.toLowerCase();
  final all = ref.watch(emailAccountsProvider);
  if (query.isEmpty) return all;
  return [
    for (final e in all)
      if (e.account.toLowerCase().contains(query) ||
          e.email.toLowerCase().contains(query))
        e,
  ];
});