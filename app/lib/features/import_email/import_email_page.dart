import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/app_tokens.dart';
import '../../core/design_system/widgets/app_button.dart';
import '../../core/design_system/widgets/app_card.dart';
import '../../core/models/email_account.dart';
import '../../core/providers/email_accounts_provider.dart';

/// 导入邮箱页：支持「导入 CSV 文件」与「粘贴文本」两种方式。
///
/// TODO(逻辑接入)：
/// - CSV 文件选择（file_picker）与解析目前为占位，后续接入；
/// - 导入结果持久化（shared_preferences）后续接入。
class ImportEmailPage extends ConsumerStatefulWidget {
  const ImportEmailPage({super.key});

  static const String route = '/import';

  @override
  ConsumerState<ImportEmailPage> createState() => _ImportEmailPageState();
}

class _ImportEmailPageState extends ConsumerState<ImportEmailPage> {
  final TextEditingController _controller = TextEditingController();
  String? _csvFileName;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 解析粘贴文本 → 邮箱账号列表。
  /// 格式：`邮箱----密码----client_id----refresh_token----创建时间`，每行一个。
  List<EmailAccount> _parse(String text) {
    final result = <EmailAccount>[];
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split('----').map((p) => p.trim()).toList();
      if (parts.length < 4) continue;
      final email = parts[0];
      if (!email.contains('@')) continue;
      result.add(EmailAccount(
        email: email,
        password: parts.length > 1 ? parts[1] : '',
        clientId: parts.length > 2 ? parts[2] : '',
        refreshToken: parts.length > 3 ? parts[3] : '',
        createdAt: parts.length > 4 && parts[4].isNotEmpty
            ? (DateTime.tryParse(parts[4]) ?? DateTime.now())
            : DateTime.now(),
      ));
    }
    return result;
  }

  /// 预览统计：有效行 / 无效行。
  (int valid, int invalid) _previewCount(String text) {
    var valid = 0;
    var invalid = 0;
    for (final raw in text.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final parts = line.split('----');
      if (parts.length >= 4 && parts[0].trim().contains('@')) {
        valid++;
      } else {
        invalid++;
      }
    }
    return (valid, invalid);
  }

  void _import() {
    final accounts = _parse(_controller.text);
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('没有可导入的数据，请检查格式')),
        );
      return;
    }
    ref.read(emailAccountsProvider.notifier).addAll(accounts);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('成功导入 ${accounts.length} 个邮箱')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    final text = _controller.text;
    final (valid, invalid) = _previewCount(text);

    return Scaffold(
      appBar: AppBar(title: const Text('导入邮箱')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // 格式说明
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: mutedFg),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '数据格式',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const _FormatExample(),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '每行一个账号；密码必填，其余字段可为空。',
                    style: TextStyle(fontSize: 12, color: mutedFg),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // 导入方式一：CSV 文件
            AppButton(
              label: _csvFileName ?? '导入 CSV 文件',
              icon: Icons.upload_file_rounded,
              variant: AppButtonVariant.outline,
              expand: true,
              onPressed: () {
                // TODO(逻辑接入)：接入 file_picker 选择并解析 CSV 文件。
                setState(() => _csvFileName = 'sample_accounts.csv（模拟）');
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('CSV 文件选择将在后续版本接入')),
                  );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // 导入方式二：粘贴文本
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                '或直接粘贴',
                style: TextStyle(fontSize: 12, color: mutedFg),
              ),
            ),
            // 导入方式二：粘贴文本
            AppCard(
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _controller,
                maxLines: 8,
                minLines: 5,
                onChanged: (_) => setState(() {}),
                style: TextStyle(
                  fontSize: 13,
                  color: fg,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  hintText: '邮箱----密码----client_id----refresh_token----创建时间\n\n一行一个账号，例如：\nalice2026@outlook.com----Kf9!mNp2----cid----rt----2026-08-01',
                  hintMaxLines: 6,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
            ),
            // 实时预览
            if (text.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _PreviewChip(
                    color: AppColors.success,
                    label: '有效 $valid',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  if (invalid > 0)
                    _PreviewChip(
                      color: AppColors.destructive,
                      label: '无效 $invalid',
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            // 确认导入
            AppButton(
              label: '确认导入',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _controller.text.trim().isEmpty ? null : _import,
            ),
          ],
        ),
      ),
    );
  }
}

/// 格式示例（等宽风格展示）。
class _FormatExample extends StatelessWidget {
  const _FormatExample();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final mutedFg = isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isLight ? AppColors.muted : AppColors.mutedDark,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'alice2026@outlook.com----Kf9!mNp2----client_id----refresh_token----2026-08-01',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          color: mutedFg,
        ),
      ),
    );
  }
}

/// 预览统计小标签。
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isLight ? color : color),
      ),
    );
  }
}
