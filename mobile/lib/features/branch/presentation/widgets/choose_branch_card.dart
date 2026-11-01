import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../models/branch_model.dart';
import '../../providers/branch_provider.dart';
import 'branch_selection_bottom_sheet.dart';

class ChooseBranchCard extends ConsumerWidget {
  const ChooseBranchCard({super.key});

  void _openGoogleMaps(BuildContext context, BranchModel branch) async {
    final success = await GoogleMapsService.openBranch(
      query: branch.effectiveMapsQuery,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isVerified: branch.isVerified,
      label: branch.name,
    );

    if (!success && context.mounted) {
      final fallback = branch.effectiveMapsUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            branch.isVerified
                ? 'Membuka Google Maps (${branch.name})...'
                : 'Membuka pencarian Google Maps untuk ${branch.name}...',
          ),
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
    final selectedBranch = branchState.selectedBranch;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF193D2E), // Forest Green
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF193D2E).withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.coral,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'CHOOSE YOUR BRANCH',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.butterYellow,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (selectedBranch.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: AppColors.butterYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'VERIFIED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.butterYellow,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Main Branch Details
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedBranch.name,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22,
                    color: const Color(0xFFF8F4EC),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      size: 14,
                      color: AppColors.coral,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${selectedBranch.displayLocation} • ${selectedBranch.timezoneLabel} • ${selectedBranch.currencyLabel}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF8F4EC).withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                if (selectedBranch.address != null && selectedBranch.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    selectedBranch.address!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      height: 1.3,
                      color: const Color(0xFFF8F4EC).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.12),
          ),

          // Action Buttons: Change Branch & View on Google Maps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Change Branch Button
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => BranchSelectionBottomSheet.show(context),
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 18,
                      color: AppColors.butterYellow,
                    ),
                    label: Text(
                      'Change Branch',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF8F4EC),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // View on Google Maps Button (MANDATORY REQUIREMENT)
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openGoogleMaps(context, selectedBranch),
                    icon: const Icon(
                      Icons.map_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'View Location',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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
