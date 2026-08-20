import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/state/email_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/buttons.dart';
import '../../widgets/section_card.dart';
import '../activation/activation_detail_page.dart';
import '../import_email/import_email_page.dart';
import 'widgets/email_list_item.dart';
import 'widgets/stat_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _pageSize = 12;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  int get _filteredLength =>
      context.read<EmailStore>().search(_query).length;

  Future<void> _loadMore() async {
    if (_loadingMore || _visibleCount >= _filteredLength) return;
    setState(() => _loadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _visibleCount = (_visibleCount + _pageSize).clamp(0, _filteredLength);
      _loadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await context.read<EmailStore>().load();
    if (!mounted) return;
    setState(() => _visibleCount = _pageSize);
  }

  void _openImport() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportEmailPage()),
    );
  }

  Future<void> _copyAccount(EmailAccount account) async {
    await Clipboard.setData(
      ClipboardData(text: context.s.copyAccountText(account.accountName, account.password)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.s.copied),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openActivation(EmailAccount account) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActivationDetailPage(account: account)),
    );
  }
  // _HANDLERS_

  Future<bool> _confirmDelete(EmailAccount account) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.s.confirmDeleteTitle),
        content: Text(context.s.confirmDeleteBody(account.accountName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(context.s.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<EmailStore>();
    final list = store.search(_query);
    final visible = list.take(_visibleCount).toList();

    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _header()),
              SliverToBoxAdapter(child: _stats(store)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
              SliverToBoxAdapter(child: _listSection(store, list, visible)),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Keys',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: context.c.textPrimary,
                    height: 1.1,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  context.s.appSubtitle,
                  style: TextStyle(fontSize: 13, color: context.c.textSecondary),
                ),
              ],
            ),
          ),
          SoftPillButton(
            label: context.s.importEmail,
            icon: Icons.file_download_outlined,
            onPressed: _openImport,
          ),
        ],
      ),
    );
  }

  Widget _stats(EmailStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              title: context.s.statEmailCount,
              value: '${store.total}',
              caption: context.s.statTotal,
              icon: Icons.mail_outline_rounded,
              iconColor: AppColors.primary,
              iconBg: context.c.primarySoft,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatCard(
              title: context.s.statActivated,
              value: '${store.available}',
              caption: context.s.statAvailable,
              icon: Icons.check_circle_outline_rounded,
              iconColor: AppColors.success,
              iconBg: context.c.successSoft,
            ),
          ),
        ],
      ),
    );
  }
  // _LIST_

  Widget _listSection(
      EmailStore store, List<EmailAccount> list, List<EmailAccount> visible) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SectionCard(
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.lg, 0, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                context.s.emailListTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _searchField(),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (list.isEmpty)
              _emptyState()
            else
              ...List.generate(
                  visible.length, (i) => _dismissibleItem(store, visible[i], i)),
            const SizedBox(height: AppSpacing.sm),
            _footer(store, list, visible),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() {
        _query = v;
        _visibleCount = _pageSize;
      }),
      style: TextStyle(fontSize: 14, color: context.c.textPrimary),
      decoration: InputDecoration(
        hintText: context.s.searchHint,
        hintStyle: TextStyle(color: context.c.textSecondary, fontSize: 14),
        prefixIcon: Icon(Icons.search_rounded,
            color: context.c.textSecondary, size: 20),
        filled: true,
        fillColor: context.c.bg,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dismissibleItem(EmailStore store, EmailAccount account, int index) {
    return Column(
      children: [
        if (index > 0)
          Divider(
              height: 1,
              thickness: 1,
              color: context.c.border,
              indent: 72,
              endIndent: 16),
        Dismissible(
          key: ValueKey(account.email),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmDelete(account),
          onDismissed: (_) => store.remove(account),
          background: Container(
            alignment: Alignment.centerRight,
            color: AppColors.danger,
            padding: const EdgeInsets.only(right: 24),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
          child: EmailListItem(
            account: account,
            colorIndex: index,
            onTap: () => _copyAccount(account),
            onActivate: () => _openActivation(account),
          ),
        ),
      ],
    );
  }

  Widget _footer(
      EmailStore store, List<EmailAccount> list, List<EmailAccount> visible) {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.c.neutral),
            ),
            const SizedBox(width: 8),
            Text(
              context.s.loadingMore,
              style: TextStyle(fontSize: 12, color: context.c.textSecondary),
            ),
          ],
        ),
      );
    }
    final allShown = visible.length >= list.length;
    return Column(
      children: [
        if (allShown && list.length > _pageSize)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              context.s.noMore,
              style: TextStyle(fontSize: 12, color: context.c.neutral),
            ),
          ),
        Center(
          child: Text(
            context.s.emailCount(store.total),
            style: TextStyle(fontSize: 12, color: context.c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 44, color: context.c.neutral.withValues(alpha: 0.7)),
            const SizedBox(height: AppSpacing.md),
            Text(
              _query.isEmpty ? context.s.emptyNoEmails : context.s.emptyNoMatch,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
