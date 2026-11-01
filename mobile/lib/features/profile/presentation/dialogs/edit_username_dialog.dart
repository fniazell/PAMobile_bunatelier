import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '_base_dialog.dart';

class EditUsernameDialog extends ConsumerStatefulWidget {
  final String currentUsername;
  const EditUsernameDialog({super.key, required this.currentUsername});

  @override
  ConsumerState<EditUsernameDialog> createState() =>
      _EditUsernameDialogState();
}

class _EditUsernameDialogState extends ConsumerState<EditUsernameDialog> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentUsername);
    _ctrl.addListener(() {
      setState(() => _dirty = _ctrl.text.trim() != widget.currentUsername);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ({bool inCooldown, DateTime? until}) _cooldownInfo() {
    final changedAt = ref.read(authProvider).user?.usernameChangedAt;
    if (changedAt == null) return (inCooldown: false, until: null);
    final until = changedAt.add(const Duration(days: 30));
    final inCooldown = DateTime.now().isBefore(until);
    return (inCooldown: inCooldown, until: until);
  }

  String _cooldownText(DateTime until) {
    final fmt = DateFormat('d MMMM yyyy', 'id');
    final days = until.difference(DateTime.now()).inDays + 1;
    return 'Anda bisa mengganti username lagi pada ${fmt.format(until)} (tersisa $days hari).';
  }

  Future<void> _save() async {
    final username = _ctrl.text.trim().toLowerCase();

    if (!RegExp(r'^[a-z0-9._]{3,20}$').hasMatch(username)) {
      setState(() => _error = '3–20 karakter: huruf, angka, titik, underscore.');
      return;
    }
    if (username == widget.currentUsername) {
      Navigator.pop(context, false);
      return;
    }

    final cd = _cooldownInfo();
    if (cd.inCooldown) {
      setState(() => _error = _cooldownText(cd.until!));
      return;
    }

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Username?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username baru: @$username'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.butterYellow.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.espresso, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anda hanya bisa mengganti username 1x dalam 30 hari.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL',
                style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _error = null);

    final (:result, :cooldownUntil) = await ref
        .read(authProvider.notifier)
        .updateProfile(username: username);

    if (!mounted) return;

    switch (result) {
      case UpdateProfileResult.success:
        Navigator.pop(context, true);
      case UpdateProfileResult.usernameTaken:
        setState(() => _error = 'Username sudah digunakan.');
      case UpdateProfileResult.usernameCooldown:
        setState(() => _error = cooldownUntil != null
            ? _cooldownText(cooldownUntil)
            : 'Anda bisa mengganti username lagi setelah 30 hari.');
      case UpdateProfileResult.validationError:
        setState(() => _error = '3–20 karakter: huruf, angka, titik, underscore.');
      default:
        setState(() => _error = 'Gagal menyimpan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final cd = _cooldownInfo();

    return BaseDialog(
      title: 'Username',
      isLoading: isLoading,
      saveEnabled: _dirty && !cd.inCooldown,
      onSave: _save,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          if (cd.inCooldown && _error == null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.butterYellow.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: AppColors.espresso, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _cooldownText(cd.until!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _ctrl,
            enabled: !cd.inCooldown,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'e.g. bun_lover88',
              prefixText: '@',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              helperText: '3–20 karakter: huruf, angka, titik, underscore',
            ),
          ),
          if (!cd.inCooldown)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Anda hanya bisa mengganti username 1x dalam 30 hari.',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText.withValues(alpha: 0.8)),
              ),
            ),
        ],
      ),
    );
  }
}
