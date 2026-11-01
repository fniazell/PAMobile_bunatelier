import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '_base_dialog.dart';

class EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;
  const EditNameDialog({super.key, required this.currentName});

  @override
  ConsumerState<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<EditNameDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama lengkap wajib diisi.');
      return;
    }
    if (name.length > 50) {
      setState(() => _error = 'Nama maksimal 50 karakter.');
      return;
    }
    setState(() => _error = null);

    final (:result, cooldownUntil: _) = await ref
        .read(authProvider.notifier)
        .updateProfile(fullName: name);

    if (!mounted) return;
    if (result == UpdateProfileResult.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = 'Gagal menyimpan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return BaseDialog(
      title: 'Nama Lengkap',
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
            textCapitalization: TextCapitalization.words,
            maxLength: 50,
            decoration: const InputDecoration(
              labelText: 'Nama Lengkap',
              hintText: 'e.g. Raditya Dika',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
