import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/saran_pesan_model.dart';
import '../providers/saran_pesan_provider.dart';
import 'widgets/saran_pesan_history_card.dart';

class SaranPesanScreen extends ConsumerStatefulWidget {
  const SaranPesanScreen({super.key});

  @override
  ConsumerState<SaranPesanScreen> createState() => _SaranPesanScreenState();
}

class _SaranPesanScreenState extends ConsumerState<SaranPesanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _saranController = TextEditingController();
  final TextEditingController _pesanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final form = ref.read(saranPesanFormProvider);
    _saranController.text = form.saran;
    _pesanController.text = form.pesan;

    _saranController.addListener(() {
      ref
          .read(saranPesanFormProvider.notifier)
          .setSaran(_saranController.text);
    });

    _pesanController.addListener(() {
      ref
          .read(saranPesanFormProvider.notifier)
          .setPesan(_pesanController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _saranController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final saranText = _saranController.text.trim();
    final pesanText = _pesanController.text.trim();

    // Validasi 1: Saran tidak boleh kosong
    if (saranText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kolom Saran untuk Mata Kuliah wajib diisi.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Validasi 2: Pesan tidak boleh kosong
    if (pesanText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kolom Pesan untuk Dosen Pengampu wajib diisi.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Validasi 3: Pengguna harus login
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null || user.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          content: Text('Silakan login terlebih dahulu untuk mengirim saran dan pesan.'),
        ),
      );
      context.push('/login');
      return;
    }

    // Kirim data
    final formNotifier = ref.read(saranPesanFormProvider.notifier);
    final success = await formNotifier.submit(
      userId: user.id,
      userName: user.fullName,
      userEmail: user.email,
    );

    if (!mounted) return;

    if (success) {
      _saranController.clear();
      _pesanController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Saran & Pesan berhasil dikirim dan tersimpan!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

      // Pindahkan langsung ke tab Riwayat
      _tabController.animateTo(1);
    } else {
      final err = ref.read(saranPesanFormProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.coral,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  err ?? 'Gagal mengirim saran dan pesan. Silakan coba lagi.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
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

    final formState = ref.watch(saranPesanFormProvider);

    final historyAsync = currentUserId.isNotEmpty
        ? ref.watch(userSaranPesanHistoryProvider(currentUserId))
        : const AsyncValue.data(<SaranPesanModel>[]);

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Saran & Pesan',
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
                      Icon(Icons.edit_note_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Tulis Saran & Pesan'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 18),
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
          // ── TAB 1: FORMULIR SARAN & PESAN ──────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner Deskripsi Resmi
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.school_rounded,
                            color: isDark
                                ? AppColors.forestGreenLight
                                : AppColors.forestGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Pemrograman Aplikasi Mobile',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan sampaikan saran dan pesan Anda terkait mata kuliah Pemrograman Aplikasi Mobile. Masukan yang diberikan dapat menjadi bahan evaluasi dan perbaikan untuk pembelajaran selanjutnya.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: subtextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── KOLOM A: SARAN UNTUK MATA KULIAH ─────────────────────────
                Text(
                  'Saran untuk Mata Kuliah',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Materi, metode pembelajaran, praktikum, atau tugas',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _saranController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 13.5, color: textColor),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan saran Anda terkait materi, metode pembelajaran, praktikum, atau tugas mata kuliah Pemrograman Aplikasi Mobile...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: subtextColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── KOLOM B: PESAN UNTUK DOSEN PENGAMPU ──────────────────────
                Text(
                  'Pesan untuk Dosen Pengampu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pesan, kesan, atau ucapan yang ingin Anda sampaikan',
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: TextField(
                    controller: _pesanController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 13.5, color: textColor),
                    decoration: InputDecoration(
                      hintText:
                          'Tuliskan pesan, kesan, atau hal yang ingin Anda sampaikan kepada dosen pengampu...',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: subtextColor.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── TOMBOL KIRIM SARAN & PESAN ───────────────────────────────
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
                    onPressed: formState.isSubmitting ? null : _handleSubmit,
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
                            'Kirim Saran & Pesan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // ── TAB 2: RIWAYAT SARAN & PESAN ──────────────────────────────────
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
                      'Gagal memuat riwayat',
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
            data: (items) {
              if (items.isEmpty) {
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
                            Icons.forum_outlined,
                            size: 40,
                            color: subtextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Riwayat',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda belum pernah mengirim saran dan pesan mata kuliah Pemrograman Aplikasi Mobile.',
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
                          icon: const Icon(Icons.edit_note_rounded, size: 18),
                          label: const Text('Tulis Sekarang'),
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
                        .read(userSaranPesanHistoryProvider(currentUserId).notifier)
                        .load();
                  }
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return SaranPesanHistoryCard(item: item);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
