import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/models/order_model.dart';
import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';
import '../services/feedback_service.dart';
import 'widgets/feedback_success_dialog.dart';

class GiveFeedbackScreen extends ConsumerStatefulWidget {
  final OrderItemModel? order;
  final String? orderId;
  final String? customerName;

  const GiveFeedbackScreen({
    super.key,
    this.order,
    this.orderId,
    this.customerName,
  });

  @override
  ConsumerState<GiveFeedbackScreen> createState() => _GiveFeedbackScreenState();
}

class _GiveFeedbackScreenState extends ConsumerState<GiveFeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocus = FocusNode();

  int _rating = 0;
  bool _isSubmitting = false;
  String? _validationError;

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _onStarTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _rating = index;
      _validationError = null;
    });
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Needs Improvement';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Exceptional!';
      default:
        return 'Select a rating';
    }
  }

  Future<void> _submitFeedback() async {
    // Dismiss keyboard
    _commentFocus.unfocus();

    // 1. Validasi rating wajib dipilih
    if (_rating < 1 || _rating > 5) {
      setState(() {
        _validationError = 'Please select a star rating before publishing.';
      });
      _showFeedbackSnackBar(
        message: 'Rating wajib dipilih sebelum feedback dikirim.',
        isError: true,
      );
      return;
    }

    // 2. Ambil user id dari autentikasi pengguna yang sudah ada
    final authUser = ref.read(authProvider).user;
    String? userId = widget.order?.userId ?? authUser?.id;

    if (userId == null || userId.isEmpty) {
      final localUserData = await SecureStorageService().getUserData();
      userId = localUserData?['id'] as String?;
    }

    if (userId == null || userId.isEmpty) {
      // Jika guest atau belum login, gunakan UUID order jika ada atau minta login
      userId = authUser?.id;
    }

    if (userId == null || userId.isEmpty) {
      setState(() {
        _validationError = 'Silakan login terlebih dahulu untuk mengirim feedback.';
      });
      _showFeedbackSnackBar(
        message: 'Autentikasi akun tidak ditemukan. Silakan login kembali.',
        isError: true,
      );
      return;
    }

    // 3. Tentukan Order ID yang terhubung
    final orderId = widget.order?.id ??
        widget.order?.orderNumber ??
        widget.orderId ??
        'order-${DateTime.now().millisecondsSinceEpoch}';

    final customerName = widget.order?.customerName ??
        widget.customerName ??
        authUser?.fullName ??
        'Pelanggan Bun Atelier';

    setState(() {
      _isSubmitting = true;
      _validationError = null;
    });

    final commentText = _commentController.text.trim();
    final feedback = FeedbackModel(
      orderId: orderId,
      userId: userId,
      customerName: customerName,
      rating: _rating,
      comment: commentText.isEmpty ? null : commentText,
      createdAt: DateTime.now().toUtc(),
    );

    try {
      final feedbackService = ref.read(feedbackServiceProvider);
      final result = await feedbackService.submitFeedback(feedback);

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _isSubmitting = false;
        });

        final createdFeedback = result.feedback ?? feedback;
        ref
            .read(feedbackFeedProvider.notifier)
            .prependFeedback(createdFeedback);

        // Tampilkan success dialog
        final dismissed = await FeedbackSuccessDialog.show(context);
        if (dismissed == true && mounted) {
          context.pop(createdFeedback);
        }
      } else {
        setState(() {
          _isSubmitting = false;
          _validationError = result.errorMessage ??
              'Gagal mengirim feedback ke Supabase. Silakan coba beberapa saat lagi.';
        });
        _showFeedbackSnackBar(
          message: result.errorMessage ?? 'Gagal menyimpan feedback ke server.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _validationError = 'Terjadi kesalahan tidak terduga: $e';
      });
      _showFeedbackSnackBar(
        message: 'Gagal mengirim feedback: $e',
        isError: true,
      );
    }
  }

  void _showFeedbackSnackBar({
    required String message,
    required bool isError,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: AppColors.cream,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final cardBg = AppColors.surface(context);
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);
    final borderColor = AppColors.border(context);
    final scaffoldBg = AppColors.background(context);
    final order = widget.order;

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
          'Give Feedback',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Order Info Banner (if linked to order) ─────────────
                      if (order != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : AppColors.espresso.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 16,
                                        color: AppColors.forestGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        order.orderNumber,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'COMPLETED',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.forestGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (order.itemsSummary.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  order.itemsSummary,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (order.branchName != null &&
                                  order.branchName!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront_rounded,
                                      size: 13,
                                      color: AppColors.coral,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      order.branchName!,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: AppColors.coral,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Card 1: Star Rating Section ─────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
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
                        child: Column(
                          children: [
                            // Heading: How did we do?
                            Text(
                              'How did we do?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap a star to rate your dining experience',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: subtextColor,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Interactive 1-5 Star Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                final starNumber = index + 1;
                                final isSelected = starNumber <= _rating;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: InkWell(
                                    onTap: _isSubmitting
                                        ? null
                                        : () => _onStarTapped(starNumber),
                                    borderRadius: BorderRadius.circular(30),
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.08 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isSelected
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          size: 38,
                                          color: isSelected
                                              ? const Color(0xFFF5A623)
                                              : borderColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),

                            // Dynamic Rating Caption Pill
                            const SizedBox(height: 14),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _rating > 0
                                    ? const Color(0xFFF5A623).withValues(
                                        alpha: isDark ? 0.2 : 0.12,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _rating > 0
                                      ? const Color(0xFFF5A623).withValues(
                                          alpha: 0.4,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                _getRatingLabel(_rating),
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _rating > 0
                                      ? (isDark
                                          ? const Color(0xFFFFB84D)
                                          : const Color(0xFFC77800))
                                      : subtextColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Card 2: Comment Section ─────────────────────────────
                      Container(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Heading: Care to share more about it?
                            Text(
                              'Care to share more about it?',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tell us what went well or where we can improve (optional)',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Text area
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkScaffold
                                    : AppColors.cream.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.0,
                                ),
                              ),
                              child: TextField(
                                controller: _commentController,
                                focusNode: _commentFocus,
                                enabled: !_isSubmitting,
                                maxLines: 5,
                                minLines: 4,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: textColor,
                                  height: 1.45,
                                ),
                                cursorColor: AppColors.coral,
                                decoration: InputDecoration(
                                  hintText:
                                      'Tell us about your experience with Bun Atelier...',
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: subtextColor.withValues(alpha: 0.7),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Inline Validation Error Banner ─────────────────────
                      if (_validationError != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _validationError!,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action: PUBLISH FEEDBACK Button ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  border: Border(
                    top: BorderSide(color: borderColor, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.espresso.withValues(
                        alpha: isDark ? 0.35 : 0.05,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor:
                          AppColors.coral.withValues(alpha: 0.6),
                      disabledForegroundColor:
                          AppColors.white.withValues(alpha: 0.8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'PUBLISH FEEDBACK',
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
