// Shared base dialog and error banner used by all Edit Profile dialogs.
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
// Re-export result enums so dialog files only need to import this file.
export '../../../auth/auth_service.dart'
    show UpdateProfileResult, EmailChangeResult;

// ─── BaseDialog ───────────────────────────────────────────────────────────────

class BaseDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onSave;
  final bool isLoading;
  final bool saveEnabled;

  const BaseDialog({
    super.key,
    required this.title,
    required this.content,
    this.onSave,
    this.isLoading = false,
    this.saveEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('BATAL',
              style: TextStyle(color: AppColors.mutedText)),
        ),
        ElevatedButton(
          onPressed: (isLoading || !saveEnabled) ? null : onSave,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: AppColors.white, strokeWidth: 2),
                )
              : const Text('SIMPAN'),
        ),
      ],
    );
  }
}

// ─── ErrorBanner ─────────────────────────────────────────────────────────────

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style:
                    const TextStyle(color: AppColors.error, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
