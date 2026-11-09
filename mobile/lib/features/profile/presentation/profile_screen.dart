import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../rewards/providers/rewards_provider.dart';
import '../providers/settings_provider.dart';
import 'widgets/settings_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SecureStorageService _storage = SecureStorageService();
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricPref();
  }

  ImageProvider? _buildAvatarProvider(String path) {
    try {
      if (path.startsWith('http')) return NetworkImage(path);
      return FileImage(File(path));
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadBiometricPref() async {
    final enabled = await _storage.isBiometricEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometrics(bool val) async {
    final enabled = await ref
        .read(authProvider.notifier)
        .setBiometricLoginEnabled(val);
    if (!mounted) return;

    if (enabled) setState(() => _biometricEnabled = val);
    final errorMessage = ref.read(authProvider).errorMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: enabled ? AppColors.forestGreen : AppColors.coral,
        content: Text(
          enabled
              ? (val
                    ? 'Login biometrik berhasil diaktifkan.'
                    : 'Login biometrik dinonaktifkan.')
              : errorMessage ?? 'Login biometrik gagal diatur.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showLogoutDialog(SettingsState settings) {
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          settings.t('confirm_sign_out'),
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        content: Text(
          settings.t('sign_out_message'),
          style: TextStyle(color: subtextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              settings.t('cancel'),
              style: TextStyle(color: subtextColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/login');
            },
            child: Text(settings.t('log_out')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);
    final user = authState.user;
    final rewardState = user == null
        ? null
        : ref.watch(rewardsProvider(user.id));
    final fullName = user?.fullName ?? 'Bun Gourmet';
    final email = user?.email ?? 'customer@bunatelier.com';
    final role = user?.role ?? 'CUSTOMER';

    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);
    final sectionHeaderColor = isDark ? AppColors.coral : AppColors.forestGreen;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: AppColors.background(context),
        elevation: 0,
        title: Text(
          settings.t('user_profile'),
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── User Card (tappable) ───────────────────────────────────────
              Material(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.push('/profile/edit'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
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
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.coral,
                          backgroundImage:
                              (user?.avatarPath != null &&
                                  user!.avatarPath!.isNotEmpty)
                              ? _buildAvatarProvider(user.avatarPath!)
                              : null,
                          child:
                              (user?.avatarPath == null ||
                                  user!.avatarPath!.isEmpty)
                              ? Text(
                                  fullName.isNotEmpty
                                      ? fullName[0].toUpperCase()
                                      : 'B',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: subtextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isDark
                                                  ? AppColors.coral
                                                  : AppColors.forestGreen)
                                              .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.coral
                                            : AppColors.forestGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    settings.t('edit_profile'),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.coral,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Chevron
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subtextColor,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (user != null) ...[
                const SizedBox(height: 12),
                Material(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.push('/rewards'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.coral,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUN POINTS',
                                  style: textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                    color: subtextColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  rewardState!.isLoading
                                      ? 'Memuat saldo...'
                                      : '${rewardState.totalPoints} poin',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                if (rewardState.errorMessage != null)
                                  Text(
                                    'Saldo tidak dapat dimuat',
                                    style: TextStyle(
                                      color: AppColors.coral,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: subtextColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Security & Preferences Section ─────────────────────────────
              Text(
                settings.t('security_prefs'),
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: sectionHeaderColor,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: AppColors.coral,
                      secondary: Icon(
                        Icons.fingerprint_rounded,
                        color: isDark
                            ? AppColors.forestGreenLight
                            : AppColors.forestGreen,
                      ),
                      title: Text(
                        settings.t('biometrics_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        settings.t('biometrics_subtitle'),
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      value: _biometricEnabled,
                      onChanged: _toggleBiometrics,
                    ),
                    Divider(height: 1, color: borderColor),
                    ListTile(
                      leading: Icon(
                        Icons.receipt_long_rounded,
                        color: isDark ? AppColors.coral : AppColors.espresso,
                      ),
                      title: Text(
                        settings.t('my_orders'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtextColor,
                      ),
                      onTap: () => context.push('/orders'),
                    ),
                    Divider(height: 1, color: borderColor),
                    ListTile(
                      leading: const Icon(
                        Icons.map_rounded,
                        color: AppColors.coral,
                      ),
                      title: Text(
                        settings.t('our_outlets'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtextColor,
                      ),
                      onTap: () => context.push('/outlets'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Settings Section (Reference Design) ────────────────────────
              const SettingsSection(),

              const SizedBox(height: 24),

              // ── Academic Utilities Section ─────────────────────────────────
              Text(
                settings.t('academic_tools'),
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: sectionHeaderColor,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.sports_esports_rounded,
                        color: Color(0xFF8E44AD),
                      ),
                      title: Text(
                        settings.t('mini_game'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        settings.t('mini_game_subtitle'),
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtextColor,
                      ),
                      onTap: () => context.push('/game'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Evaluasi Aplikasi Section ──────────────────────────────────
              Text(
                'EVALUASI APLIKASI',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: sectionHeaderColor,
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.rate_review_rounded,
                        color: AppColors.forestGreen,
                      ),
                      title: Text(
                        'Feedback Aplikasi',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        'Beri penilaian UI/UX & saran pengembangan aplikasi',
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: subtextColor,
                      ),
                      onTap: () => context.push('/app-feedback'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Sign Out Button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () => _showLogoutDialog(settings),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: Text(settings.t('sign_out')),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
