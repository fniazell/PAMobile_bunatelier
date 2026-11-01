import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../../data/mock/catalog_data.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../core/services/google_maps_service.dart';
import '../../branch/providers/branch_provider.dart';
import '../../branch/presentation/widgets/choose_branch_card.dart';
import '../../branch/presentation/widgets/branch_selection_bottom_sheet.dart';
import '../../ai_recommendation/presentation/widgets/ai_sensory_banner.dart';

/// Editorial Artisan Burger Restaurant × Modern Premium Food App
/// Palette:
/// - Deep Forest Green: #193D2E / #163527
/// - Warm White: #F8F4EC
/// - Coral: #F05A43
/// - Soft Butter Yellow: #F4D779
/// - White: #FFFFFF
class HomeTheme {
  static const Color forestGreen = Color(0xFF193D2E);
  static const Color heroGreen = Color(0xFF163527);
  static const Color warmWhite = Color(0xFFF8F4EC);
  static const Color coral = Color(0xFFF05A43);
  static const Color butterYellow = Color(0xFFF4D779);
  static const Color white = Color(0xFFFFFFFF);
  static const Color espresso = Color(0xFF2C1E1A);
  static const Color mutedText = Color(0xFF7A6E65);
  static const Color borderLight = Color(0xFFEADBCE);
  static const Color dividerGrey = Color(0xFFD8CFBE);
}

class HomeScreen extends ConsumerWidget {
  final bool autoCheck;
  const HomeScreen({super.key, this.autoCheck = true});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(price).replaceAll(',', '.')}';
  }

  Widget _buildHeaderAvatar(String? avatarPath) {
    if (avatarPath != null && avatarPath.trim().isNotEmpty) {
      final clean = avatarPath.trim();
      try {
        if (clean.startsWith('http://') || clean.startsWith('https://')) {
          return Image.network(
            clean,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultHeaderAvatarIcon(),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _defaultHeaderAvatarIcon();
            },
          );
        }
        final file = File(clean);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultHeaderAvatarIcon(),
          );
        }
      } catch (_) {
        return _defaultHeaderAvatarIcon();
      }
    }
    return _defaultHeaderAvatarIcon();
  }

  Widget _defaultHeaderAvatarIcon() {
    return const Center(
      child: Icon(
        Icons.person_rounded,
        size: 19,
        color: Colors.white,
      ),
    );
  }

  void _quickAddToCart(BuildContext context, WidgetRef ref, ProductItem product) {
    final cartItem = CartItem(
      id: 'cart-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      quantity: 1,
    );
    ref.read(cartProvider.notifier).addItem(cartItem);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: HomeTheme.butterYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: HomeTheme.forestGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Added ${product.name} to tray! 🍔',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'VIEW TRAY',
          textColor: HomeTheme.butterYellow,
          onPressed: () => context.push('/cart'),
        ),
        backgroundColor: HomeTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final cartState = ref.watch(cartProvider);
    final notificationState = ref.watch(notificationProvider);
    final catalogState = ref.watch(catalogProductsProvider);

    // Dynamic user name from auth system formatted nicely (e.g. "Devita")
    final rawName = authState.user?.fullName;
    final String formattedUserName;
    if (rawName != null && rawName.trim().isNotEmpty) {
      final first = rawName.trim().split(' ').first;
      formattedUserName = '${first[0].toUpperCase()}${first.substring(1).toLowerCase()}';
    } else {
      formattedUserName = 'Devita';
    }

    // Best sellers list from dynamic catalog provider
    final bestSellers = catalogState.products.isNotEmpty
        ? catalogState.products.where((p) => p.isBestSeller).toList()
        : CatalogData.allProducts.where((p) => p.isBestSeller).toList();

    // Chef's recommendation (Hot Mess Express)
    final chefsPick = catalogState.products.firstWhere(
      (p) => p.id == 'b-02' || p.isChefsPick,
      orElse: () => CatalogData.allProducts.firstWhere(
        (p) => p.id == 'b-02',
        orElse: () => CatalogData.allProducts[1],
      ),
    );
    final branchState = ref.watch(branchProvider);
    final selectedBranch = branchState.selectedBranch;

    return Scaffold(
      backgroundColor: HomeTheme.warmWhite,
      appBar: AppBar(
        backgroundColor: HomeTheme.warmWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 62,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Left: Artisanal Logo + Subtitle + Divider + Pickup Selector
              Expanded(
                child: Row(
                  children: [
                    // Bun Atelier Burger Icon
                    _buildHeaderBurgerMark(),
                    const SizedBox(width: 7),

                    // Brand Name + Tagline
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'BUN ATELIER',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: HomeTheme.forestGreen,
                              letterSpacing: 0.6,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CRAFTED TO CRAVE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w800,
                              color: HomeTheme.forestGreen.withValues(alpha: 0.85),
                              letterSpacing: 1.6,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vertical Divider
                    Container(
                      height: 22,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: HomeTheme.dividerGrey,
                    ),

                    // Location Picker (Dynamic Branch Selector)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => BranchSelectionBottomSheet.show(context),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: HomeTheme.forestGreen,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Pickup at',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: HomeTheme.mutedText,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          selectedBranch.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: HomeTheme.forestGreen,
                                            height: 1.1,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        size: 13,
                                        color: HomeTheme.forestGreen,
                                      ),
                                    ],
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
              ),

              const SizedBox(width: 6),

              // 2. Right: Notification Bell (Badge 3), Cart Bag (Badge 2), User Avatar
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clean Notification Bell
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 21,
                            color: HomeTheme.forestGreen,
                          ),
                        ),
                        if (notificationState.unreadCount > 0)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: HomeTheme.coral,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              child: Center(
                                child: Text(
                                  '${notificationState.unreadCount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Clean Cart Bag
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/cart'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            size: 20,
                            color: HomeTheme.forestGreen,
                          ),
                        ),
                        if (cartState.totalItemCount > 0)
                          Positioned(
                            top: 1,
                            right: 1,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: HomeTheme.coral,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              child: Center(
                                child: Text(
                                  '${cartState.totalItemCount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Dark Forest Green Circular Avatar / User Profile Photo
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: HomeTheme.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildHeaderAvatar(authState.user?.avatarPath),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. GREETING SECTION (EXACT REFERENCE DESIGN)
            // ==========================================
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getGreeting()}, $formattedUserName!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 38,
                        height: 1.08,
                        color: HomeTheme.forestGreen,
                      ),
                      children: [
                        const TextSpan(text: 'Ready to make\na little '),
                        TextSpan(
                          text: 'mess?',
                          style: GoogleFonts.dmSerifDisplay(
                            fontStyle: FontStyle.italic,
                            color: HomeTheme.coral,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // 2. HERO BANNER CAROUSEL (SWIPE + AUTO-SLIDE)
            // ==========================================
            const BurgerHeroCarousel(),

            const SizedBox(height: 20),

            // ==========================================
            // ATELIER SENSORY AI RECOMMENDATION BANNER
            // ==========================================
            const AiSensoryBanner(),

            const SizedBox(height: 20),

            // ==========================================
            // CHOOSE YOUR BRANCH SECTION (MULTI-BRANCH)
            // ==========================================
            const ChooseBranchCard(),

            const SizedBox(height: 24),

            // ==========================================
            // 3. EXPLORE MENU (HORIZONTAL CATEGORIES)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPLORE MENU',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: HomeTheme.coral,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Curated Categories',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22,
                            color: HomeTheme.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => context.push('/menu'),
                    child: Row(
                      children: [
                        Text(
                          'Full Menu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: HomeTheme.forestGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: HomeTheme.forestGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category Horizontal Scroll
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildCategoryCard(
                    number: '01',
                    label: 'Smash\nBurgers',
                    isSelected: true,
                    onTap: () => context.push('/menu'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryCard(
                    number: '02',
                    label: 'Croissant\nBurgers',
                    isSelected: false,
                    onTap: () => context.push('/menu'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryCard(
                    number: '03',
                    label: 'Crispy\nSides',
                    isSelected: false,
                    onTap: () => context.push('/menu'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryCard(
                    number: '04',
                    label: 'Cool\nDrinks',
                    isSelected: false,
                    onTap: () => context.push('/menu'),
                  ),
                  const SizedBox(width: 8),
                  _buildCategoryCard(
                    number: '05',
                    label: 'Sweet\nDesserts',
                    isSelected: false,
                    onTap: () => context.push('/menu'),
                  ),
                  const SizedBox(width: 8),
                  // Custom Burger Atelier Card
                  GestureDetector(
                    onTap: () => context.push('/custom-burger'),
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: HomeTheme.forestGreen,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: HomeTheme.forestGreen),
                        boxShadow: [
                          BoxShadow(
                            color: HomeTheme.forestGreen.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune_rounded, size: 16, color: HomeTheme.butterYellow),
                          const SizedBox(height: 10),
                          Text(
                            'Custom\nBurger 🍔',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: HomeTheme.warmWhite,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 4. BEST SELLERS SECTION (DYNAMIC DATA)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE CROWD\'S CHOICE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HomeTheme.coral,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          'Best Sellers',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 28,
                            color: HomeTheme.forestGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/menu'),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'LIHAT SEMUA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: HomeTheme.forestGreen,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: HomeTheme.forestGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Container(width: 86, height: 1.5, color: HomeTheme.forestGreen),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Best Sellers Carousel
            SizedBox(
              height: 318,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: bestSellers.length,
                itemBuilder: (context, index) {
                  final product = bestSellers[index];
                  return _buildProductCard(
                    context: context,
                    ref: ref,
                    product: product,
                    isChefsPick: product.isChefsPick || product.id == 'b-02',
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // ==========================================
            // 5. CHEF'S RECOMMENDATION CARD (HOT MESS EXPRESS)
            // ==========================================
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: HomeTheme.coral,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: HomeTheme.coral.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // Right arched food image cutout
                  Positioned(
                    right: -10,
                    bottom: -15,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(150),
                      ),
                      child: Container(
                        width: 200,
                        height: 200,
                        color: HomeTheme.forestGreen.withValues(alpha: 0.15),
                        child: (chefsPick.imageUrl.startsWith('assets/'))
                            ? Image.asset(
                                chefsPick.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Image.asset(
                                  'assets/images/hero_burger.jpg',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Image.network(
                                chefsPick.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Image.asset(
                                  'assets/images/hero_burger.jpg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),

                  // Content Layout
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 22, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CHEF\'S RECOMMENDATION',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '02',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 38,
                              height: 0.95,
                              color: Colors.white,
                            ),
                            children: [
                              const TextSpan(text: 'HOT.\n'),
                              TextSpan(
                                text: 'MESS.\n',
                                style: GoogleFonts.dmSerifDisplay(
                                  fontStyle: FontStyle.italic,
                                  color: HomeTheme.butterYellow,
                                ),
                              ),
                              const TextSpan(text: 'EXPRESS.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          width: 210,
                          child: Text(
                            chefsPick.description.isNotEmpty
                                ? chefsPick.description
                                : 'Spicy, smoky, and unapologetically messy with molten cheese.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Action Button
                        GestureDetector(
                          onTap: () => context.push('/product/${chefsPick.id}'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: HomeTheme.butterYellow,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'MEET THE MESS',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: HomeTheme.forestGreen,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 15,
                                  color: HomeTheme.forestGreen,
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

            const SizedBox(height: 16),

            // ==========================================
            // 6. TWO-COLUMN SPLIT TILES (BUN BUDDY AI & STACK YOUR BUN)
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left: Bun Buddy AI (Deep Forest Green)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/buddy'),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 220),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: HomeTheme.forestGreen,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: HomeTheme.forestGreen.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: HomeTheme.butterYellow.withValues(alpha: 0.18),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome_rounded,
                                      color: HomeTheme.butterYellow,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'BUN BUDDY AI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: HomeTheme.butterYellow,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Not sure what to get?',
                                    style: GoogleFonts.dmSerifDisplay(
                                      fontSize: 18,
                                      color: Colors.white,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Let your burger bestie help customize your meal.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: HomeTheme.warmWhite.withValues(alpha: 0.8),
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: Stack Your Bun Game (Soft Butter Yellow)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/game'),
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 220),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: HomeTheme.butterYellow,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: HomeTheme.butterYellow.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: HomeTheme.forestGreen.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sports_esports_rounded,
                                    color: HomeTheme.forestGreen,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'STACK YOUR BUN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: HomeTheme.forestGreen,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Think you can stack it?',
                                  style: GoogleFonts.dmSerifDisplay(
                                    fontSize: 18,
                                    color: HomeTheme.forestGreen,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: HomeTheme.forestGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'High score: 2,480',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: HomeTheme.forestGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: HomeTheme.forestGreen.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: HomeTheme.forestGreen,
                                    size: 16,
                                  ),
                                ),
                              ],
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

            const SizedBox(height: 16),

            // ==========================================
            // 7. NEAREST ATELIER TILE (ROASTED ESPRESSO)
            // ==========================================
            GestureDetector(
              onTap: () => BranchSelectionBottomSheet.show(context),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                decoration: BoxDecoration(
                  color: HomeTheme.espresso,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: HomeTheme.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'NEAREST ATELIER',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: HomeTheme.coral,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 24,
                                color: HomeTheme.warmWhite,
                                height: 1.15,
                              ),
                              children: [
                                const TextSpan(text: 'Crafted at\n'),
                                TextSpan(text: selectedBranch.city),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: selectedBranch.isVerified ? const Color(0xFF4CAF50) : HomeTheme.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${selectedBranch.name} • ${selectedBranch.operatingHours ?? "Open"}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: HomeTheme.warmWhite.withValues(alpha: 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Coral circle with location pin — Tap directly opens Google Maps
                    GestureDetector(
                      onTap: () {
                        GoogleMapsService.openBranch(
                          query: selectedBranch.effectiveMapsQuery,
                          latitude: selectedBranch.latitude,
                          longitude: selectedBranch.longitude,
                          isVerified: selectedBranch.isVerified,
                          label: selectedBranch.name,
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: HomeTheme.coral,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_on_rounded,
                            color: HomeTheme.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Extra bottom spacing to prevent floating cart overlay
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================

  /// Header geometric artisan burger mark matching reference
  Widget _buildHeaderBurgerMark() {
    return SizedBox(
      width: 26,
      height: 22,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Curved Top Bun
          Container(
            height: 5.5,
            decoration: const BoxDecoration(
              color: HomeTheme.forestGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(5.5)),
            ),
          ),
          // Patty 1
          Container(
            height: 2.2,
            decoration: BoxDecoration(
              color: HomeTheme.forestGreen,
              borderRadius: BorderRadius.circular(1.2),
            ),
          ),
          // Patty 2
          Container(
            height: 2.2,
            decoration: BoxDecoration(
              color: HomeTheme.forestGreen,
              borderRadius: BorderRadius.circular(1.2),
            ),
          ),
          // Curved Bottom Bun
          Container(
            height: 4.5,
            decoration: const BoxDecoration(
              color: HomeTheme.forestGreen,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.5)),
            ),
          ),
        ],
      ),
    );
  }

  /// Category Tab Card
  Widget _buildCategoryCard({
    required String number,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? HomeTheme.butterYellow : HomeTheme.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFE5B962) : HomeTheme.borderLight,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected ? HomeTheme.forestGreen : HomeTheme.coral,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: HomeTheme.forestGreen,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Best Seller Product Card
  Widget _buildProductCard({
    required BuildContext context,
    required WidgetRef ref,
    required ProductItem product,
    required bool isChefsPick,
  }) {
    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        width: 195,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: HomeTheme.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HomeTheme.borderLight, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Badges & Plus Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
                  child: Container(
                    height: 175,
                    width: double.infinity,
                    color: HomeTheme.espresso.withValues(alpha: 0.05),
                    child: product.imageUrl.startsWith('assets/')
                        ? Image.asset(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Image.asset(
                              'assets/images/hero_burger.jpg',
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Image.asset(
                              'assets/images/hero_burger.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),

                // Best Seller / Chef's Pick Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: isChefsPick
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HomeTheme.butterYellow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: HomeTheme.forestGreen, width: 1),
                          ),
                          child: Text(
                            'CHEF\'S PICK',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: HomeTheme.forestGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: HomeTheme.coral,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'BEST SELLER',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                ),

                // Quick Add '+' Button
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _quickAddToCart(context, ref, product),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: HomeTheme.forestGreen,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Text Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 16,
                      color: HomeTheme.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    product.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: HomeTheme.mutedText,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    _formatPrice(product.price),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HomeTheme.forestGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BURGER HERO CAROUSEL DATA & WIDGET
// ==========================================

class PromoBannerItem {
  final String productId;
  final String badgeText;
  final String title;
  final String description;
  final int price;
  final bool isBestSeller;
  final String? assetImage;
  final String imageUrl;
  final String scriptText;

  const PromoBannerItem({
    required this.productId,
    required this.badgeText,
    required this.title,
    required this.description,
    required this.price,
    this.isBestSeller = false,
    this.assetImage,
    required this.imageUrl,
    required this.scriptText,
  });
}

class BurgerHeroCarousel extends StatefulWidget {
  const BurgerHeroCarousel({super.key});

  @override
  State<BurgerHeroCarousel> createState() => _BurgerHeroCarouselState();
}

class _BurgerHeroCarouselState extends State<BurgerHeroCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  static const List<PromoBannerItem> _items = [
    PromoBannerItem(
      productId: 'b-01',
      badgeText: 'THE BUN DROP / 01',
      title: 'OG Main\nCharacter',
      description: 'Juicy beef patty, melted cheddar,\ncaramelized onions, special sauce.',
      price: 65000,
      isBestSeller: true,
      assetImage: 'assets/images/hero_burger.jpg',
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
      scriptText: 'Pure\nBeef\nGoodness',
    ),
    PromoBannerItem(
      productId: 'b-02',
      badgeText: "CHEF'S PICK / 02",
      title: 'Hot Mess\nExpress',
      description: 'Dripping spicy habanero glaze,\npepper jack & ghost pepper mayo.',
      price: 72000,
      isBestSeller: true,
      imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80',
      scriptText: 'Spicy\nMessy\nCraving',
    ),
    PromoBannerItem(
      productId: 'b-03',
      badgeText: 'SPECIAL / 03',
      title: 'Smash Hit\nAtelier',
      description: 'Double crispy-edge smash patty,\nmolten onions & smoky dijonnaise.',
      price: 68000,
      isBestSeller: false,
      imageUrl: 'https://images.unsplash.com/photo-1550547660-d9450f859349?auto=format&fit=crop&w=800&q=80',
      scriptText: 'Double\nSmash\nCrisp',
    ),
    PromoBannerItem(
      productId: 'b-04',
      badgeText: 'CRUNCHY / 04',
      title: 'Crunch\nCulture',
      description: 'Buttermilk fried chicken breast,\nred cabbage slaw & hot honey.',
      price: 59000,
      isBestSeller: true,
      imageUrl: 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?auto=format&fit=crop&w=800&q=80',
      scriptText: 'Buttermilk\nGold\nCrunch',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _items.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    // Restart auto-slide after customer manual swipe
    _startAutoSlide();
  }

  void _goToPage(int index) {
    if (!mounted || !_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(price).replaceAll(',', '.')}';
  }

  Widget _buildBurgerImage(PromoBannerItem item) {
    if (item.assetImage != null) {
      return Image.asset(
        item.assetImage!,
        fit: BoxFit.cover,
        alignment: const Alignment(-0.15, 0.0),
        errorBuilder: (ctx, err, stack) => Image.network(
          item.imageUrl,
          fit: BoxFit.cover,
          alignment: const Alignment(-0.15, 0.0),
          errorBuilder: (c, e, s) => Container(color: HomeTheme.heroGreen),
        ),
      );
    }
    return Image.network(
      item.imageUrl,
      fit: BoxFit.cover,
      alignment: const Alignment(-0.15, 0.0),
      errorBuilder: (ctx, err, stack) => Image.asset(
        'assets/images/hero_burger.jpg',
        fit: BoxFit.cover,
        alignment: const Alignment(-0.15, 0.0),
        errorBuilder: (c, e, s) => Container(color: HomeTheme.heroGreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final bool isDesktop = availableWidth >= 900;
        final bool isTablet = availableWidth >= 640 && availableWidth < 900;
        final bool isWide = isDesktop || isTablet;

        final double bannerHeight = isDesktop
            ? 410.0
            : (isTablet ? 370.0 : 335.0);

        final double horizontalMargin = isWide ? 20.0 : 16.0;

        final double titleFontSize = isDesktop
            ? 38.0
            : (isTablet ? 32.0 : 27.0);
        final double descFontSize = isWide ? 13.0 : 11.5;
        final double priceFontSize = isWide ? 22.0 : 18.0;
        final EdgeInsets contentPadding = isDesktop
            ? const EdgeInsets.fromLTRB(38, 36, 16, 32)
            : (isTablet
                ? const EdgeInsets.fromLTRB(28, 28, 14, 26)
                : const EdgeInsets.fromLTRB(20, 20, 10, 20));

        final double imageWidthRatio = isDesktop ? 0.54 : (isTablet ? 0.52 : 0.51);
        final double effectiveBannerWidth = math.min(availableWidth - (horizontalMargin * 2), 1400.0);
        final double imageWidth = effectiveBannerWidth * imageWidthRatio;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
              height: bannerHeight,
              decoration: BoxDecoration(
                color: HomeTheme.heroGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: HomeTheme.forestGreen.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // 1. RIGHT: Swipable Burger Image Carousel (ONLY the image slides/swipes!)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    width: imageWidth,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _items.length,
                      physics: const PageScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black,
                                  ],
                                  stops: [0.0, 0.24],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: _buildBurgerImage(item),
                            ),

                            // Script accent text in Butter Yellow
                            Positioned(
                              top: isWide ? 26 : 18,
                              right: isWide ? 26 : 16,
                              child: Transform.rotate(
                                angle: -0.14,
                                child: Text(
                                  item.scriptText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.caveat(
                                    fontSize: isWide ? 20 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: HomeTheme.butterYellow,
                                    height: 1.05,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.65),
                                        blurRadius: 5,
                                        offset: const Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // 2. LEFT: Editorial Details & ORDER NOW Action (STATIONARY - does NOT move!)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: imageWidth * 0.88,
                    bottom: 0,
                    child: Padding(
                      padding: contentPadding,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: isWide ? 260.0 : 200.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Text layout updates smoothly in place when _currentPage changes
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                switchInCurve: Curves.easeIn,
                                switchOutCurve: Curves.easeOut,
                                child: KeyedSubtree(
                                  key: ValueKey<int>(_currentPage),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pill Badge
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isWide ? 12 : 10,
                                          vertical: isWide ? 4.5 : 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: HomeTheme.butterYellow,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Text(
                                          _items[_currentPage].badgeText,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: isWide ? 10.5 : 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: HomeTheme.forestGreen,
                                            letterSpacing: 0.9,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 14 : 10),

                                      // Title
                                      Text(
                                        _items[_currentPage].title,
                                        style: GoogleFonts.dmSerifDisplay(
                                          fontSize: titleFontSize,
                                          height: 1.05,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 10 : 6),

                                      // Description
                                      Text(
                                        _items[_currentPage].description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: descFontSize,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white.withValues(alpha: 0.88),
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: isDesktop ? 14 : 10),

                                      // Price & Badge Row
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            _formatPrice(_items[_currentPage].price),
                                            style: GoogleFonts.dmSerifDisplay(
                                              fontSize: priceFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 1,
                                            height: isWide ? 16 : 14,
                                            color: Colors.white38,
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _items[_currentPage].isBestSeller
                                                ? Icons.workspace_premium_rounded
                                                : Icons.local_fire_department_rounded,
                                            size: isWide ? 16 : 14,
                                            color: HomeTheme.butterYellow,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _items[_currentPage].isBestSeller ? 'Best Seller' : 'Fan Favorite',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: isWide ? 12 : 11,
                                              fontWeight: FontWeight.w700,
                                              color: HomeTheme.butterYellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: isDesktop ? 22 : 16),

                              // Coral Action Button: ORDER NOW -> (Stationary, dynamically routes to active burger)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.push('/product/${_items[_currentPage].productId}'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isWide ? 22 : 16,
                                    vertical: isWide ? 11 : 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HomeTheme.coral,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.28),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ORDER NOW',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isWide ? 12 : 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.9,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: isWide ? 15 : 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. BOTTOM RIGHT: Interactive Carousel Indicator Dots (• • • •)
                  Positioned(
                    bottom: isWide ? 18 : 14,
                    right: isWide ? 24 : 18,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_items.length, (i) {
                        final bool isActive = i == _currentPage;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _goToPage(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 4),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: isActive ? (isWide ? 18.0 : 14.0) : (isWide ? 5.0 : 4.5),
                              height: isWide ? 5.0 : 4.5,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(isActive ? 3 : 2.5),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

