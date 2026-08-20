import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../core/tokens/app_tokens.dart';
import '../../widgets/section_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                context.s.navSettings,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: context.c.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            _sectionLabel(context, context.s.sectionAppearance),
            _appearanceCard(context, settings),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel(context, context.s.sectionLanguage),
            _languageCard(context, settings),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel(context, context.s.sectionAbout),
            _aboutCard(context),
          ],
        ),
      ),
    );
  }
  // _SETTINGS_BODY_

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.c.textSecondary,
          ),
        ),
      );

  Widget _appearanceCard(BuildContext context, SettingsController settings) {
    final options = <(ThemeMode, IconData, String)>[
      (ThemeMode.light, Icons.light_mode_outlined, context.s.themeLight),
      (ThemeMode.dark, Icons.dark_mode_outlined, context.s.themeDark),
      (ThemeMode.system, Icons.brightness_auto_outlined, context.s.themeSystem),
    ];
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < options.length; i++) ...[
            if (i > 0) Divider(height: 1, color: context.c.border),
            _optionRow(
              context,
              icon: options[i].$2,
              label: options[i].$3,
              selected: settings.themeMode == options[i].$1,
              onTap: () => settings.setThemeMode(options[i].$1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _languageCard(BuildContext context, SettingsController settings) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Column(
        children: [
          _optionRow(
            context,
            icon: Icons.translate_rounded,
            label: context.s.langZh,
            selected: settings.locale.languageCode == 'zh',
            onTap: () => settings.setLocale(const Locale('zh')),
          ),
          Divider(height: 1, color: context.c.border),
          _optionRow(
            context,
            icon: Icons.language_rounded,
            label: context.s.langEn,
            selected: false,
            enabled: false,
            trailingText: context.s.langEnComingSoon,
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context) {
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.s.aboutVersion,
            style: TextStyle(fontSize: 14, color: context.c.textPrimary),
          ),
          Text(
            'v1.0.0',
            style: TextStyle(fontSize: 14, color: context.c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _optionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    bool enabled = true,
    String? trailingText,
  }) {
    final fg = enabled ? context.c.textPrimary : context.c.neutral;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: enabled ? context.c.textSecondary : context.c.neutral),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: fg),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(fontSize: 12, color: context.c.neutral),
              ),
            if (selected)
              const Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
