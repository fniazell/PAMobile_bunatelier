import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../providers/settings_provider.dart';

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final textTheme = Theme.of(context).textTheme;
    final isDark = AppColors.isDark(context);

    final cardBg = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.espresso.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Settings ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Text(
              settings.t('settings_title'),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),

          // ── 1. Language ───────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.translate_rounded,
            iconColor: textColor,
            title: settings.t('language'),
            value: settings.languageName,
            textColor: textColor,
            valueColor: subtextColor,
            onTap: () => _showLanguageDialog(context, ref, settings),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // ── 2. Theme ──────────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.palette_outlined,
            iconColor: textColor,
            title: settings.t('theme'),
            value: settings.t(settings.isDark ? 'theme_dark' : 'theme_light'),
            textColor: textColor,
            valueColor: subtextColor,
            onTap: () => _showThemeDialog(context, ref, settings),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // ── 3. Notifications ──────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.notifications_none_rounded,
            iconColor: textColor,
            title: settings.t('notifications'),
            value: settings.t(
                settings.notificationsEnabled ? 'enabled' : 'disabled'),
            textColor: textColor,
            valueColor: subtextColor,
            onTap: () => _toggleNotifications(context, ref, settings),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // ── Bun Buddy AI ──────────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.auto_awesome,
            iconColor: AppColors.forestGreen,
            title: 'Bun Buddy AI',
            textColor: textColor,
            value: 'Konsultan Burger',
            valueColor: subtextColor,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 20,
            ),
            onTap: () => context.push('/buddy'),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // ── 4. Contact Support ────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.headset_mic_outlined,
            iconColor: textColor,
            title: settings.t('contact_support'),
            textColor: textColor,
            valueColor: subtextColor,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 20,
            ),
            onTap: () => context.push('/support-chat'),
          ),
          Divider(height: 1, indent: 56, color: borderColor),

          // ── 5. Saran & Pesan ──────────────────────────────────────────────
          _SettingsTile(
            icon: Icons.forum_outlined,
            iconColor: AppColors.forestGreen,
            title: 'Saran & Pesan',
            textColor: textColor,
            value: 'Mata Kuliah PAM',
            valueColor: subtextColor,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: subtextColor,
              size: 20,
            ),
            onTap: () => context.push('/saran-pesan'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Actions & Dialogs ─────────────────────────────────────────────────────

  void _showLanguageDialog(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (dialogCtx, dialogRef, _) {
          final curSettings = dialogRef.watch(settingsProvider);
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              curSettings.t('select_language'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RadioOption(
                  title: 'English',
                  subtitle: 'English (US / Global)',
                  isSelected: curSettings.languageCode == 'en',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await dialogRef.read(settingsProvider.notifier).setLanguage('en');
                    if (context.mounted) {
                      _showSnack(
                        context,
                        dialogRef.read(settingsProvider).t('lang_changed_en'),
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                _RadioOption(
                  title: 'Bahasa Indonesia',
                  subtitle: 'Bahasa Indonesia (ID)',
                  isSelected: curSettings.languageCode == 'id',
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await dialogRef.read(settingsProvider.notifier).setLanguage('id');
                    if (context.mounted) {
                      _showSnack(
                        context,
                        dialogRef.read(settingsProvider).t('lang_changed_id'),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  curSettings.t('cancel'),
                  style: TextStyle(color: subtextColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, SettingsState settings) {
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        builder: (dialogCtx, dialogRef, _) {
          final curSettings = dialogRef.watch(settingsProvider);
          return AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              curSettings.t('select_theme'),
              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RadioOption(
                  title: curSettings.t('theme_light'),
                  subtitle: curSettings.t('theme_light_desc'),
                  leadingIcon: Icons.wb_sunny_rounded,
                  leadingIconColor: AppColors.coral,
                  isSelected: curSettings.themeMode == ThemeMode.light,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await dialogRef
                        .read(settingsProvider.notifier)
                        .setThemeMode(ThemeMode.light);
                    if (context.mounted) {
                      _showSnack(
                        context,
                        dialogRef.read(settingsProvider).t('theme_set_light'),
                      );
                    }
                  },
                ),
                const SizedBox(height: 6),
                _RadioOption(
                  title: curSettings.t('theme_dark'),
                  subtitle: curSettings.t('theme_dark_desc'),
                  leadingIcon: Icons.nightlight_round,
                  leadingIconColor: AppColors.forestGreenLight,
                  isSelected: curSettings.themeMode == ThemeMode.dark,
                  textColor: textColor,
                  subtextColor: subtextColor,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await dialogRef
                        .read(settingsProvider.notifier)
                        .setThemeMode(ThemeMode.dark);
                    if (context.mounted) {
                      _showSnack(
                        context,
                        dialogRef.read(settingsProvider).t('theme_set_dark'),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  curSettings.t('cancel'),
                  style: TextStyle(color: subtextColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleNotifications(
      BuildContext context, WidgetRef ref, SettingsState settings) async {
    final next = !settings.notificationsEnabled;
    await ref.read(settingsProvider.notifier).setNotificationsEnabled(next);
    if (context.mounted) {
      final msg = next
          ? ref.read(settingsProvider).t('notif_enabled')
          : ref.read(settingsProvider).t('notif_disabled');
      _showSnack(context, msg);
    }
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.cream, fontSize: 13),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ── Supporting Widget: _SettingsTile ─────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final Color textColor;
  final Color valueColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    required this.textColor,
    required this.valueColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 21),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting Widget: _RadioOption ──────────────────────────────────────────

class _RadioOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final bool isSelected;
  final Color textColor;
  final Color subtextColor;
  final VoidCallback onTap;

  const _RadioOption({
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.leadingIconColor,
    required this.isSelected,
    required this.textColor,
    required this.subtextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.coral : Colors.transparent,
            width: 1.5,
          ),
          color: isSelected
              ? AppColors.coral.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: leadingIconColor, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: subtextColor),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.coral : subtextColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

