import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../data/mock/catalog_data.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../models/ai_recommendation_models.dart';
import '../providers/ai_recommendation_provider.dart';

class AiBurgerDetailScreen extends ConsumerStatefulWidget {
  final BurgerRecommendation? initialRecommendation;

  const AiBurgerDetailScreen({super.key, this.initialRecommendation});

  @override
  ConsumerState<AiBurgerDetailScreen> createState() => _AiBurgerDetailScreenState();
}

class _AiBurgerDetailScreenState extends ConsumerState<AiBurgerDetailScreen> {
  int _quantity = 1;
  bool _isFavorite = false;
  final _notesController = TextEditingController();

  String _formatPrice(int price) {
    final fmt = NumberFormat('#,###', 'id_ID');
    return 'Rp ${fmt.format(price).replaceAll(',', '.')}';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleAddToCart(ProductItem product) {
    final cartItem = CartItem(
      id: 'cart-ai-${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      quantity: _quantity,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F3D2E),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFFDE68A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added $_quantity x ${product.name} to Cart!',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: const Color(0xFFFDE68A),
          onPressed: () {
            messenger.clearSnackBars();
            context.push('/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.initialRecommendation ??
        ref.watch(selectedRecommendedProductProvider) ??
        ref.watch(aiRecommendationResultProvider)?.bestMatch ??
        BurgerRecommendation(
          product: CatalogData.allProducts.first,
          matchScore: 98.4,
          isBestMatch: true,
          whyThisMatches: 'Sesuai dengan preferensi gourmet Anda.',
          specs: const {'PATTY': 'Double Beef', 'PROFIL': 'Smoky', 'SENSASI': 'Medium'},
        );

    final product = rec.product;
    final prefs = ref.watch(aiPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with Hero Image ──────────────────────────────
          SliverAppBar(
            expandedHeight: 290,
            pinned: true,
            backgroundColor: AppColors.cream,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.85),
                child: IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.espresso, size: 26),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isFavorite ? const Color(0xFFDC2626) : AppColors.espresso,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  product.imageUrl.startsWith('assets/')
                      ? Image.asset(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppColors.creamDarker,
                            child: const Center(
                              child: Icon(Icons.lunch_dining_rounded, size: 64, color: AppColors.coral),
                            ),
                          ),
                        )
                      : Image.network(
                          product.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppColors.creamDarker,
                            child: const Center(
                              child: Icon(Icons.lunch_dining_rounded, size: 64, color: AppColors.coral),
                            ),
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F3D2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF6EE7B7)),
                              const SizedBox(width: 5),
                              Text(
                                '${rec.matchScore.toStringAsFixed(1)}% AI MATCH',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF6EE7B7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA62B2B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rec.heatBadge,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Detail Content ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle & Title
                  Text(
                    rec.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.coral,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatPrice(product.price),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFA62B2B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    product.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppColors.espresso,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── SECTION: WHY THIS MATCHES YOU ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2D3C0), width: 1.2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_alt_rounded, color: AppColors.coral, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'WHY THIS MATCHES YOU',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rec.whyThisMatches,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.espresso,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFDAC7B2)),
                        const SizedBox(height: 8),

                        // Match Breakdown Grid
                        _buildMatchFactorRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Budget Fit:',
                          value: '${prefs.budget.label} (Harga: ${_formatPrice(product.price)})',
                        ),
                        const SizedBox(height: 6),
                        _buildMatchFactorRow(
                          icon: Icons.local_dining_outlined,
                          label: 'Flavor Harmony:',
                          value: prefs.flavors.map((f) => f.tag).join(', '),
                        ),
                        const SizedBox(height: 6),
                        _buildMatchFactorRow(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Heat Level:',
                          value: prefs.spice.tag,
                        ),
                        const SizedBox(height: 6),
                        _buildMatchFactorRow(
                          icon: Icons.restaurant_outlined,
                          label: 'Protein Cut:',
                          value: prefs.protein.title,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ingredients List
                  Text(
                    'INGREDIENTS & PREPARATION',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Text(
                      product.ingredients,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.espresso,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Special Instructions Note
                  Text(
                    'SPECIAL INSTRUCTIONS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Extra sauce, no onion, cut in half...',
                      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.mutedText),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selector & Add To Cart Button
                  Row(
                    children: [
                      // Quantity Stepper
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEADBCE)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_quantity > 1) setState(() => _quantity--);
                              },
                            ),
                            Text(
                              '$_quantity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.espresso,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                setState(() => _quantity++);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Add to Cart CTA
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _handleAddToCart(product),
                            icon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.white),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ADD TO CART • ${_formatPrice(product.price * _quantity)}',
                                maxLines: 1,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA62B2B),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchFactorRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.coral),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: AppColors.espresso,
            ),
          ),
        ),
      ],
    );
  }
}
