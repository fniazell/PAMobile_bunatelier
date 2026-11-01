import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/mock/catalog_data.dart';
import '../providers/catalog_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../cart/providers/cart_provider.dart';
import 'widgets/menu_tokens.dart';
import 'widgets/menu_item_card.dart';
import 'widgets/atelier_secret_card.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../branch/providers/branch_provider.dart';
import '../../branch/presentation/widgets/branch_selection_bottom_sheet.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<Map<String, String>> _categories = const [
    {'number': '00', 'slug': 'all', 'label': 'ALL'},
    {'number': '01', 'slug': 'burger', 'label': 'SMASH BURGERS'},
    {'number': '02', 'slug': 'croissant', 'label': 'CROISSANT BUNS'},
    {'number': '03', 'slug': 'sides', 'label': 'CRISPY SIDES'},
    {'number': '04', 'slug': 'drinks', 'label': 'COOL DRINKS'},
    {'number': '05', 'slug': 'desserts', 'label': 'DESSERTS'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAddToCart(ProductItem product) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    if (product.isOutOfStock) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Maaf, ${product.name} sedang habis (Sold Out)!',
            style: MenuTokens.sansUI(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          dismissDirection: DismissDirection.horizontal,
        ),
      );
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          messenger.hideCurrentSnackBar();
        }
      });
      return;
    }

    final cartItem = CartItem(
      id: 'cart-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      quantity: 1,
    );
    ref.read(cartProvider.notifier).addItem(cartItem);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Added ${product.name} to your tray! 🍔',
          style: MenuTokens.sansUI(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: MenuTokens.deepGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1800),
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: 'VIEW CART',
          textColor: MenuTokens.butterYellow,
          onPressed: () {
            messenger.clearSnackBars();
            context.push('/cart');
          },
        ),
      ),
    );

    // Menjamin notifikasi hilang maksimal 2 detik
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MenuTokens.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Menu',
                    style: MenuTokens.serifHeading(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: MenuTokens.deepGreen),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.local_fire_department_rounded, color: MenuTokens.coral),
                title: Text('Spicy Burgers Only', style: MenuTokens.sansUI(fontWeight: FontWeight.w700, color: MenuTokens.deepGreen)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'spicy');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.star_rounded, color: MenuTokens.butterYellow),
                title: Text('Best Sellers Only', style: MenuTokens.sansUI(fontWeight: FontWeight.w700, color: MenuTokens.deepGreen)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _searchQuery = 'bestseller');
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh_rounded, color: MenuTokens.deepGreen),
                title: Text('Reset Filters', style: MenuTokens.sansUI(fontWeight: FontWeight.w700, color: MenuTokens.mutedText)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'all';
                    _searchController.clear();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authProvider);
    final catalogState = ref.watch(catalogProductsProvider);
    final branchState = ref.watch(branchProvider);
    final selectedBranch = branchState.selectedBranch;

    // Filter products from reactive catalog state
    final filteredProducts = catalogState.products.where((product) {
      final matchesCategory = _selectedCategory == 'all' || product.category == _selectedCategory;
      if (!matchesCategory) return false;

      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      if (q == 'spicy') return product.isSpicy;
      if (q == 'bestseller') return product.isBestSeller;

      return product.name.toLowerCase().contains(q) ||
          product.description.toLowerCase().contains(q) ||
          product.ingredients.toLowerCase().contains(q);
    }).toList();

    // Determine user avatar initials
    final userInitials = authState.user?.fullName.isNotEmpty == true
        ? authState.user!.fullName
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join()
            .toUpperCase()
        : 'JD';

    final cartBadgeCount = '${cartState.totalItemCount}';

    return Scaffold(
      backgroundColor: MenuTokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. TOP APP BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Serif "BUN" logo with small coral dot
                  GestureDetector(
                    onTap: () => context.go('/main'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BUN',
                          style: MenuTokens.serifHeading(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: MenuTokens.deepGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: MenuTokens.coral,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Rounded pill location selector "MENU / [BRANCH CITY] ⌄"
                  Expanded(
                    child: GestureDetector(
                      onTap: () => BranchSelectionBottomSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: MenuTokens.borderLight),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'MENU / ',
                                      style: MenuTokens.sansUI(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: MenuTokens.mutedText,
                                      ),
                                    ),
                                    TextSpan(
                                      text: selectedBranch.city.toUpperCase(),
                                      style: MenuTokens.sansUI(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: MenuTokens.deepGreen,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: MenuTokens.coral,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Notification Bell Icon with Badge
                  GestureDetector(
                    onTap: () => context.push('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: MenuTokens.borderLight),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 19,
                              color: MenuTokens.deepGreen,
                            ),
                          ),
                        ),
                        if (ref.watch(notificationProvider).unreadCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: MenuTokens.coral,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 15,
                                minHeight: 15,
                              ),
                              child: Center(
                                child: Text(
                                  '${ref.watch(notificationProvider).unreadCount}',
                                  style: MenuTokens.sansUI(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Bag icon with coral badge "2"
                  GestureDetector(
                    onTap: () => context.push('/cart'),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: MenuTokens.borderLight),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 19,
                                color: MenuTokens.deepGreen,
                              ),
                            ),
                          ),
                          if (cartState.totalItemCount > 0)
                            Positioned(
                              top: -3,
                              right: -3,
                              child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: MenuTokens.coral,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Center(
                                child: Text(
                                  cartBadgeCount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Circular Avatar with initials "JD" (deep green circle, thin yellow ring)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: MenuTokens.deepGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: MenuTokens.butterYellow,
                        width: 1.6,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userInitials,
                        style: MenuTokens.sansUI(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SCROLLABLE BODY
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 6),

                  // 2. HEADER ROW: Eyebrow + Drops Active Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'THE FULL LINE-UP',
                        style: MenuTokens.sansUI(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: MenuTokens.mutedText,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: MenuTokens.coral.withValues(alpha: 0.55),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          '${filteredProducts.length.toString().padLeft(2, '0')} DROPS ACTIVE',
                          style: MenuTokens.sansUI(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: MenuTokens.coral,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title: "Pick your main character." (main character in italic coral)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Pick your ',
                          style: MenuTokens.serifHeading(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: MenuTokens.deepGreen,
                            height: 1.1,
                          ),
                        ),
                        TextSpan(
                          text: 'main character.',
                          style: MenuTokens.serifHeading(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: MenuTokens.coral,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. SEARCH FIELD & FILTER BUTTON
                  Row(
                    children: [
                      // Search field (white, fully rounded, thin border)
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: MenuTokens.borderLight),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: MenuTokens.sansUI(
                              fontSize: 13,
                              color: MenuTokens.deepGreen,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search burgers, sides, dips…',
                              hintStyle: MenuTokens.sansUI(
                                fontSize: 13,
                                color: MenuTokens.mutedText.withValues(alpha: 0.7),
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: MenuTokens.mutedText,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Deep green rounded "FILTER" button with sliders icon
                      GestureDetector(
                        onTap: _showFilterModal,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: MenuTokens.deepGreen,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: MenuTokens.deepGreen.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'FILTER',
                                style: MenuTokens.sansUI(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
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
                  const SizedBox(height: 14),

                  // 4. HORIZONTAL SCROLLABLE CATEGORY CHIPS
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat['slug'];
                        final labelText = '${cat['number']} ${cat['label']}';

                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat['slug']!),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? MenuTokens.deepGreen : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? MenuTokens.deepGreen : MenuTokens.borderLight,
                                width: 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: MenuTokens.deepGreen.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                labelText,
                                style: MenuTokens.sansUI(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? Colors.white : MenuTokens.deepGreen,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5. YELLOW BANNER: LIVE OVEN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: MenuTokens.butterYellow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Mini tag with coral dot and "LIVE OVEN"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: MenuTokens.deepGreen,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: MenuTokens.coral,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'LIVE OVEN',
                                style: MenuTokens.sansUI(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),

                        // Text
                        Expanded(
                          child: Text(
                            'FRESH BATCH GRILLED EVERY 15 MINS',
                            style: MenuTokens.sansUI(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: MenuTokens.deepGreen,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),

                        // Small Flame Icon
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: MenuTokens.deepGreen.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 6. MENU ITEM LIST (Alternating layout, 1 full-width card per item)
                  if (filteredProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.lunch_dining_rounded, size: 48, color: MenuTokens.borderLight),
                          const SizedBox(height: 12),
                          Text(
                            'No items found',
                            style: MenuTokens.serifHeading(fontSize: 18, color: MenuTokens.mutedText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search or category filter',
                            style: MenuTokens.sansUI(fontSize: 13, color: MenuTokens.mutedText),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(
                      filteredProducts.length,
                      (index) => MenuItemCard(
                        product: filteredProducts[index],
                        index: index,
                        onAddToCart: () => _handleAddToCart(filteredProducts[index]),
                      ),
                    ),

                  // 7. "ATELIER SECRET" BLOCK
                  const AtelierSecretCard(),

                  // Extra bottom padding to ensure content scrolls freely
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
