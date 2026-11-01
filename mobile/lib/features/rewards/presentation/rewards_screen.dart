import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../catalog/presentation/widgets/menu_tokens.dart';
import '../data/reward_repository.dart';
import '../models/voucher_model.dart';
import '../providers/rewards_provider.dart';
import '../providers/vouchers_provider.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final rewardState = user == null
        ? null
        : ref.watch(rewardsProvider(user.id));

    return Scaffold(
      backgroundColor: MenuTokens.background,
      appBar: AppBar(
        title: Text('Bun Points & Rewards', style: MenuTokens.serifHeading(fontSize: 20)),
        backgroundColor: MenuTokens.background,
        foregroundColor: MenuTokens.deepGreen,
        elevation: 0,
        actions: [
          if (user != null) ...[
            TextButton.icon(
              onPressed: () => context.push('/my-vouchers'),
              icon: const Icon(Icons.confirmation_number_outlined, size: 18, color: MenuTokens.coral),
              label: Text(
                'My Vouchers',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: MenuTokens.coral,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh points',
              onPressed: () =>
                  ref.read(rewardsProvider(user.id).notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: auth.isLoading && user == null
            ? const Center(
                child: CircularProgressIndicator(color: MenuTokens.deepGreen),
              )
            : user == null
            ? _buildSignedOut()
            : _buildRewards(context, ref, rewardState!),
      ),
    );
  }

  Widget _buildSignedOut() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Login untuk melihat Bun Points dan riwayat Stack Bun milikmu.',
          textAlign: TextAlign.center,
          style: MenuTokens.sansUI(color: MenuTokens.mutedText),
        ),
      ),
    );
  }

  Widget _buildRewards(BuildContext context, WidgetRef ref, RewardState state) {
    return RefreshIndicator(
      color: MenuTokens.deepGreen,
      onRefresh: () async {
        final userId = ref.read(authProvider).user?.id;
        if (userId != null) {
          await ref.read(rewardsProvider(userId).notifier).load();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildBalanceCard(state),
          const SizedBox(height: 14),
          _buildMyVouchersBanner(context),
          const SizedBox(height: 24),
          _buildVoucherRedeemSection(context, ref, state),
          const SizedBox(height: 24),
          _buildHowToEarnCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Text(
                  'RIWAYAT STACK BUN',
                  style: MenuTokens.sansUI(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: MenuTokens.deepGreen,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              Text(
                '${state.entries.length} sesi',
                style: MenuTokens.sansUI(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.isLoading && state.entries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: MenuTokens.deepGreen),
              ),
            )
          else if (state.errorMessage != null)
            _buildError(state.errorMessage!, ref)
          else if (state.entries.isEmpty)
            _buildEmptyHistory()
          else
            ...state.entries.map(_buildHistoryEntry),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(RewardState state) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: MenuTokens.deepGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MenuTokens.deepGreen.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: MenuTokens.butterYellow,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: MenuTokens.deepGreen,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL BUN POINTS',
                  style: MenuTokens.sansUI(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: MenuTokens.butterYellow,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.isLoading && state.entries.isEmpty
                      ? '...'
                      : NumberFormat('#,##0').format(state.totalPoints),
                  style: MenuTokens.serifHeading(
                    fontSize: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'PTS',
            style: MenuTokens.sansUI(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: MenuTokens.butterYellow,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MenuTokens.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MenuTokens.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            color: MenuTokens.coral,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mainkan Stack Bun',
                  style: MenuTokens.sansUI(
                    fontWeight: FontWeight.w900,
                    color: MenuTokens.deepGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Poin diberikan setelah sesi selesai. Skor, bahan yang tertumpuk, akurasi, dan kemenangan menentukan jumlahnya.',
                  style: MenuTokens.sansUI(
                    fontSize: 12,
                    height: 1.45,
                    color: MenuTokens.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rumus: skor ÷ 10 + 5/layer + 10/stack presisi + bonus menang 100; maksimum 500 poin per sesi.',
                  style: MenuTokens.sansUI(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MenuTokens.deepGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryEntry(RewardEntry entry) {
    final playedAt = DateFormat('dd MMM yyyy · HH:mm')
        .format(entry.playedAt.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: MenuTokens.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MenuTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sports_esports_rounded,
                color: MenuTokens.deepGreen,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  playedAt,
                  style: MenuTokens.sansUI(
                    fontSize: 11,
                    color: MenuTokens.mutedText,
                  ),
                ),
              ),
              Text(
                '+${entry.pointsAwarded} pts',
                style: MenuTokens.sansUI(
                  fontWeight: FontWeight.w900,
                  color: MenuTokens.deepGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Skor ${NumberFormat('#,##0').format(entry.score)}  ·  '
            '${entry.stackedIngredients}/15 bahan  ·  '
            '${entry.precisionHits} presisi${entry.victory ? '  ·  MENANG' : ''}',
            style: MenuTokens.sansUI(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: MenuTokens.deepGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: MenuTokens.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MenuTokens.borderLight),
      ),
      child: Text(
        'Belum ada sesi Stack Bun. Mainkan game untuk mulai mengumpulkan poin.',
        textAlign: TextAlign.center,
        style: MenuTokens.sansUI(height: 1.45),
      ),
    );
  }

  Widget _buildError(String message, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MenuTokens.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MenuTokens.coral),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: MenuTokens.sansUI(color: MenuTokens.mutedText),
          ),
          TextButton(
            onPressed: () {
              final userId = ref.read(authProvider).user?.id;
              if (userId != null) {
                ref.read(rewardsProvider(userId).notifier).load();
              }
            },
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVouchersBanner(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/my-vouchers'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MenuTokens.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: MenuTokens.coral.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.confirmation_number_rounded, color: MenuTokens.coral, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Vouchers (Voucher Saya)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: MenuTokens.deepGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lihat voucher aktif, terpakai, dan audit blockchain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: MenuTokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: MenuTokens.mutedText),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherRedeemSection(
    BuildContext context,
    WidgetRef ref,
    RewardState state,
  ) {
    final userId = ref.read(authProvider).user?.id;
    final voucherState = userId == null
        ? const VoucherState()
        : ref.watch(userVouchersProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TUKAR BUN POINTS',
              style: MenuTokens.sansUI(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: MenuTokens.deepGreen,
                letterSpacing: 1.4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '⚡ Blockchain Verified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF137333),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tukarkan poin hasil main Stack Bun menjadi voucher diskon belanja.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: MenuTokens.mutedText,
          ),
        ),
        const SizedBox(height: 12),

        // Voucher 1: 5% (15 points)
        _buildRedeemCard(
          context: context,
          ref: ref,
          type: VoucherType.discount5,
          currentPoints: state.totalPoints,
          isRedeeming: voucherState.isRedeeming,
        ),
        const SizedBox(height: 10),

        // Voucher 2: 15% (350 points)
        _buildRedeemCard(
          context: context,
          ref: ref,
          type: VoucherType.discount15,
          currentPoints: state.totalPoints,
          isRedeeming: voucherState.isRedeeming,
        ),
        const SizedBox(height: 10),

        // Voucher 3: 20% (500 points)
        _buildRedeemCard(
          context: context,
          ref: ref,
          type: VoucherType.discount20,
          currentPoints: state.totalPoints,
          isRedeeming: voucherState.isRedeeming,
        ),
      ],
    );
  }

  Widget _buildRedeemCard({
    required BuildContext context,
    required WidgetRef ref,
    required VoucherType type,
    required int currentPoints,
    required bool isRedeeming,
  }) {
    final hasEnoughPoints = currentPoints >= type.pointsCost;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEnoughPoints
              ? MenuTokens.deepGreen.withValues(alpha: 0.15)
              : MenuTokens.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Discount Badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasEnoughPoints ? MenuTokens.coral : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '${type.discountPercent}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Points Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: MenuTokens.deepGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Biaya: ${type.pointsCost} Poin',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: hasEnoughPoints ? MenuTokens.coral : MenuTokens.mutedText,
                  ),
                ),
                Text(
                  type.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: MenuTokens.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Redeem Button with Anti-Double-Click Guard
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: (!hasEnoughPoints || isRedeeming)
                  ? null
                  : () => _handleRedeem(context, ref, type, hasEnoughPoints, currentPoints),
              style: ElevatedButton.styleFrom(
                backgroundColor: MenuTokens.deepGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isRedeeming
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      hasEnoughPoints ? 'TUKAR' : 'Poin Kurang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRedeem(
    BuildContext context,
    WidgetRef ref,
    VoucherType type,
    bool hasEnoughPoints,
    int currentPoints,
  ) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    if (!hasEnoughPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poin tidak mencukupi! Butuh ${type.pointsCost} poin, kamu memiliki $currentPoints poin.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final voucher = await ref
          .read(userVouchersProvider(userId).notifier)
          .redeemVoucher(type);

      if (context.mounted) {
        _showRedeemSuccessDialog(context, voucher);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Penukaran gagal: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRedeemSuccessDialog(BuildContext context, VoucherModel voucher) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF137333), size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Penukaran Berhasil!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: MenuTokens.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat! Kamu berhasil menukarkan ${voucher.pointsCost} Bun Points untuk ${voucher.type.title}.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Voucher Code Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MenuTokens.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MenuTokens.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KODE PROMO KAMU',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: MenuTokens.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          voucher.code,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: MenuTokens.deepGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: MenuTokens.coral, size: 18),
                      tooltip: 'Salin kode',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: voucher.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Kode ${voucher.code} disalin!'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Blockchain Audit Notification
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF34A853), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 18, color: Color(0xFF137333)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pencatatan penukaran sedang dikonfirmasi ke blockchain ledger.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF137333),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Tutup',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: MenuTokens.mutedText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.push('/my-vouchers');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MenuTokens.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Buka My Vouchers',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}
