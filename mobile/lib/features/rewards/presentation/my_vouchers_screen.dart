import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/presentation/widgets/menu_tokens.dart';
import '../models/voucher_model.dart';
import '../providers/rewards_provider.dart';
import '../providers/vouchers_provider.dart';

class MyVouchersScreen extends ConsumerStatefulWidget {
  const MyVouchersScreen({super.key});

  @override
  ConsumerState<MyVouchersScreen> createState() => _MyVouchersScreenState();
}

class _MyVouchersScreenState extends ConsumerState<MyVouchersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final fallbackUserId = ref.watch(currentRewardUserIdProvider);
    final userId = authUser?.id ??
        (fallbackUserId != null && fallbackUserId.isNotEmpty ? fallbackUserId : null);

    if (userId == null) {
      return Scaffold(
        backgroundColor: MenuTokens.background,
        appBar: AppBar(
          title: Text('My Vouchers', style: MenuTokens.serifHeading(fontSize: 20)),
          backgroundColor: MenuTokens.background,
          foregroundColor: MenuTokens.deepGreen,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Silakan login terlebih dahulu untuk melihat voucher milikmu.',
              style: MenuTokens.sansUI(color: MenuTokens.mutedText),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final voucherState = ref.watch(userVouchersProvider(userId));

    return Scaffold(
      backgroundColor: MenuTokens.background,
      appBar: AppBar(
        title: Text('My Vouchers', style: MenuTokens.serifHeading(fontSize: 22)),
        backgroundColor: MenuTokens.background,
        foregroundColor: MenuTokens.deepGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan voucher',
            onPressed: () =>
                ref.read(userVouchersProvider(userId).notifier).loadVouchers(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: MenuTokens.deepGreen,
          unselectedLabelColor: MenuTokens.mutedText,
          indicatorColor: MenuTokens.coral,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Tersedia (${voucherState.availableVouchers.length})'),
            Tab(text: 'Terpakai (${voucherState.usedVouchers.length})'),
            Tab(text: 'Kedaluwarsa (${voucherState.expiredVouchers.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: voucherState.isLoading && voucherState.vouchers.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: MenuTokens.deepGreen),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildVoucherList(
                    voucherState.availableVouchers,
                    emptyMessage: 'Belum ada voucher tersedia.\nTukarkan Bun Points milikmu di menu Rewards!',
                    isAvailableTab: true,
                  ),
                  _buildVoucherList(
                    voucherState.usedVouchers,
                    emptyMessage: 'Belum ada voucher yang digunakan.',
                    isAvailableTab: false,
                  ),
                  _buildVoucherList(
                    voucherState.expiredVouchers,
                    emptyMessage: 'Tidak ada voucher yang kedaluwarsa.',
                    isAvailableTab: false,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVoucherList(
    List<VoucherModel> list, {
    required String emptyMessage,
    required bool isAvailableTab,
  }) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: MenuTokens.cardSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: MenuTokens.borderLight),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 36,
                  color: MenuTokens.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: MenuTokens.sansUI(
                  fontSize: 13,
                  height: 1.5,
                  color: MenuTokens.mutedText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: MenuTokens.deepGreen,
      onRefresh: () async {
        final userId = ref.read(authProvider).user?.id;
        if (userId != null) {
          await ref.read(userVouchersProvider(userId).notifier).loadVouchers();
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: list.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final voucher = list[index];
          return _buildVoucherCard(voucher, isAvailableTab: isAvailableTab);
        },
      ),
    );
  }

  Widget _buildVoucherCard(VoucherModel voucher, {required bool isAvailableTab}) {
    final isConfirmed = voucher.blockchainStatus == BlockchainStatus.confirmed;
    final isPending = voucher.blockchainStatus == BlockchainStatus.pending;
    final isFailed = voucher.blockchainStatus == BlockchainStatus.failed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailableTab
              ? MenuTokens.deepGreen.withValues(alpha: 0.15)
              : MenuTokens.borderLight,
          width: isAvailableTab ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAvailableTab
                  ? MenuTokens.deepGreen
                  : (voucher.isUsed ? const Color(0xFF5A4D41) : Colors.grey.shade600),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: MenuTokens.butterYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      voucher.type.title.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MenuTokens.coral,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${voucher.discountPercent}% OFF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Voucher Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.type.subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.espresso,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Promo Code Box with Copy Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: MenuTokens.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MenuTokens.borderLight,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE PROMO',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: MenuTokens.mutedText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
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
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: voucher.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Kode ${voucher.code} berhasil disalin!'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16, color: MenuTokens.coral),
                        label: Text(
                          'Salin',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: MenuTokens.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Expiry and Status Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Berlaku hingga: ${voucher.formattedExpiry}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: MenuTokens.mutedText,
                      ),
                    ),
                    Text(
                      'Status: ${voucher.status.label}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: voucher.isAvailable
                            ? MenuTokens.deepGreen
                            : (voucher.isUsed ? Colors.brown : Colors.red),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Blockchain Audit Section
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE8E2D5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_outlined,
                                size: 14,
                                color: MenuTokens.deepGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'BLOCKCHAIN AUDIT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: MenuTokens.deepGreen,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          // Blockchain Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? const Color(0xFFE6F4EA)
                                  : (isPending ? const Color(0xFFFEF7E0) : const Color(0xFFFCE8E6)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isConfirmed
                                    ? const Color(0xFF34A853)
                                    : (isPending ? const Color(0xFFFBBC04) : const Color(0xFFEA4335)),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isConfirmed
                                      ? Icons.check_circle_rounded
                                      : (isPending ? Icons.hourglass_top_rounded : Icons.error_outline_rounded),
                                  size: 11,
                                  color: isConfirmed
                                      ? const Color(0xFF137333)
                                      : (isPending ? const Color(0xFFB06000) : const Color(0xFFC5221F)),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  voucher.blockchainStatus.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isConfirmed
                                        ? const Color(0xFF137333)
                                        : (isPending ? const Color(0xFFB06000) : const Color(0xFFC5221F)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Tx Hash Info
                      Row(
                        children: [
                          Text(
                            'Tx Hash: ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: MenuTokens.mutedText,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              voucher.redemptionTxHash ?? 'Menunggu konfirmasi blok...',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.robotoMono(
                                fontSize: 10,
                                color: AppColors.espresso,
                              ),
                            ),
                          ),
                          if (voucher.redemptionTxHash != null && voucher.redemptionTxHash!.isNotEmpty)
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: voucher.redemptionTxHash!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Transaction hash disalin!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.copy_rounded, size: 13, color: MenuTokens.mutedText),
                              ),
                            ),
                        ],
                      ),

                      // If block explorer URL is available
                      if (voucher.explorerUrl != null && voucher.explorerUrl!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final uri = Uri.parse(voucher.explorerUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Text(
                            'Lihat di Sepolia Etherscan ↗',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: MenuTokens.coral,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],

                      // Retry button if failed
                      if (isFailed) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 28,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final userId = ref.read(authProvider).user?.id;
                              if (userId != null) {
                                ref.read(userVouchersProvider(userId).notifier).retryBlockchainRecording(voucher);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 14),
                            label: const Text('Coba Lagi Sync Blockchain', style: TextStyle(fontSize: 10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
