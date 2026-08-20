import 'package:flutter/material.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/models/email_account.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/tokens/app_tokens.dart';
import '../../../widgets/avatar.dart';
import '../../../widgets/buttons.dart';

/// Single row in the email list.
class EmailListItem extends StatelessWidget {
  const EmailListItem({
    super.key,
    required this.account,
    required this.onTap,
    required this.onActivate,
    this.colorIndex,
  });

  final EmailAccount account;
  final VoidCallback onTap;
  final VoidCallback onActivate;
  final int? colorIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: 14),
          child: Row(
            children: [
              LetterAvatar(
                name: account.email,
                letter: account.initial,
                size: 44,
                colorIndex: colorIndex,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '••••••••',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1,
                            color: context.c.textSecondary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusDot(activated: account.activated),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (!account.activated)
                SoftPillButton(label: context.s.activate, onPressed: onActivate),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded,
                  color: context.c.neutral, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
