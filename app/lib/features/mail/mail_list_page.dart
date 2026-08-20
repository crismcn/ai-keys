import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/models/email_account.dart';
import '../../core/models/mail_message.dart';
import '../../core/services/mail_read_store.dart';
import '../../core/services/mail_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/avatar.dart';
import '../../widgets/section_card.dart';
import 'mail_detail_sheet.dart';

/// Received-mail list for a single account, backed by the paginated
/// `fetch_emails` API (API.MD #2). Reached by tapping an account row on home.
class MailListPage extends StatefulWidget {
  const MailListPage({super.key, required this.account});

  final EmailAccount account;

  @override
  State<MailListPage> createState() => _MailListPageState();
}

class _MailListPageState extends State<MailListPage> {
  final _scroll = ScrollController();

  final List<MailMessage> _mails = [];
  bool _loading = true; // initial page load
  bool _loadingMore = false; // subsequent pages
  bool _error = false; // initial load failed
  bool _hasMore = false;
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadFirst();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) _loadMore();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final page = await MailService.fetchEmails(
        account: widget.account,
        page: 1,
      );
      final merged = await _mergeReadState(page.emails);
      if (!mounted) return;
      setState(() {
        _mails
          ..clear()
          ..addAll(merged);
        _hasMore = page.hasMore;
        _total = page.total;
        _page = 1;
        _loading = false;
      });
    } on MailException {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _refresh() => _loadFirst();

  Future<void> _loadMore() async {
    if (_loadingMore || _loading || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await MailService.fetchEmails(
        account: widget.account,
        page: _page + 1,
      );
      final merged = await _mergeReadState(page.emails);
      if (!mounted) return;
      setState(() {
        _mails.addAll(merged);
        _hasMore = page.hasMore;
        _total = page.total;
        _page += 1;
        _loadingMore = false;
      });
    } on MailException {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  /// Read-tracking key for a mail: `md5(mailbox address + date)`.
  String _readKey(MailMessage mail) =>
      MailReadStore.keyFor(widget.account.email, mail.date);

  /// Overlays locally-persisted read-state onto freshly fetched mails, so mails
  /// read in a previous session show without an unread dot after a reload.
  Future<List<MailMessage>> _mergeReadState(List<MailMessage> mails) async {
    final out = <MailMessage>[];
    for (final mail in mails) {
      final read =
          mail.isRead || await MailReadStore.instance.isRead(_readKey(mail));
      out.add(read == mail.isRead ? mail : mail.copyWith(isRead: true));
    }
    return out;
  }

  /// Opens the detail drawer; marks the mail read once the detail loads
  /// (keyed by mailbox address + date — see [MailReadStore.keyFor]).
  void _openDetail(int index) {
    final mail = _mails[index];
    final key = _readKey(mail);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MailDetailSheet(
        account: widget.account,
        messageId: mail.messageId,
        headerSubject: mail.cleanSubject,
        headerSender: mail.sender,
        onRead: () {
          MailReadStore.instance.markRead(key);
          if (!mounted) return;
          if (index < _mails.length && _mails[index].unread) {
            setState(() => _mails[index] = _mails[index].copyWith(isRead: true));
          }
        },
      ),
    );
  }
  // _BODY_

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(title: Text(context.s.mailListTitle)),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primary,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _accountCard(widget.account),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                _loadingState()
              else if (_error)
                _errorState()
              else if (_mails.isEmpty)
                _emptyState()
              else ...[
                _mailListCard(),
                const SizedBox(height: AppSpacing.lg),
                _footer(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountCard(EmailAccount account) {
    return SectionCard(
      child: Row(
        children: [
          LetterAvatar(name: account.email, letter: account.initial, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.accountName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: context.c.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  account.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: context.c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // _LIST_

  Widget _mailListCard() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < _mails.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                color: context.c.border,
                indent: 68,
                endIndent: 16,
              ),
            _MailTile(mail: _mails[i], onTap: () => _openDetail(i)),
          ],
        ],
      ),
    );
  }

  Widget _footer() {
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.c.neutral,
              ),
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
    return Column(
      children: [
        if (!_hasMore && _mails.length > MailService.pageSize)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              context.s.noMore,
              style: TextStyle(fontSize: 12, color: context.c.neutral),
            ),
          ),
        Center(
          child: Text(
            context.s.mailCount(_total),
            style: TextStyle(fontSize: 12, color: context.c.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.s.mailLoading,
            style: TextStyle(fontSize: 13, color: context.c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: context.c.neutral),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.s.mailLoadError,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: context.c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _loadFirst,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.s.mailRetry),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(
            Icons.mail_outline_rounded,
            size: 44,
            color: context.c.neutral.withValues(alpha: 0.7),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.s.mailEmpty,
            style: TextStyle(fontSize: 14, color: context.c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Single received-mail row: sender avatar, sender + time + unread dot,
/// subject, and a preview built from the address (list API has no body).
class _MailTile extends StatelessWidget {
  const _MailTile({required this.mail, required this.onTap});

  final MailMessage mail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleWeight = mail.unread ? FontWeight.w700 : FontWeight.w600;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LetterAvatar(name: mail.sender, letter: mail.initial, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mail.sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: titleWeight,
                              color: context.c.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          mail.displayTime,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.c.textSecondary,
                          ),
                        ),
                        if (mail.unread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mail.cleanSubject,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: context.c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mail.senderEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
