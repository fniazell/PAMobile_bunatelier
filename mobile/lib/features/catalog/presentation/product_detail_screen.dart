import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../data/mock/catalog_data.dart';
import '../providers/catalog_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  ProductAddonItem? _selectedSauce;
  final List<ProductAddonItem> _selectedAddons = [];
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int _calculateTotal(ProductItem product) {
    int total = product.price;
    if (_selectedSauce != null) {
      total += _selectedSauce!.price;
    }
    for (final addon in _selectedAddons) {
      total += addon.price;
    }
    return total * _quantity;
  }

  void _handleAddToCart(ProductItem product) {
    final cartItem = CartItem(
      id: 'cart-${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      quantity: _quantity,
      selectedAddons: List.from(_selectedAddons),
      selectedSauce: _selectedSauce,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    ref.read(cartProvider.notifier).addItem(cartItem);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.forestGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.butterYellow),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Added ${product.name} to Cart!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: AppColors.butterYellow,
          onPressed: () {
            messenger.clearSnackBars();
            context.push('/cart');
          },
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      messenger.clearSnackBars();
    });

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProductsProvider);
    final product = catalogState.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => CatalogData.allProducts.first,
    );

    final currentTotal = _calculateTotal(product);

    // Split name for two-tone editorial title
    final words = product.name.split(' ');
    final firstPart = words.take(words.length > 1 ? words.length - 1 : 1).join(' ');
    final lastPart = words.length > 1 ? words.last : '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Image Sliver with Badges matching screenshot
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    product.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            product.imageUrl,
                            height: 380,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 380,
                              color: AppColors.espresso,
                              child: const Center(
                                child: Icon(Icons.lunch_dining_rounded, size: 80, color: AppColors.cream),
                              ),
                            ),
                          )
                        : Image.network(
                            product.imageUrl,
                            height: 380,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              height: 380,
                              color: AppColors.espresso,
                              child: const Center(
                                child: Icon(Icons.lunch_dining_rounded, size: 80, color: AppColors.cream),
                              ),
                            ),
                          ),

                    // Top-Left Back Button (White box with chevron)
                    Positioned(
                      top: 48,
                      left: 18,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          color: Colors.white,
                          child: const Center(
                            child: Icon(Icons.chevron_left_rounded, size: 24, color: AppColors.espresso),
                          ),
                        ),
                      ),
                    ),

                    // Top-Right BEST SELLER Circular Badge
                    if (product.isBestSeller)
                      Positioned(
                        top: 48,
                        right: 18,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              'BEST\nSELLER',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bottom-Left NO. 01 BUN ICON dark green tag
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        color: AppColors.forestGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NO. 01',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'BUN ICON',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
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

              // Product Info & Customization
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle / Eyebrow
                      Text(
                        'THE ORIGINAL MESS',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.coral,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Two-tone Editorial Title
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 44,
                            height: 1.05,
                            color: AppColors.forestGreen,
                          ),
                          children: [
                            TextSpan(text: '$firstPart\n'),
                            TextSpan(
                              text: '$lastPart.',
                              style: GoogleFonts.dmSerifDisplay(
                                fontStyle: FontStyle.italic,
                                color: AppColors.coral,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price + Nett Tag
                      Row(
                        children: [
                          Text(
                            'Rp${(product.price / 1000).toInt()}.000',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            color: AppColors.forestGreen.withValues(alpha: 0.12),
                            child: Text(
                              'NETT',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description
                      Text(
                        product.description,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.mutedText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Key Ingredients
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KEY INGREDIENTS',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.ingredients,
                              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.espresso),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // SAUCES SELECTION
                      Text(
                        'CHOOSE YOUR ARTISAN SAUCE',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 10),
                      ...CatalogData.sauces.map((sauce) {
                        final isSelected = _selectedSauce?.id == sauce.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSauce = isSelected ? null : sauce),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.butterYellow.withValues(alpha: 0.3) : Colors.white,
                              border: Border.all(
                                color: isSelected ? AppColors.coral : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? AppColors.coral : AppColors.mutedText,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(sauce.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                Text('+ Rp ${sauce.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.forestGreen)),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),

                      // ADDONS SELECTION
                      Text(
                        'ADD-ONS & CUSTOMIZATIONS',
                        style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 10),
                      ...CatalogData.addons.map((addon) {
                        final isChecked = _selectedAddons.any((a) => a.id == addon.id);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isChecked) {
                                _selectedAddons.removeWhere((a) => a.id == addon.id);
                              } else {
                                _selectedAddons.add(addon);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isChecked ? AppColors.butterYellow.withValues(alpha: 0.3) : Colors.white,
                              border: Border.all(
                                color: isChecked ? AppColors.forestGreen : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                                  color: isChecked ? AppColors.forestGreen : AppColors.mutedText,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(addon.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                Text('+ Rp ${addon.price}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.forestGreen)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Bar matching screenshot exactly
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Stepper Box
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.espresso, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                          ),
                          Text(
                            '$_quantity',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Solid Coral Add To Cart Button (Disabled if out of stock)
                    Expanded(
                      child: GestureDetector(
                        onTap: product.isOutOfStock ? null : () => _handleAddToCart(product),
                        child: Container(
                          height: 48,
                          color: product.isOutOfStock ? Colors.grey.shade400 : AppColors.coral,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                product.isOutOfStock ? 'STOK HABIS (SOLD OUT)' : 'ADD TO CART',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              if (!product.isOutOfStock)
                                Text(
                                  'RP $currentTotal',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
