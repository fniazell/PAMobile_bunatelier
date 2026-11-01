import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '_base_dialog.dart';

class EditEmailDialog extends ConsumerStatefulWidget {
  final String currentEmail;
  const EditEmailDialog({super.key, required this.currentEmail});

  @override
  ConsumerState<EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends ConsumerState<EditEmailDialog> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePw = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newEmail = _emailCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    if (!newEmail.contains('@') || newEmail.isEmpty) {
      setState(() => _error = 'Masukkan alamat email yang valid.');
      return;
    }
    if (newEmail == widget.currentEmail) {
      Navigator.pop(context, false);
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Masukkan password saat ini untuk konfirmasi.');
      return;
    }
    setState(() => _error = null);

    final result = await ref
        .read(authProvider.notifier)
        .changeEmail(newEmail: newEmail, currentPassword: password);

    if (!mounted) return;

    switch (result) {
      case EmailChangeResult.success:
        Navigator.pop(context, true);
      case EmailChangeResult.wrongPassword:
        setState(() => _error = 'Password salah.');
      case EmailChangeResult.emailTaken:
        setState(() => _error = 'Email sudah terdaftar oleh akun lain.');
      case EmailChangeResult.validationError:
        setState(() => _error = 'Format email tidak valid.');
      default:
        setState(() => _error = 'Gagal menyimpan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return BaseDialog(
      title: 'Ganti Email',
      isLoading: isLoading,
      onSave: _save,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.forestGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email baru akan langsung digunakan untuk login berikutnya.',
                    style: TextStyle(fontSize: 12, color: AppColors.forestGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email Baru',
              hintText: 'nama@example.com',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePw,
            decoration: InputDecoration(
              labelText: 'Password Saat Ini',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePw
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscurePw = !_obscurePw),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
