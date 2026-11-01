import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/ai_recommendation_provider.dart';
import 'widgets/ai_header_app_bar.dart';

class AiMoreRecommendationsScreen extends ConsumerWidget {
  const AiMoreRecommendationsScreen({super.key});

  String _formatPrice(int price) {
    final fmt = NumberFormat('#,###', 'id_ID');
    return 'Rp ${fmt.format(price).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultSet = ref.watch(aiRecommendationResultProvider);
    final prefs = ref.watch(aiPreferencesProvider);

    final result = resultSet ?? AiRecommendationEngine.evaluate(prefs);

    // List of alternative burgers + additional ranked items
    final list = result.alternatives;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AiHeaderAppBar(
        title: 'More Recommendations',
        brandTag: 'BUN ATELIER AI',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main Heading
                    Text(
                      'More Buns to Love',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Supporting Text
                    Text(
                      'Curated pairings sculpted around your taste profile.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.espresso.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Cards List
                    ...list.map((rec) {
                      final product = rec.product;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            ref.read(selectedRecommendedProductProvider.notifier).state = rec;
                            context.push('/ai-recommendation/detail');
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Photo with Match Badge
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: product.imageUrl.startsWith('assets/')
                                          ? Image.asset(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                color: AppColors.creamDarker,
                                                child: const Icon(Icons.lunch_dining_rounded, size: 48, color: AppColors.coral),
                                              ),
                                            )
                                          : Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (ctx, err, stack) => Container(
                                                color: AppColors.creamDarker,
                                                child: const Icon(Icons.lunch_dining_rounded, size: 48, color: AppColors.coral),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F3D2E),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${rec.matchScore.round()}% MATCH',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF6EE7B7),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        rec.heatBadge,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Card Info
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.name,
                                            style: GoogleFonts.playfairDisplay(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.forestGreen,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatPrice(product.price),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFA62B2B),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    // Flavor & Protein tags
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _buildTag(product.category == 'croissant' ? 'Croissant Bun' : 'Brioche Bun'),
                                        if (product.isSpicy) _buildTag('Spicy Kick', isHighlight: true),
                                        _buildTag(product.name.contains('Chicken') ? 'Crispy Chicken' : 'Prime Beef'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Reason text
                                    Text(
                                      rec.whyThisMatches,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppColors.espresso.withValues(alpha: 0.85),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Action Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          ref.read(selectedRecommendedProductProvider.notifier).state = rec;
                                          context.push('/ai-recommendation/detail');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F3D2E),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          'LIHAT DETAIL & PESAN',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Bar: CHANGE PREFERENCES ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEADBCE))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.push('/ai-recommendation/edit-preferences');
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18, color: Color(0xFFA62B2B)),
                  label: Text(
                    'CHANGE PREFERENCES',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: const Color(0xFFA62B2B),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFA62B2B), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFEE2E2) : const Color(0xFFF7EFE6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFCA5A5) : const Color(0xFFE8DCCF),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: isHighlight ? const Color(0xFFDC2626) : AppColors.espresso,
        ),
      ),
    );
  }
}
