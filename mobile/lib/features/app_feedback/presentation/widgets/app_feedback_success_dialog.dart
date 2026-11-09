import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';

class AppFeedbackSuccessDialog extends StatelessWidget {
  final VoidCallback onViewHistory;
  final VoidCallback onBack;

  const AppFeedbackSuccessDialog({
    super.key,
    required this.onViewHistory,
    required this.onBack,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onViewHistory,
    required VoidCallback onBack,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AppFeedbackSuccessDialog(
        onViewHistory: onViewHistory,
        onBack: onBack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Appreciation Badge
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 46,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Feedback Terkirim!',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'Terima kasih telah meluangkan waktu mengevaluasi aplikasi Bun Atelier. Penilaian dan saran Anda sangat berarti bagi pengembangan aplikasi kami.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: subtextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onViewHistory();
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text(
                  'Lihat Riwayat Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: subtextColor,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onBack();
                },
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

