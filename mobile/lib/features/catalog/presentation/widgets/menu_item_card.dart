import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/mock/catalog_data.dart';
import 'menu_tokens.dart';

class MenuItemCard extends StatelessWidget {
  final ProductItem product;
  final int index;
  final VoidCallback onAddToCart;

  const MenuItemCard({
    super.key,
    required this.product,
    required this.index,
    required this.onAddToCart,
  });

  bool get isPhotoOnLeft => index % 2 == 0;

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(price).replaceAll(',', '.')}';
  }

  // Determine badge text and colors based on product properties
  Map<String, dynamic>? _getBadgeConfig() {
    if (product.isOutOfStock) {
      return {
        'label': 'HABIS (SOLD OUT)',
        'bg': Colors.grey.shade800,
        'textColor': Colors.white,
      };
    } else if (product.isChefsPick || product.id == 'b-02' || (product.category == 'croissant' && product.id == 'c-02')) {
      return {
        'label': "CHEF'S PICK",
        'bg': MenuTokens.butterYellow,
        'textColor': MenuTokens.deepGreen,
      };
    } else if (product.isBestSeller || product.id == 'b-01') {
      return {
        'label': 'BEST SELLER',
        'bg': MenuTokens.coral,
        'textColor': Colors.white,
      };
    } else if (product.id == 'c-01' || product.name.toLowerCase().contains('croissant') || product.id == 'b-06') {
      return {
        'label': 'LIMITED',
        'bg': MenuTokens.coral,
        'textColor': Colors.white,
      };
    } else if (product.id == 'b-03' || product.id == 'b-05' || product.id == 'b-07') {
      return {
        'label': 'STAPLE',
        'bg': MenuTokens.deepGreen,
        'textColor': Colors.white,
      };
    } else if (product.isSpicy) {
      return {
        'label': 'SPICY HIT',
        'bg': MenuTokens.coral,
        'textColor': Colors.white,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final badge = _getBadgeConfig();
    const photoSize = 126.0;

    final photoWidget = SizedBox(
      width: photoSize + 12,
      height: photoSize + 12,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Circular Image with subtle shadow
          Container(
            width: photoSize,
            height: photoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: product.imageUrl.startsWith('assets/')
                  ? Image.asset(
                      product.imageUrl,
                      width: photoSize,
                      height: photoSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: photoSize,
                        height: photoSize,
                        color: MenuTokens.borderLight,
                        child: const Center(
                          child: Icon(
                            Icons.lunch_dining_rounded,
                            size: 44,
                            color: MenuTokens.deepGreen,
                          ),
                        ),
                      ),
                    )
                  : Image.network(
                      product.imageUrl,
                      width: photoSize,
                      height: photoSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: photoSize,
                        height: photoSize,
                        color: MenuTokens.borderLight,
                        child: const Center(
                          child: Icon(
                            Icons.lunch_dining_rounded,
                            size: 44,
                            color: MenuTokens.deepGreen,
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: photoSize,
                          height: photoSize,
                          color: MenuTokens.borderLight.withValues(alpha: 0.4),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MenuTokens.coral,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // Overlapping Badge on outer top corner
          if (badge != null)
            Positioned(
              top: 0,
              left: isPhotoOnLeft ? 0 : null,
              right: isPhotoOnLeft ? null : 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badge['bg'] as Color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badge['label'] as String,
                  style: MenuTokens.sansUI(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badge['textColor'] as Color,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),

          // Overlapping "+" Button on inner bottom corner
          Positioned(
            bottom: 2,
            left: isPhotoOnLeft ? null : 2,
            right: isPhotoOnLeft ? 2 : null,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddToCart,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MenuTokens.deepGreen,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final textWidget = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            product.name,
            style: MenuTokens.serifHeading(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MenuTokens.deepGreen,
              height: 1.15,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),

          // Description (max 4 lines)
          Text(
            product.description,
            style: MenuTokens.sansUI(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: MenuTokens.mutedText,
              height: 1.35,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Price Pill (peach background, coral text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: MenuTokens.pricePillBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatPrice(product.price),
              style: MenuTokens.sansUI(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: MenuTokens.coral,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: MenuTokens.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4ECE4), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D2E).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/product/${product.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: isPhotoOnLeft
                  ? [
                      photoWidget,
                      const SizedBox(width: 16),
                      textWidget,
                    ]
                  : [
                      textWidget,
                      const SizedBox(width: 16),
                      photoWidget,
                    ],
            ),
          ),
        ),
      ),
    );
  }
}
