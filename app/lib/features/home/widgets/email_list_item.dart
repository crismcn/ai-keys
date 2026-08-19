import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/widgets/app_button.dart';
import '../../../core/design_system/widgets/status_badge.dart';
import '../../../core/models/email_account.dart';

/// 邮箱列表项。
///
/// 行为：
/// - 点击整行 → 复制 `帐号：xxx 密码：xxx`
/// - 右侧「激活」按钮 → 进入激活详情页（已激活则显示状态）
/// - 已激活项用翠绿玻璃底色 + 渐变头像 + 辉光圆点区分
class EmailListItem extends StatelessWidget {
  const EmailListItem({
    super.key,
    required this.account,
    required this.onActivate,
    this.showDecoration = true,
  });

  final EmailAccount account;
  final VoidCallback onActivate;

  /// 是否显示卡片样式（列表分页内为 true）。
  final bool showDecoration;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: account.copyText));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('已复制：${account.copyText}')));
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? AppColors.foreground : AppColors.foregroundDark;
    final mutedFg =
        isLight ? AppColors.mutedForeground : AppColors.mutedForegroundDark;
    final activated = account.activated;
    final success = isLight ? AppColors.success : AppColors.successDark;

    // 已激活项：翠绿玻璃底色；未激活项：透明。
    final bg = activated
        ? (isLight
            ? AppColors.successSoft
            : success.withValues(alpha: 0.09))
        : Colors.transparent;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copy(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
          child: Row(
            children: [
              // 头像（首字母）：霓虹渐变圆。
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: activated
                      ? AppColors.emeraldGradient
                      : AppColors.brand,
                  shape: BoxShape.circle,
                  boxShadow: AppGlow.of(
                    activated ? success : AppColors.indigo,
                    blur: 10,
                    alpha: isLight ? 0.35 : 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  account.account.isEmpty ? '?' : account.account[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // 帐号 + 密码
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.account,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.maskedPassword,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: mutedFg,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (activated)
                          const StatusBadge.available()
                        else
                          const StatusBadge.pending(),
                      ],
                    ),
                  ],
                ),
              ),
              // 右侧操作
              if (activated)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: success,
                  ),
                )
              else
                AppButton(
                  label: '激活',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.bolt_rounded,
                  onPressed: onActivate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
