import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  Future<void> _openGiveFeedback(BuildContext context) async {
    final created = await context.push<FeedbackModel?>('/feedback/give');
    if (created != null && mounted) {
      ref.read(feedbackFeedProvider.notifier).prependFeedback(created);
    }
  }

  String _formatDateTime(DateTime dt) {
    try {
      final local = dt.toLocal();
      final now = DateTime.now();
      final difference = now.difference(local);

      if (difference.inMinutes < 2) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24 && local.day == now.day) {
        return 'Today, ${DateFormat('HH:mm').format(local)}';
      } else if (difference.inDays < 2) {
        return 'Yesterday, ${DateFormat('HH:mm').format(local)}';
      } else {
        return DateFormat('dd MMM yyyy, HH:mm').format(local);
      }
    } catch (_) {
      return DateFormat('dd MMM yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final scaffoldBg = AppColors.background(context);
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);
    final borderColor = AppColors.border(context);

    final feedAsync = ref.watch(feedbackFeedProvider);
    final currentUserId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Customer Feedback',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openGiveFeedback(context),
              icon: const Icon(
                Icons.rate_review_outlined,
                size: 18,
                color: AppColors.coral,
              ),
              label: Text(
                'Give Feedback',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.coral,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.coral,
        foregroundColor: AppColors.white,
        elevation: 4,
        icon: const Icon(Icons.rate_review_rounded, size: 20),
        label: Text(
          'Give Feedback',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: () => _openGiveFeedback(context),
      ),
      body: SafeArea(
        child: feedAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppColors.coral,
              strokeWidth: 2.5,
            ),
          ),
          error: (error, _) {
            final errorStr = error.toString();
            final isTableMissing = errorStr.contains('PGRST205') ||
                errorStr.contains('schema cache') ||
                errorStr.contains('404') ||
                errorStr.contains('belum dibuat');

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.error,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isTableMissing
                          ? 'Tabel Belum Dibuat di Supabase'
                          : 'Gagal Memuat Feedback',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isTableMissing
                          ? 'Tabel feedbacks belum ada di schema database. Silakan jalankan file supabase_feedback_migration.sql di Supabase SQL Editor.'
                          : 'Terjadi kendala saat mengambil data feedback: $errorStr',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: subtextColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          ref.read(feedbackFeedProvider.notifier).fetchFeedbacks(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          },
          data: (feedbacks) {
            if (feedbacks.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : AppColors.butterYellow.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.butterYellow.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/splash/splash_frame_1.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.star_outline_rounded,
                              size: 42,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Belum Ada Feedback',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jadilah pelanggan pertama yang membagikan pengalaman bersantap Anda di Bun Atelier!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: subtextColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => _openGiveFeedback(context),
                        icon: const Icon(Icons.rate_review_rounded, size: 18),
                        label: Text(
                          'GIVE FEEDBACK',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Hitung rata-rata rating
            final totalRating = feedbacks.fold<double>(
              0.0,
              (sum, item) => sum + item.rating,
            );
            final averageRating = totalRating / feedbacks.length;

            return RefreshIndicator(
              color: AppColors.coral,
              backgroundColor: cardBg,
              onRefresh: () =>
                  ref.read(feedbackFeedProvider.notifier).fetchFeedbacks(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                itemCount: feedbacks.length + 1,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  // Index 0: Header Summary Card
                  if (index == 0) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                      child: Row(
                        children: [
                          // Average Score Box
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A623).withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF5A623).withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFF5A623),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      averageRating.toStringAsFixed(1),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? const Color(0xFFFFB84D)
                                            : const Color(0xFFC77800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'of 5.0',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Suara Pelanggan',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Berdasarkan ${feedbacks.length} ulasan autentik dari penikmat Bun Atelier.',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: subtextColor,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final item = feedbacks[index - 1];
                  final isOwnFeedback =
                      currentUserId != null && item.userId == currentUserId;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isOwnFeedback
                            ? AppColors.coral.withValues(alpha: 0.35)
                            : borderColor,
                        width: isOwnFeedback ? 1.4 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : AppColors.espresso.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: User / Author badge & Timestamp
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isOwnFeedback
                                    ? AppColors.coral.withValues(alpha: 0.15)
                                    : AppColors.forestGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isOwnFeedback
                                    ? Icons.person_rounded
                                    : Icons.storefront_rounded,
                                size: 17,
                                color: isOwnFeedback
                                    ? AppColors.coral
                                    : AppColors.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOwnFeedback
                                        ? 'Ulasan Anda (Terkirim)'
                                        : 'Pelanggan Bun Atelier',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isOwnFeedback
                                          ? AppColors.coral
                                          : textColor,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(item.createdAt),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Rating Bintang Mini
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5A623).withValues(
                                  alpha: isDark ? 0.2 : 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Color(0xFFF5A623),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.rating}.0',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFFFFB84D)
                                          : const Color(0xFFC77800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Row 2: Star Row Display
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(5, (sIdx) {
                            final isFilled = (sIdx + 1) <= item.rating;
                            return Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 18,
                                color: isFilled
                                    ? const Color(0xFFF5A623)
                                    : borderColor,
                              ),
                            );
                          }),
                        ),

                        // Row 3: Comment Text
                        if (item.comment != null &&
                            item.comment!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            item.comment!.trim(),
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: textColor,
                              height: 1.45,
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            'Memberikan rating tanpa komentar tertulis.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: subtextColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
