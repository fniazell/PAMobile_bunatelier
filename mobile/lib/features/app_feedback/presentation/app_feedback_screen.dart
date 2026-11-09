import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/app_feedback_model.dart';
import '../providers/app_feedback_provider.dart';
import 'widgets/aspect_rating_card.dart';
import 'widgets/app_feedback_history_card.dart';
import 'widgets/app_feedback_success_dialog.dart';

class AppFeedbackScreen extends ConsumerStatefulWidget {
  const AppFeedbackScreen({super.key});

  @override
  ConsumerState<AppFeedbackScreen> createState() => _AppFeedbackScreenState();
}

class _AppFeedbackScreenState extends ConsumerState<AppFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _suggestionsController = TextEditingController();

  static const List<String> _overallOptions = [
    'Sangat Baik',
    'Baik',
    'Cukup',
    'Kurang',
    'Sangat Kurang',
  ];

  static const List<String> _featureOptions = [
    'Home',
    'Menu dan Pemesanan',
    'Orders',
    'Rewards',
    'Mini Games',
    'Receipt',
    'Fitur lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final form = ref.read(appFeedbackFormProvider);
    _issueController.text = form.issueDescription;
    _suggestionsController.text = form.suggestions;

    _issueController.addListener(() {
      ref
          .read(appFeedbackFormProvider.notifier)
          .setIssueDescription(_issueController.text);
    });

    _suggestionsController.addListener(() {
      ref
          .read(appFeedbackFormProvider.notifier)
          .setSuggestions(_suggestionsController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _issueController.dispose();
    _suggestionsController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.coral,
          content: Text('Silakan login terlebih dahulu untuk mengirim feedback.'),
        ),
      );
      context.push('/login');
      return;
    }

    final formNotifier = ref.read(appFeedbackFormProvider.notifier);
    final success = await formNotifier.submitFeedback(
      userId: user.id,
      userName: user.fullName,
      userEmail: user.email,
    );

    if (!mounted) return;

    if (success) {
      _issueController.clear();
      _suggestionsController.clear();

      AppFeedbackSuccessDialog.show(
        context: context,
        onViewHistory: () {
          _tabController.animateTo(1);
        },
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/profile');
          }
        },
      );
    } else {
      final err = ref.read(appFeedbackFormProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coral,
          content: Text(err ?? 'Gagal mengirim feedback.'),
        ),
      );
    }
  }

  void _handleCancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/profile');
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

    final authState = ref.watch(authProvider);
    final user = authState.user;
    final currentUserId = user?.id ?? '';

    final formState = ref.watch(appFeedbackFormProvider);
    final formNotifier = ref.read(appFeedbackFormProvider.notifier);

    final historyAsync = currentUserId.isNotEmpty
        ? ref.watch(userAppFeedbackHistoryProvider(currentUserId))
        : const AsyncValue.data(<AppFeedbackModel>[]);

    final historyCount = historyAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: _handleCancel,
        ),
        title: Text(
          'Feedback Aplikasi',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.espresso.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.forestGreen,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.white,
              unselectedLabelColor: subtextColor,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Beri Penilaian'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text('Riwayat ($historyCount)'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: FORM PENILAIAN APLIKASI ────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.forestGreenLight
                            : AppColors.forestGreen)
                        .withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.forestGreen.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.mobile_friendly_rounded,
                        color: AppColors.forestGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Evaluasi Aplikasi Mobile Bun Atelier',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bantu kami meningkatkan performa, tampilan, dan kenyamanan aplikasi Bun Atelier dengan memberikan penilaian jujur Anda.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: subtextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── SECTION A: PENILAIAN PENGALAMAN PENGGUNA ──────────────────
                _buildSectionHeader(
                  context,
                  badge: 'BAGIAN A',
                  title: 'Penilaian Pengalaman Pengguna',
                  subtitle: 'Beri rating bintang 1–5 untuk setiap aspek performa dan tampilan aplikasi:',
                ),
                const SizedBox(height: 14),

                // 1. Tampilan aplikasi (UI)
                AspectRatingCard(
                  title: '1. Tampilan Aplikasi (UI)',
                  description: 'Apakah tampilan antarmuka aplikasi menarik, rapi, dan nyaman dilihat?',
                  icon: Icons.palette_outlined,
                  rating: formState.ratingUi,
                  onRatingChanged: formNotifier.setRatingUi,
                ),

                // 2. Kemudahan penggunaan (UX)
                AspectRatingCard(
                  title: '2. Kemudahan Penggunaan (UX)',
                  description: 'Apakah alur kerja dan fungsi aplikasi mudah dipahami dan digunakan?',
                  icon: Icons.touch_app_rounded,
                  rating: formState.ratingUx,
                  onRatingChanged: formNotifier.setRatingUx,
                ),

                // 3. Navigasi aplikasi
                AspectRatingCard(
                  title: '3. Navigasi Aplikasi',
                  description: 'Apakah Anda mudah berpindah dan menemukan menu serta fitur yang dibutuhkan?',
                  icon: Icons.explore_rounded,
                  rating: formState.ratingNavigation,
                  onRatingChanged: formNotifier.setRatingNavigation,
                ),

                // 4. Performa aplikasi
                AspectRatingCard(
                  title: '4. Performa Aplikasi',
                  description: 'Apakah aplikasi berjalan dengan cepat, mulus, dan responsif tanpa lag?',
                  icon: Icons.speed_rounded,
                  rating: formState.ratingPerformance,
                  onRatingChanged: formNotifier.setRatingPerformance,
                ),

                // 5. Fungsionalitas
                AspectRatingCard(
                  title: '5. Fungsionalitas Aplikasi',
                  description: 'Apakah seluruh fitur utama aplikasi berfungsi dengan baik sesuai kebutuhan Anda?',
                  icon: Icons.verified_rounded,
                  rating: formState.ratingFunctionality,
                  onRatingChanged: formNotifier.setRatingFunctionality,
                ),

                // 6. Kenyamanan penggunaan
                AspectRatingCard(
                  title: '6. Kenyamanan Penggunaan',
                  description: 'Apakah Anda merasa puas dan nyaman secara keseluruhan saat mengoperasikan aplikasi?',
                  icon: Icons.sentiment_very_satisfied_rounded,
                  rating: formState.ratingComfort,
                  onRatingChanged: formNotifier.setRatingComfort,
                ),

                const SizedBox(height: 20),

                // ── SECTION B: PERTANYAAN TAMBAHAN ───────────────────────────
                _buildSectionHeader(
                  context,
                  badge: 'BAGIAN B',
                  title: 'Pertanyaan Tambahan',
                  subtitle: 'Bagikan preferensi fitur dan pengalaman Anda selama ini:',
                ),
                const SizedBox(height: 14),

                // Pertanyaan 1: Pengalaman Keseluruhan
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Bagaimana pengalaman Anda secara keseluruhan menggunakan aplikasi Bun Atelier?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _overallOptions.map((opt) {
                          final isSelected = formState.overallExperience == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            onSelected: (_) =>
                                formNotifier.setOverallExperience(opt),
                            selectedColor: AppColors.forestGreen,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.espresso.withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.white : textColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.forestGreen
                                    : borderColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Pertanyaan 2: Fitur yang Paling Disukai
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Fitur apa yang paling Anda sukai?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _featureOptions.map((feat) {
                          final isSelected = formState.favoriteFeature == feat;
                          return ChoiceChip(
                            label: Text(feat),
                            selected: isSelected,
                            onSelected: (_) =>
                                formNotifier.setFavoriteFeature(feat),
                            selectedColor: AppColors.coral,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : AppColors.espresso.withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.white : textColor,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color:
                                    isSelected ? AppColors.coral : borderColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Pertanyaan 3: Kendala yang Dialami
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '3. Apakah Anda mengalami kendala saat menggunakan aplikasi?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: !formState.hadIssues
                                    ? AppColors.forestGreen
                                    : Colors.transparent,
                                foregroundColor: !formState.hadIssues
                                    ? AppColors.white
                                    : textColor,
                                side: BorderSide(
                                  color: !formState.hadIssues
                                      ? AppColors.forestGreen
                                      : borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => formNotifier.setHadIssues(false),
                              child: const Text(
                                'Tidak',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: formState.hadIssues
                                    ? AppColors.coral
                                    : Colors.transparent,
                                foregroundColor: formState.hadIssues
                                    ? AppColors.white
                                    : textColor,
                                side: BorderSide(
                                  color: formState.hadIssues
                                      ? AppColors.coral
                                      : borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => formNotifier.setHadIssues(true),
                              child: const Text(
                                'Ya',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Animated Kendala Input Field
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: formState.hadIssues
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        firstChild: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Text(
                              'Jelaskan kendala yang Anda alami:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _issueController,
                              maxLines: 3,
                              style: TextStyle(fontSize: 13, color: textColor),
                              decoration: InputDecoration(
                                hintText:
                                    'Contoh: Tombol pesanan lambat merespons, gambar menu belum tampil, dsb...',
                                hintStyle:
                                    TextStyle(fontSize: 12, color: subtextColor),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : AppColors.cream.withValues(alpha: 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: AppColors.coral),
                                ),
                              ),
                            ),
                          ],
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── SECTION C: SARAN DAN MASUKAN ─────────────────────────────
                _buildSectionHeader(
                  context,
                  badge: 'BAGIAN C',
                  title: 'Saran dan Masukan',
                  subtitle: 'Tuliskan kritik, masukan, maupun ide pengembangan untuk Bun Atelier:',
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apa saran atau masukan Anda untuk meningkatkan aplikasi Bun Atelier?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _suggestionsController,
                        maxLines: 4,
                        style: TextStyle(fontSize: 13, color: textColor),
                        decoration: InputDecoration(
                          hintText:
                              'Tuliskan saran Anda di sini (misal: tambah fitur filter kalori, notifikasi promo menarik, dll)...',
                          hintStyle:
                              TextStyle(fontSize: 12, color: subtextColor),
                          filled: true,
                          fillColor: isDark
                              ? Colors.black.withValues(alpha: 0.2)
                              : AppColors.cream.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.forestGreen),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── TOMBOL AKSI: KIRIM FEEDBACK & BATAL ───────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.forestGreen,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed:
                        formState.isSubmitting ? null : _handleSubmit,
                    child: formState.isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                        : const Text(
                            'Kirim Feedback',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtextColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: formState.isSubmitting ? null : _handleCancel,
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── TAB 2: RIWAYAT SAYA ───────────────────────────────────────────
          historyAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.forestGreen),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.coral,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat riwayat feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: TextStyle(fontSize: 12, color: subtextColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            data: (feedbacks) {
              if (feedbacks.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppColors.espresso.withValues(alpha: 0.04),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.rate_review_outlined,
                            size: 40,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Feedback Aplikasi',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda belum pernah mengirim evaluasi aplikasi Bun Atelier. Berikan penilaian Anda untuk membantu kami berkembang.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: subtextColor,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () => _tabController.animateTo(0),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Beri Penilaian Sekarang'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.forestGreen,
                onRefresh: () async {
                  if (currentUserId.isNotEmpty) {
                    await ref
                        .read(userAppFeedbackHistoryProvider(currentUserId).notifier)
                        .load();
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: feedbacks.length,
                  itemBuilder: (context, index) {
                    final item = feedbacks[index];
                    return AppFeedbackHistoryCard(feedback: item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String badge,
    required String title,
    required String subtitle,
  }) {
    final textColor = AppColors.text(context);
    final subtextColor = AppColors.subtext(context);
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.coral : AppColors.forestGreen)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.coral : AppColors.forestGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: subtextColor,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

