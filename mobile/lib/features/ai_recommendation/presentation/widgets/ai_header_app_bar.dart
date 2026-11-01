import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';

class AiHeaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String brandTag;
  final VoidCallback? onBack;
  final bool showMascot;
  final bool showMoreAction;
  final Color? backgroundColor;

  const AiHeaderAppBar({
    super.key,
    required this.title,
    this.brandTag = 'BUN ATELIER AI',
    this.onBack,
    this.showMascot = true,
    this.showMoreAction = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? AppColors.cream,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        bottom: 8,
        left: 12,
        right: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: 28,
              color: AppColors.espresso,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onBack ?? () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/main');
              }
            },
          ),
          const SizedBox(width: 4),

          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  brandTag.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right actions: 3 dots & mascot avatar
          if (showMoreAction) ...[
            IconButton(
              icon: const Icon(
                Icons.more_horiz_rounded,
                size: 22,
                color: AppColors.espresso,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                _showInfoModal(context);
              },
            ),
            const SizedBox(width: 4),
          ],

          if (showMascot)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.creamDarker,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight, width: 1),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/images/splash/splash_frame_1.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppColors.coral,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.coral, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Tentang Bun Atelier Sensory AI',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Mesin kurasi berbasis sensory matrix yang menyelaraskan preferensi budget, cita rasa arang kayu, tingkat kepedasan, dan pilihan potongan daging dengan resep brioche segar Bun Atelier.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.espresso,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'Mengerti',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
