import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../app/theme/app_colors.dart';
import '../../auth/auth_service.dart';
import '../../auth/providers/auth_provider.dart';
import 'dialogs/edit_name_dialog.dart';
import 'dialogs/edit_username_dialog.dart';
import 'dialogs/edit_email_dialog.dart';
import 'dialogs/edit_phone_dialog.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  bool _avatarLoading = false;

  // ── Avatar helpers ────────────────────────────────────────────────────────

  ImageProvider? _avatarProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    try {
      if (path.startsWith('http')) return NetworkImage(path);
      return FileImage(File(path));
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    XFile? file;

    try {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 88,
      );
    } catch (e) {
      if (mounted) {
        _showSnack('Tidak bisa membuka galeri. Pastikan izin diberikan.', isError: true);
      }
      return;
    }

    if (file == null) return;

    // Validate size (2 MB max)
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      if (mounted) _showSnack('Ukuran file maksimal 2 MB.', isError: true);
      return;
    }

    // Validate mime type by magic bytes
    if (!_isAllowedImage(bytes)) {
      if (mounted) _showSnack('Hanya JPG, PNG, atau WEBP yang diperbolehkan.', isError: true);
      return;
    }

    setState(() => _avatarLoading = true);

    try {
      String savedPath;

      if (kIsWeb) {
        // On web, store the XFile path/blob URL directly
        savedPath = file.path;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final ext = p.extension(file.name).toLowerCase();
        final safeName =
            'avatar_${DateTime.now().millisecondsSinceEpoch}$ext';
        final dest = File(p.join(dir.path, safeName));
        await dest.writeAsBytes(bytes);
        savedPath = dest.path;

        // Delete old avatar file
        final oldPath = ref.read(authProvider).user?.avatarPath;
        if (oldPath != null && oldPath.isNotEmpty && oldPath != savedPath) {
          try {
            final old = File(oldPath);
            if (await old.exists()) await old.delete();
          } catch (_) {}
        }
      }

      await ref.read(authProvider.notifier).updateAvatar(savedPath);
      if (mounted) _showSnack('Foto profil berhasil diperbarui.');
    } catch (e) {
      if (mounted) _showSnack('Gagal menyimpan foto.', isError: true);
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Foto?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Foto profil akan dihapus dan diganti dengan avatar inisial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _avatarLoading = true);

    // Delete local file
    final oldPath = ref.read(authProvider).user?.avatarPath;
    if (oldPath != null && oldPath.isNotEmpty && !kIsWeb) {
      try {
        final f = File(oldPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }

    await ref.read(authProvider.notifier).updateAvatar(null);
    if (mounted) {
      setState(() => _avatarLoading = false);
      _showSnack('Foto profil dihapus.');
    }
  }

  bool _isAllowedImage(List<int> bytes) {
    if (bytes.length < 4) { return false; }
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) { return true; }
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E &&
        bytes[3] == 0x47) { return true; }
    // WEBP: 52 49 46 46 ... 57 45 42 50
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 &&
        bytes[3] == 0x46 && bytes[8] == 0x57 && bytes[9] == 0x45 &&
        bytes[10] == 0x42 && bytes[11] == 0x50) { return true; }
    return false;
  }

  // ── Snack helper ──────────────────────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          msg,
          style: const TextStyle(color: AppColors.cream, fontSize: 13),
        ),
      ),
    );
  }

  // ── Dialog launchers ──────────────────────────────────────────────────────

  Future<void> _openNameDialog(AuthUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditNameDialog(currentName: user.fullName),
    );
    if (result == true && mounted) _showSnack('Nama berhasil diperbarui.');
  }

  Future<void> _openUsernameDialog(AuthUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditUsernameDialog(currentUsername: user.username),
    );
    if (result == true && mounted) _showSnack('Username berhasil diperbarui.');
  }

  Future<void> _openEmailDialog(AuthUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditEmailDialog(currentEmail: user.email),
    );
    if (result == true && mounted) _showSnack('Email berhasil diperbarui.');
  }

  Future<void> _openPhoneDialog(AuthUser user) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditPhoneDialog(currentPhone: user.phone),
    );
    if (result == true && mounted) _showSnack('Nomor telepon berhasil diperbarui.');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authProvider).user;
    final fullName = user?.fullName ?? '';
    final username = user?.username ?? '';
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final avatarPath = user?.avatarPath;
    final hasAvatar = avatarPath != null && avatarPath.isNotEmpty;

    // Username cooldown info
    String? cooldownLabel;
    final changedAt = user?.usernameChangedAt;
    if (changedAt != null) {
      final until = changedAt.add(const Duration(days: 30));
      final remaining = until.difference(DateTime.now()).inDays;
      if (remaining > 0) {
        final day = until.day.toString().padLeft(2, '0');
        final month = _monthName(until.month);
        final year = until.year;
        cooldownLabel = 'Bisa diganti lagi pada $day $month $year (tersisa $remaining hari)';
      }
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.espresso),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EDIT PROFILE',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                children: [
                  // ── Avatar section ───────────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: AppColors.coral,
                        backgroundImage:
                            hasAvatar ? _avatarProvider(avatarPath) : null,
                        child: _avatarLoading
                            ? const SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : (!hasAvatar
                                ? Text(
                                    fullName.isNotEmpty
                                        ? fullName[0].toUpperCase()
                                        : 'B',
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  )
                                : null),
                      ),
                      // Camera button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _avatarLoading ? null : _showAvatarOptions,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.forestGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.cream, width: 2.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                color: AppColors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fullName,
                    style: textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@$username',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.mutedText),
                  ),
                  const SizedBox(height: 32),

                  // ── Edit menu card ───────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Foto Profil
                        _EditTile(
                          icon: Icons.photo_camera_rounded,
                          iconColor: AppColors.coral,
                          label: 'Foto Profil',
                          value: hasAvatar ? 'Ganti foto' : 'Belum ada foto',
                          onTap: _avatarLoading
                              ? null
                              : () => _showAvatarOptions(),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Nama Lengkap
                        _EditTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.forestGreen,
                          label: 'Nama Lengkap',
                          value: fullName.isEmpty ? 'Belum diisi' : fullName,
                          onTap: user == null
                              ? null
                              : () => _openNameDialog(user),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Username
                        _EditTile(
                          icon: Icons.alternate_email_rounded,
                          iconColor: AppColors.espresso,
                          label: 'Username',
                          value: username.isEmpty ? 'Belum diisi' : '@$username',
                          subtitle: cooldownLabel,
                          subtitleColor: AppColors.mutedText,
                          onTap: user == null
                              ? null
                              : () => _openUsernameDialog(user),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Email
                        _EditTile(
                          icon: Icons.mail_outline_rounded,
                          iconColor: const Color(0xFF2980B9),
                          label: 'Email',
                          value: email.isEmpty ? 'Belum diisi' : email,
                          onTap: user == null
                              ? null
                              : () => _openEmailDialog(user),
                        ),
                        const Divider(height: 1, indent: 56),

                        // Nomor Telepon
                        _EditTile(
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF16A085),
                          label: 'Nomor Telepon',
                          value: phone.isEmpty
                              ? 'Belum diisi'
                              : AuthService.formatPhone(phone),
                          onTap: user == null
                              ? null
                              : () => _openPhoneDialog(user),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarOptions() {
    final hasAvatar = (ref.read(authProvider).user?.avatarPath ?? '').isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.forestGreen),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar();
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  title: const Text('Hapus Foto',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.error)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded,
                    color: AppColors.mutedText),
                title: const Text('Batal',
                    style: TextStyle(color: AppColors.mutedText)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ][m];
}

// ─── _EditTile ────────────────────────────────────────────────────────────────

class _EditTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;

  const _EditTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                  fontSize: 11,
                  color: subtitleColor ?? AppColors.mutedText),
              maxLines: 2,
            )
          : Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right_rounded,
              color: AppColors.mutedText, size: 20)
          : null,
      onTap: onTap,
      minLeadingWidth: 0,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
