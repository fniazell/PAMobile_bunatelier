import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../models/app_feedback_model.dart';

class AppFeedbackHistoryCard extends StatelessWidget {
  final AppFeedbackModel feedback;

  const AppFeedbackHistoryCard({
    super.key,
    required this.feedback,
  });

  String _formatDateTime(DateTime dt) {
    try {
      final local = dt.toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(local);
    } catch (_) {
      return feedback.createdAt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surface(context);
    final borderColor = AppColors.border(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
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
          // ── Header: Date & Status Badge ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : AppColors.cream.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: subtextColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(feedback.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtextColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: AppColors.forestGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        feedback.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.forestGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Rating & Experience Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 20,
                            color: Color(0xFFFFB300),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            feedback.ratingOverall.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFD68910),
                            ),
                          ),
                          Text(
                            ' / 5.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppColors.forestGreenLight
                                : AppColors.forestGreen)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        feedback.overallExperience,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.forestGreenLight
                              : AppColors.forestGreen,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Cloud Sync Indicator
                    Tooltip(
                      message: feedback.isSynced
                          ? 'Tersinkron ke Cloud'
                          : 'Tersimpan di Perangkat (Lokal)',
                      child: Icon(
                        feedback.isSynced
                            ? Icons.cloud_done_rounded
                            : Icons.phone_android_rounded,
                        size: 18,
                        color: feedback.isSynced
                            ? AppColors.forestGreen
                            : subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Favorite Feature Chip
                Row(
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Fitur Favorit: ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subtextColor,
                      ),
                    ),
                    Text(
                      feedback.favoriteFeature,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 6 Aspect Mini Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : AppColors.cream.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAspectMini('UI (Tampilan)', feedback.ratingUi),
                          _buildAspectMini('UX (Kemudahan)', feedback.ratingUx),
                          _buildAspectMini('Navigasi', feedback.ratingNavigation),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAspectMini('Performa', feedback.ratingPerformance),
                          _buildAspectMini('Fungsional', feedback.ratingFunctionality),
                          _buildAspectMini('Kenyamanan', feedback.ratingComfort),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Kendala Section (jika ada)
                if (feedback.hadIssues &&
                    feedback.issueDescription != null &&
                    feedback.issueDescription!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.coral.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Kendala yang dialami:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.coral,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.issueDescription!,
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Saran & Masukan (jika ada)
                if (feedback.suggestions != null &&
                    feedback.suggestions!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.forestGreen.withValues(alpha: 0.15)
                          : AppColors.forestGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.forestGreen.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.format_quote_rounded,
                              size: 16,
                              color: AppColors.forestGreen,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Saran & Masukan:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.suggestions!,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectMini(String label, int score) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Icon(
              Icons.star_rounded,
              size: 13,
              color: Color(0xFFFFB300),
            ),
            Text(
              ' $score',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

