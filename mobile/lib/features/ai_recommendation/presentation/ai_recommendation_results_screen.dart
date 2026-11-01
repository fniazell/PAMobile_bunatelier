import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/ai_recommendation_provider.dart';
import 'widgets/ai_header_app_bar.dart';

class AiRecommendationResultsScreen extends ConsumerWidget {
  const AiRecommendationResultsScreen({super.key});

  String _formatPrice(int price) {
    final fmt = NumberFormat('#,###', 'id_ID');
    return 'Rp ${fmt.format(price).replaceAll(',', '.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultSet = ref.watch(aiRecommendationResultProvider);
    final prefs = ref.watch(aiPreferencesProvider);

    // Fallback if not evaluated yet
    final result = resultSet ?? AiRecommendationEngine.evaluate(prefs);
    final bestMatch = result.bestMatch;
    final product = bestMatch.product;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AiHeaderAppBar(
        title: 'Recommendation Results',
        brandTag: 'BUN ATELIER AI',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Summary Banner (Deep Green) ───────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D2E),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bestMatch.editionTag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: const Color(0xFF6EE7B7),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 11, color: Color(0xFFFDE68A)),
                              const SizedBox(width: 4),
                              Text(
                                '${bestMatch.matchScore.toStringAsFixed(1)}% Match',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFDE68A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Perfect Match!',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on your flavor synthesis:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 4 Preference Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildSynthesisPill(prefs.budget.label),
                        _buildSynthesisPill(prefs.flavors.map((f) => f.tag).take(2).join(' & ')),
                        _buildSynthesisPill(prefs.spice.tag),
                        _buildSynthesisPill(prefs.protein.tag),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Featured Burger Card ───────────────────────────────────────
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEADBCE), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Burger Hero Image with Overlays
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: product.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: AppColors.creamDarker,
                                      child: const Center(
                                        child: Icon(Icons.lunch_dining_rounded, size: 54, color: AppColors.coral),
                                      ),
                                    ),
                                  )
                                : Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      color: AppColors.creamDarker,
                                      child: const Center(
                                        child: Icon(Icons.lunch_dining_rounded, size: 54, color: AppColors.coral),
                                      ),
                                    ),
                                  ),
                          ),
                        ),

                        // Best Match Badge (Gold)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE68A),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Color(0xFF92400E)),
                                const SizedBox(width: 4),
                                Text(
                                  'BEST MATCH',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Gradient Bar inside photo
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bestMatch.smokehouseCode,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.local_fire_department, size: 11, color: Colors.white),
                                      const SizedBox(width: 3),
                                      Text(
                                        bestMatch.heatBadge,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Content Padding
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category Subtitle
                          Text(
                            bestMatch.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: AppColors.coral,
                            ),
                          ),
                          const SizedBox(height: 2),

                          // Title and Price Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatPrice(product.price),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFA62B2B),
                                    ),
                                  ),
                                  if (bestMatch.originalPriceText != null)
                                    Text(
                                      bestMatch.originalPriceText!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Appetizing Description
                          Text(
                            product.description,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.espresso.withValues(alpha: 0.85),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 3 Specs Cards
                          Row(
                            children: bestMatch.specs.entries.map((entry) {
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF7ED),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFF5DECF)),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.coral,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.value,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.forestGreen,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Recommended Side Box
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7EFE6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F3D2E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.local_cafe_rounded, size: 16, color: Color(0xFFFDE68A)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'RECOMMENDED SIDE',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.coral,
                                        ),
                                      ),
                                      Text(
                                        bestMatch.recommendedSideName,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.espresso,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '+${_formatPrice(bestMatch.recommendedSidePrice)}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary CTA: LIHAT DETAIL MENU
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                ref.read(selectedRecommendedProductProvider.notifier).state = bestMatch;
                                context.push('/ai-recommendation/detail');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA62B2B),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.restaurant_menu_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'LIHAT DETAIL MENU',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Secondary CTA: COBA REKOMENDASI LAIN
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () {
                                context.push('/ai-recommendation/more');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.espresso,
                                side: const BorderSide(color: Color(0xFFE0D0C0), width: 1.2),
                                backgroundColor: const Color(0xFFFFF9F5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sync_rounded, size: 16, color: AppColors.espresso),
                                  const SizedBox(width: 6),
                                  Text(
                                    'COBA REKOMENDASI LAIN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Section: Alternative Buns ─────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'ALTERNATIVE BUNS ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.coral,
                      ),
                      children: [
                        TextSpan(
                          text: '• Runner Ups',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Score > 90%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Alternative Horizontal Cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: result.alternatives.map((alt) {
                    return Container(
                      width: 175,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE8DCCF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          ref.read(selectedRecommendedProductProvider.notifier).state = alt;
                          context.push('/ai-recommendation/detail');
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  child: alt.product.imageUrl.startsWith('assets/')
                                      ? Image.asset(
                                          alt.product.imageUrl,
                                          height: 100,
                                          width: 175,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            height: 100,
                                            color: AppColors.creamDarker,
                                            child: const Icon(Icons.lunch_dining_rounded, color: AppColors.coral),
                                          ),
                                        )
                                      : Image.network(
                                          alt.product.imageUrl,
                                          height: 100,
                                          width: 175,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            height: 100,
                                            color: AppColors.creamDarker,
                                            child: const Icon(Icons.lunch_dining_rounded, color: AppColors.coral),
                                          ),
                                        ),
                                ),
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F3D2E),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${alt.matchScore.round()}% MATCH',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF6EE7B7),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alt.product.name,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.forestGreen,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatPrice(alt.product.price),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFA62B2B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    alt.product.ingredients,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      color: AppColors.mutedText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Taste Guarantee
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8D7B8)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5B84B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUN ATELIER TASTE GUARANTEE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            'Jika rekomendasi ini tidak sesuai selera Anda, ganti item gratis di gerai counter manapun.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppColors.espresso,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSynthesisPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
