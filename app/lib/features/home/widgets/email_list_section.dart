import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/widgets/app_button.dart';
import '../../../core/design_system/widgets/app_card.dart';
import '../../../core/design_system/widgets/empty_state.dart';
import '../../../core/models/email_account.dart';
import '../../../core/providers/email_accounts_provider.dart';
import '../../activation/activation_detail_page.dart';
import '../email_list_provider.dart';
import 'email_list_item.dart';

/// 首页「邮箱列表」区块：模糊搜索 + 下拉刷新 + 上拉加载 + 左滑删除。
class EmailListSection extends ConsumerStatefulWidget {
  const EmailListSection({super.key});

  @override
  ConsumerState<EmailListSection> createState() => _EmailListSectionState();
}

class _EmailListSectionState extends ConsumerState<EmailListSection> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 滚动接近底部时触发上拉加载。
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter < 240) {
      final total = ref.read(filteredEmailsProvider).length;
      ref.read(emailListControllerProvider.notifier).loadMore(total);
    }
  }

  /// 下拉刷新。
  Future<void> _refresh() =>
      ref.read(emailListControllerProvider.notifier).refresh();

  /// 清除搜索。
  void _clearSearch() {
    _searchController.clear();
    ref.read(emailListControllerProvider.notifier).clearQuery();
  }

  /// 左滑删除（确认后）。
  Future<bool> _confirmDelete(BuildContext context, EmailAccount item) async {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '删除 ${item.account}？',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isLight ? AppColors.foreground : AppColors.foregroundDark,
          ),
        ),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          AppButton(
            label: '删除',
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(emailListControllerProvider);
    final filtered = ref.watch(filteredEmailsProvider);
    final allCount = ref.watch(emailAccountsProvider).length;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;

    final hasQuery = listState.query.isNotEmpty;
    final visible = filtered.take(listState.limit).toList();
    final hasMore = filtered.length > listState.limit;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // 标题行
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Text(
                  '邮箱列表',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.muted : AppColors.mutedDark,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    hasQuery ? '匹配 ${filtered.length} 个' : '共 $allCount 个',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: mutedFg,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // 搜索框
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(emailListControllerProvider.notifier).setQuery(v),
              textInputAction: TextInputAction.search,
              style: TextStyle(fontSize: 13.5, color: fg),
              decoration: InputDecoration(
                hintText: '搜索邮箱 / 账号',
                hintStyle: TextStyle(fontSize: 13, color: mutedFg),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: mutedFg),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 16, color: mutedFg),
                        tooltip: '清除搜索',
                        onPressed: _clearSearch,
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isLight ? AppColors.muted : AppColors.mutedDark,
              ),
            ),
          ),
          // 内容区
          Expanded(
            child: visible.isEmpty
                // 空态 / 搜索无结果（保持可下拉刷新）
                ? RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      children: [
                        if (filtered.isEmpty && !hasQuery)
                          const EmptyState(
                            compact: true,
                            icon: Icons.mail_outline_rounded,
                            title: '还没有邮箱',
                            subtitle: '点击右上角「导入邮箱」添加账号',
                          )
                        else
                          EmptyState(
                            compact: true,
                            icon: Icons.search_off_rounded,
                            title: '未找到匹配的邮箱',
                            subtitle: '换个关键词试试',
                            action: AppButton(
                              label: '清除搜索',
                              variant: AppButtonVariant.outline,
                              size: AppButtonSize.sm,
                              onPressed: _clearSearch,
                            ),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      itemCount: visible.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xxs),
                      itemBuilder: (context, index) {
                        // 末尾 footer：加载中 / 上拉提示 / 已加载全部
                        if (index == visible.length) {
                          return _ListFooter(
                            isLoadingMore: listState.isLoadingMore,
                            hasMore: hasMore,
                            total: filtered.length,
                          );
                        }
                        final item = visible[index];
                        return Dismissible(
                          key: ValueKey(item.email),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => _confirmDelete(context, item),
                          onDismissed: (_) {
                            ref
                                .read(emailAccountsProvider.notifier)
                                .remove(item.email);
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(content: Text('已删除 ${item.account}')),
                              );
                          },
                          background: _deleteBackground(context),
                          child: EmailListItem(
                            account: item,
                            onActivate: () => context.push(
                              ActivationDetailPage.pathOf(item.email),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 左滑删除背景（红底 + 删除图标）。
  Widget _deleteBackground(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.destructive,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
    );
  }
}

/// 列表 footer：加载中 / 上拉提示 / 已加载全部。
class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.isLoadingMore,
    required this.hasMore,
    required this.total,
  });

  final bool isLoadingMore;
  final bool hasMore;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg = isLight
        ? AppColors.mutedForeground
        : AppColors.mutedForegroundDark;

    final Widget child;
    if (isLoadingMore) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('加载中…', style: TextStyle(fontSize: 12, color: mutedFg)),
        ],
      );
    } else if (hasMore) {
      child = Text('上拉加载更多', style: TextStyle(fontSize: 12, color: mutedFg));
    } else {
      child = Text(
        '已加载全部 $total 个',
        style: TextStyle(fontSize: 12, color: mutedFg),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(child: child),
    );
  }
}