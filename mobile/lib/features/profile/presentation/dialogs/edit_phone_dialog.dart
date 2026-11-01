import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/auth_service.dart';
import '../../../auth/providers/auth_provider.dart';
import '_base_dialog.dart';

class EditPhoneDialog extends ConsumerStatefulWidget {
  final String currentPhone;
  const EditPhoneDialog({super.key, required this.currentPhone});

  @override
  ConsumerState<EditPhoneDialog> createState() => _EditPhoneDialogState();
}

class _EditPhoneDialogState extends ConsumerState<EditPhoneDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentPhone.isEmpty
          ? ''
          : AuthService.formatPhone(widget.currentPhone),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _ctrl.text.trim();
    setState(() => _error = null);

    final (:result, cooldownUntil: _) = await ref
        .read(authProvider.notifier)
        .updateProfile(phone: raw);

    if (!mounted) return;

    switch (result) {
      case UpdateProfileResult.success:
        Navigator.pop(context, true);
      case UpdateProfileResult.validationError:
        setState(() => _error =
            'Format tidak valid. Gunakan: 08xxxxxxxxxx atau +62xxxxxxxxx');
      default:
        setState(() => _error = 'Gagal menyimpan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return BaseDialog(
      title: 'Nomor Telepon',
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
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Nomor Telepon',
              hintText: '08xxxxxxxxxx atau +62xxxxxxxxxx',
              prefixIcon: Icon(Icons.phone_outlined),
              helperText: 'Boleh dikosongkan (opsional)',
            ),
          ),
        ],
      ),
    );
  }
}
