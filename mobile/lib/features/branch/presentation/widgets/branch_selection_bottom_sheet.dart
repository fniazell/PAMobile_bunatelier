import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../models/branch_model.dart';
import '../../providers/branch_provider.dart';

class BranchSelectionBottomSheet extends ConsumerWidget {
  const BranchSelectionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BranchSelectionBottomSheet(),
    );
  }

  void _onSelectBranch(
    BuildContext context,
    WidgetRef ref,
    BranchModel newBranch,
    BranchModel currentBranch,
  ) {
    if (newBranch.id == currentBranch.id) {
      Navigator.pop(context);
      return;
    }

    final cart = ref.read(cartProvider);
    if (cart.items.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppColors.surface(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Ganti Cabang Pemesanan?',
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 20,
              color: AppColors.forestGreen,
            ),
          ),
          content: Text(
            'Keranjang Anda saat ini berisi ${cart.totalItemCount} item dari "${currentBranch.name}". '
            'Mengganti ke "${newBranch.name}" akan mengosongkan keranjang saat ini. Apakah Anda yakin ingin melanjutkan?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.subtext(context),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtext(context),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
                ref.read(branchProvider.notifier).selectBranch(newBranch);
                Navigator.pop(dialogCtx); // Close dialog
                Navigator.pop(context); // Close bottom sheet
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cabang diubah ke ${newBranch.name}'),
                    backgroundColor: AppColors.forestGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Ganti & Kosongkan Keranjang',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      ref.read(branchProvider.notifier).selectBranch(newBranch);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cabang aktif: ${newBranch.name}'),
          backgroundColor: AppColors.forestGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openGoogleMaps(BuildContext context, BranchModel branch) async {
    final success = await GoogleMapsService.openBranch(
      query: branch.effectiveMapsQuery,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isVerified: branch.isVerified,
      label: branch.name,
    );

    if (!context.mounted) return;

    if (!success) {
      final fallback = branch.effectiveMapsUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak dapat membuka aplikasi Google Maps untuk ${branch.name}.',
          ),
          backgroundColor: AppColors.burgundy,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'BUKA BROWSER',
            textColor: AppColors.butterYellow,
            onPressed: () => GoogleMapsService.openInBrowser(fallback),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    final branches = branchState.branches;
    final selectedBranch = branchState.selectedBranch;
    final isDark = AppColors.isDark(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1B18) : const Color(0xFFFBF8F4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top drag pill
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHOOSE YOUR BRANCH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${branches.length} Lokasi Bun Atelier',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                      color: isDark ? Colors.white70 : AppColors.espresso,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Description banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.butterYellow.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.butterYellow.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF9E6500)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pilih cabang terdekat untuk pemesanan dine-in, takeaway, atau delivery internasional.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF6B4800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Branch List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  itemCount: branches.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final isSelected = branch.id == selectedBranch.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? (isSelected ? const Color(0xFF2C2420) : const Color(0xFF25211E))
                            : (isSelected ? Colors.white : const Color(0xFFF3ECE4)),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppColors.forestGreen : Colors.transparent,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: AppColors.forestGreen.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _onSelectBranch(context, ref, branch, selectedBranch),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: Name and Selected indicator
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          branch.name,
                                          style: GoogleFonts.dmSerifDisplay(
                                            fontSize: 18,
                                            color: isDark ? Colors.white : AppColors.forestGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_rounded,
                                              size: 14,
                                              color: AppColors.coral,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                '${branch.displayLocation} • ${branch.timezoneLabel} • ${branch.currencyLabel}',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white70 : AppColors.mutedText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.forestGreen,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check, size: 13, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Dipilih',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Divider 1: Antara Informasi Lokasi dan Alamat Lengkap
                              Divider(
                                height: 1,
                                thickness: 0.8,
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              const SizedBox(height: 10),

                              // Row 2: Alamat Lengkap Cabang (tampil rapi dan membungkus)
                              if (branch.address != null && branch.address!.isNotEmpty) ...[
                                Text(
                                  branch.address!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // Divider 2: Sebelum Tombol Aksi
                              Divider(
                                height: 1,
                                thickness: 0.8,
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                              const SizedBox(height: 10),

                              // Row 3: Verification Badge + Google Maps Action Button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Verification status badge (only shown when verified)
                                  if (branch.isVerified)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFF81C784),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.verified_rounded,
                                            size: 13,
                                            color: Color(0xFF2E7D32),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Titik Terverifikasi',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF2E7D32),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // Google Maps Button (MANDATORY REQUIREMENT)
                                  InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () => _openGoogleMaps(context, branch),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.forestGreen : const Color(0xFF163527),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.map_rounded, size: 14, color: AppColors.butterYellow),
                                          const SizedBox(width: 6),
                                          Text(
                                            'View Location',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
