import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/models/cart_item_model.dart';
import '../../../data/mock/catalog_data.dart';

class CustomBurgerOption {
  final String id;
  final String name;
  final int extraPrice;
  final String? subtitle;

  const CustomBurgerOption({
    required this.id,
    required this.name,
    this.extraPrice = 0,
    this.subtitle,
  });
}

class CustomBurgerScreen extends ConsumerStatefulWidget {
  const CustomBurgerScreen({super.key});

  @override
  ConsumerState<CustomBurgerScreen> createState() => _CustomBurgerScreenState();
}

class _CustomBurgerScreenState extends ConsumerState<CustomBurgerScreen> {
  static const int basePrice = 48000;

  // Selected Options
  String _selectedBun = 'bun-brioche';
  String _selectedPatty = 'patty-single';
  String _selectedCheese = 'cheese-cheddar';
  String _selectedSauce = 'sauce-atelier';
  final Set<String> _selectedVeggies = {'veg-lettuce', 'veg-pickle', 'veg-onion'};
  final Set<String> _selectedExtras = {};
  int _quantity = 1;

  final List<CustomBurgerOption> _buns = const [
    CustomBurgerOption(id: 'bun-brioche', name: 'Golden Brioche Bun', extraPrice: 0, subtitle: 'Buttery, soft & glazed'),
    CustomBurgerOption(id: 'bun-croissant', name: 'French Croissant Bun', extraPrice: 12000, subtitle: 'Flaky & laminated French butter'),
    CustomBurgerOption(id: 'bun-charcoal', name: 'Black Charcoal Bun', extraPrice: 8000, subtitle: 'Smoky aesthetic & crispy crust'),
    CustomBurgerOption(id: 'bun-potato', name: 'Soft Potato Roll', extraPrice: 6000, subtitle: 'Ultra pillow-soft texture'),
    CustomBurgerOption(id: 'bun-lettuce', name: 'Fresh Lettuce Wrap', extraPrice: 0, subtitle: 'Crispy low-carb keto option'),
  ];

  final List<CustomBurgerOption> _patties = const [
    CustomBurgerOption(id: 'patty-single', name: 'Single 150g Angus Beef Smash', extraPrice: 0, subtitle: 'Lacy crispy-edge smash patty'),
    CustomBurgerOption(id: 'patty-double', name: 'Double Australian Angus Smash', extraPrice: 24000, subtitle: '300g double juicy smash'),
    CustomBurgerOption(id: 'patty-chicken', name: 'Buttermilk Fried Chicken Thigh', extraPrice: 18000, subtitle: '24h brined crispy crunch'),
    CustomBurgerOption(id: 'patty-wagyu', name: 'A5 Wagyu Luxury Smash', extraPrice: 38000, subtitle: 'Melt-in-your-mouth marbling'),
    CustomBurgerOption(id: 'patty-plant', name: 'Beyond Meat Plant-Based', extraPrice: 22000, subtitle: '100% plant-powered umami'),
  ];

  final List<CustomBurgerOption> _cheeses = const [
    CustomBurgerOption(id: 'cheese-cheddar', name: 'Double American Cheddar', extraPrice: 0, subtitle: 'Classic gooey molten melt'),
    CustomBurgerOption(id: 'cheese-gruyere', name: 'Aged Swiss Gruyere', extraPrice: 8000, subtitle: 'Nutty & rich aromatic melt'),
    CustomBurgerOption(id: 'cheese-pepperjack', name: 'Spicy Pepper Jack', extraPrice: 8000, subtitle: 'Habanero flecked cheese melt'),
    CustomBurgerOption(id: 'cheese-mozzarella', name: 'Fresh Buffalo Mozzarella', extraPrice: 10000, subtitle: 'Creamy stretch and delicate flavor'),
    CustomBurgerOption(id: 'cheese-brie', name: 'French Truffle Brie', extraPrice: 14000, subtitle: 'Decadent truffle-infused creaminess'),
  ];

  final List<CustomBurgerOption> _veggies = const [
    CustomBurgerOption(id: 'veg-lettuce', name: 'Crisp Romaine Lettuce', extraPrice: 0),
    CustomBurgerOption(id: 'veg-tomato', name: 'Vine-Ripened Roma Tomatoes', extraPrice: 0),
    CustomBurgerOption(id: 'veg-pickle', name: 'House Dill Gherkins', extraPrice: 0),
    CustomBurgerOption(id: 'veg-onion', name: 'Shaved Red Onions', extraPrice: 0),
    CustomBurgerOption(id: 'veg-jalapeno', name: 'Spiced Pickled Jalapeños', extraPrice: 4000),
    CustomBurgerOption(id: 'veg-caramelized', name: 'Caramelized Balsamic Onions', extraPrice: 6000),
  ];

  final List<CustomBurgerOption> _sauces = const [
    CustomBurgerOption(id: 'sauce-atelier', name: 'Atelier Secret House Sauce', extraPrice: 0, subtitle: 'Tangy smoked paprika relish'),
    CustomBurgerOption(id: 'sauce-truffle', name: 'Black Truffle Garlic Aioli', extraPrice: 7000, subtitle: 'Earthy black truffle mayo'),
    CustomBurgerOption(id: 'sauce-bbq', name: 'Smoky Hickory Texas BBQ', extraPrice: 5000, subtitle: 'Sweet molasses & mesquite smoke'),
    CustomBurgerOption(id: 'sauce-chipotle', name: 'Spicy Chipotle Sriracha Crema', extraPrice: 5000, subtitle: 'Smoky heat with a kick'),
    CustomBurgerOption(id: 'sauce-honey', name: 'Dijon Honey Mustard', extraPrice: 5000, subtitle: 'Sweet & tangy mustard glaze'),
  ];

  final List<CustomBurgerOption> _extras = const [
    CustomBurgerOption(id: 'ext-bacon', name: 'Crispy Beef Bacon Strips (2x)', extraPrice: 12000),
    CustomBurgerOption(id: 'ext-egg', name: 'Sunny-Side Up Omega-3 Egg', extraPrice: 8000),
    CustomBurgerOption(id: 'ext-shiitake', name: 'Sautéed Butter Garlic Shiitake', extraPrice: 10000),
    CustomBurgerOption(id: 'ext-onionrings', name: 'Crispy Fried Onion Strings', extraPrice: 7000),
    CustomBurgerOption(id: 'ext-cheese-lava', name: 'Side Warm Cheese Lava Bath', extraPrice: 12000),
  ];

  int _calculateUnitPrice() {
    int total = basePrice;
    // Bun
    total += _buns.firstWhere((b) => b.id == _selectedBun).extraPrice;
    // Patty
    total += _patties.firstWhere((p) => p.id == _selectedPatty).extraPrice;
    // Cheese
    total += _cheeses.firstWhere((c) => c.id == _selectedCheese).extraPrice;
    // Sauce
    total += _sauces.firstWhere((s) => s.id == _selectedSauce).extraPrice;
    // Veggies
    for (final vegId in _selectedVeggies) {
      total += _veggies.firstWhere((v) => v.id == vegId).extraPrice;
    }
    // Extras
    for (final extId in _selectedExtras) {
      total += _extras.firstWhere((e) => e.id == extId).extraPrice;
    }
    return total;
  }

  void _handleAddToCart() {
    final unitPrice = _calculateUnitPrice();
    final bunName = _buns.firstWhere((b) => b.id == _selectedBun).name;
    final pattyName = _patties.firstWhere((p) => p.id == _selectedPatty).name;
    final cheeseName = _cheeses.firstWhere((c) => c.id == _selectedCheese).name;

    final summary = '$bunName, $pattyName, $cheeseName';

    final customProduct = ProductItem(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Custom Burger ($bunName)',
      category: 'burger',
      description: summary,
      ingredients: summary,
      price: unitPrice,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
    );

    ref.read(cartProvider.notifier).addItem(
      CartItem(
        id: 'cart-custom-${DateTime.now().millisecondsSinceEpoch}',
        product: customProduct,
        quantity: _quantity,
        notes: summary,
      ),
    );

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
                'Custom Burger ditambahkan ke Keranjang! ($summary)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'LIHAT BAG',
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
    final textTheme = Theme.of(context).textTheme;
    final unitPrice = _calculateUnitPrice();
    final totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'CUSTOM BURGER',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 22,
            letterSpacing: 1.5,
            color: AppColors.forestGreen,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedBun = 'bun-brioche';
                _selectedPatty = 'patty-single';
                _selectedCheese = 'cheese-cheddar';
                _selectedSauce = 'sauce-atelier';
                _selectedVeggies.clear();
                _selectedVeggies.addAll({'veg-lettuce', 'veg-pickle', 'veg-onion'});
                _selectedExtras.clear();
              });
            },
            child: Text(
              'RESET',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppColors.coral,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Visual Burger Stacking Preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                // Burger Stack Preview graphic
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.lunch_dining_rounded, size: 44, color: AppColors.butterYellow),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUILD YOUR MASTERPIECE',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppColors.coral,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Artisan Custom Burger',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp${unitPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.coral,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Customization Steps
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                // 1. BUN SELECTION
                _buildSectionHeader('1. PILIH BUN / ROTI', 'Pilih roti dasar burger Anda (Pilih 1)'),
                ..._buns.map((b) => _buildRadioTile(
                      title: b.name,
                      subtitle: b.subtitle,
                      extraPrice: b.extraPrice,
                      isSelected: _selectedBun == b.id,
                      onTap: () => setState(() => _selectedBun = b.id),
                    )),
                const SizedBox(height: 24),

                // 2. PATTY SELECTION
                _buildSectionHeader('2. PILIH PATTY / DAGING', 'Protein utama smash burger Anda'),
                ..._patties.map((p) => _buildRadioTile(
                      title: p.name,
                      subtitle: p.subtitle,
                      extraPrice: p.extraPrice,
                      isSelected: _selectedPatty == p.id,
                      onTap: () => setState(() => _selectedPatty = p.id),
                    )),
                const SizedBox(height: 24),

                // 3. CHEESE SELECTION
                _buildSectionHeader('3. PILIH KEJU MELELEH', 'Keju premium untuk lelehan sempurna'),
                ..._cheeses.map((c) => _buildRadioTile(
                      title: c.name,
                      subtitle: c.subtitle,
                      extraPrice: c.extraPrice,
                      isSelected: _selectedCheese == c.id,
                      onTap: () => setState(() => _selectedCheese = c.id),
                    )),
                const SizedBox(height: 24),

                // 4. VEGGIES & TOPPINGS
                _buildSectionHeader('4. SAYUR & GARNISH SEGAR', 'Pilih sayuran favorit Anda (Bisa lebih dari 1)'),
                ..._veggies.map((v) => _buildCheckboxTile(
                      title: v.name,
                      extraPrice: v.extraPrice,
                      isSelected: _selectedVeggies.contains(v.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedVeggies.add(v.id);
                          } else {
                            _selectedVeggies.remove(v.id);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 24),

                // 5. SIGNATURE SAUCE
                _buildSectionHeader('5. SAUS KHAS BUN ATELIER', 'Saus racikan chef Bun Atelier'),
                ..._sauces.map((s) => _buildRadioTile(
                      title: s.name,
                      subtitle: s.subtitle,
                      extraPrice: s.extraPrice,
                      isSelected: _selectedSauce == s.id,
                      onTap: () => setState(() => _selectedSauce = s.id),
                    )),
                const SizedBox(height: 24),

                // 6. PREMIUM EXTRAS
                _buildSectionHeader('6. EXTRA TOPPINGS MEWAH', 'Tambahkan sensasi ekstra ke burger Anda'),
                ..._extras.map((e) => _buildCheckboxTile(
                      title: e.name,
                      extraPrice: e.extraPrice,
                      isSelected: _selectedExtras.contains(e.id),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedExtras.add(e.id);
                          } else {
                            _selectedExtras.remove(e.id);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Bottom Bar: Quantity & Add to Cart
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.borderLight)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espresso.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Stepper
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 18),
                          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                        ),
                        Text(
                          '$_quantity',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 18),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Add to Bag Button
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _handleAddToCart,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'ADD TO BAG',
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white),
                            ),
                            Text(
                              'Rp${totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.forestGreen,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    String? subtitle,
    required int extraPrice,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.butterYellow.withValues(alpha: 0.25) : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.forestGreen : AppColors.mutedText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.espresso,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              extraPrice == 0 ? 'FREE' : '+Rp${extraPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? AppColors.coral : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required int extraPrice,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.butterYellow.withValues(alpha: 0.25) : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: isSelected ? AppColors.forestGreen : AppColors.mutedText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.espresso,
                ),
              ),
            ),
            Text(
              extraPrice == 0 ? 'FREE' : '+Rp${extraPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? AppColors.coral : AppColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
