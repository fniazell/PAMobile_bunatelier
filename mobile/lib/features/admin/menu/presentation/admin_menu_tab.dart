import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../catalog/providers/catalog_provider.dart';
import '../../../../data/mock/catalog_data.dart';

class AdminMenuTab extends ConsumerStatefulWidget {
  const AdminMenuTab({super.key});

  @override
  ConsumerState<AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends ConsumerState<AdminMenuTab> {
  String _selectedCategory = 'all';
  String _selectedStatusFilter = 'all'; // 'all', 'available', 'low', 'out'
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _isGridView = true;

  final List<Map<String, String>> _categories = const [
    {'slug': 'all', 'label': 'Semua Menu'},
    {'slug': 'burger', 'label': 'Burgers'},
    {'slug': 'croissant', 'label': 'Croissant Burgers'},
    {'slug': 'sides', 'label': 'Sides & Fries'},
    {'slug': 'drinks', 'label': 'Drinks'},
    {'slug': 'desserts', 'label': 'Desserts'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProductsProvider);
    final allProducts = catalogState.products;

    // Filter products
    final filtered = allProducts.where((p) {
      if (_selectedCategory != 'all' && p.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatusFilter == 'available' && (p.stock == 0 || !p.isAvailable)) {
        return false;
      }
      if (_selectedStatusFilter == 'low' && !p.isLowStock) {
        return false;
      }
      if (_selectedStatusFilter == 'out' && p.stock > 0) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchDesc = p.description.toLowerCase().contains(q);
        if (!matchName && !matchDesc) return false;
      }
      return true;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: AdminColors.warmWhite,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditProductModal(context),
        backgroundColor: AdminColors.burgundy,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Tambah Menu Baru',
          style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Search, Filters, and View Switch Bar ────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: const BoxDecoration(
                color: AdminColors.warmWhite,
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;

                    final actionRow = Row(
                      mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: isNarrow ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                      children: [
                        // View Switcher (Grid vs List)
                        Container(
                          decoration: BoxDecoration(
                            color: AdminColors.sandBeige.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AdminColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.grid_view_rounded,
                                  size: 18,
                                  color: _isGridView ? AdminColors.burgundy : AdminColors.mutedText,
                                ),
                                tooltip: 'Tampilan Grid Foto',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() => _isGridView = true),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.view_list_rounded,
                                  size: 20,
                                  color: !_isGridView ? AdminColors.burgundy : AdminColors.mutedText,
                                ),
                                tooltip: 'Tampilan Daftar Tabel',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => setState(() => _isGridView = false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AdminColors.burgundy,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${filtered.length} Menu',
                            style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARTISANAL CULINARY CATALOG',
                                style: AdminColors.sansUI(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.burgundy,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manajemen Menu & Katalog',
                                style: AdminColors.serifHeading(fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          actionRow,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARTISANAL CULINARY CATALOG',
                                style: AdminColors.sansUI(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.burgundy,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Manajemen Menu & Katalog',
                                style: AdminColors.serifHeading(fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        actionRow,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama produk kuliner atau deskripsi rasa...',
                    hintStyle: AdminColors.sansUI(color: AdminColors.mutedText, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: AdminColors.burgundy, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Row: Status Pills & Category Chips
                Row(
                  children: [
                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatusFilter,
                          style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Status: Semua')),
                            DropdownMenuItem(value: 'available', child: Text('Tersedia')),
                            DropdownMenuItem(value: 'low', child: Text('Stok Menipis')),
                            DropdownMenuItem(value: 'out', child: Text('Habis')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedStatusFilter = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category chips
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categories.map((c) {
                            final isSelected = _selectedCategory == c['slug'];
                            final count = c['slug'] == 'all'
                                ? allProducts.length
                                : allProducts.where((p) => p.category == c['slug']).length;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text('${c['label']} ($count)'),
                                labelStyle: AdminColors.sansUI(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? Colors.white : AdminColors.darkBrown,
                                ),
                                selected: isSelected,
                                selectedColor: AdminColors.burgundy,
                                backgroundColor: AdminColors.sandBeige,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide.none,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _selectedCategory = c['slug']!),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Product Presentation Area ───────────────────────────────────────
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lunch_dining_outlined, size: 52, color: AdminColors.mutedText),
                    const SizedBox(height: 12),
                    Text(
                      'Tidak ada produk ditemukan',
                      style: AdminColors.serifHeading(fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coba ubah kata kunci pencarian atau filter kategori',
                      style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText),
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (_isGridView)
          // Grid View Sliver
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 0.95 : (isTablet ? 0.92 : 0.90),
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = filtered[index];
                  return _buildArtisanalProductGridCard(product);
                },
                childCount: filtered.length,
              ),
            ),
          )
        else
          // List / Table View Sliver
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final product = filtered[index];
                return _buildArtisanalProductListRow(product);
              },
            ),
          ),
      ],
    ),
  );
}

  // ── Artisanal Grid Card ───────────────────────────────────────────────────
  Widget _buildArtisanalProductGridCard(ProductItem product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food Image with overlaid badges
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                product.imageUrl.startsWith('assets/')
                    ? Image.asset(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder())
                    : Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder()),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                // Top Category & Badges
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AdminColors.burgundy.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6),
                        ),
                      ),
                      if (product.isBestSeller)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC2410C),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'BEST SELLER',
                            style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom availability indicator
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: product.stock == 0
                          ? AdminColors.error
                          : product.isLowStock
                              ? const Color(0xFFD97706)
                              : Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.stock == 0 ? 'HABIS' : 'Stok: ${product.stock} porsi',
                      style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Controls
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: AdminColors.serifHeading(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Switch(
                            value: product.isAvailable && product.stock > 0,
                            activeThumbColor: AdminColors.burgundy,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            onChanged: (val) {
                              ref.read(catalogProductsProvider.notifier).toggleAvailability(product.id, val);
                            },
                          ),
                        ],
                      ),
                      Text(
                        _formatCurrency(product.price),
                        style: AdminColors.sansUI(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.burgundy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText, height: 1.2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (product.isChefsPick)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AdminColors.sandBeige,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "CHEF'S PICK",
                                  style: AdminColors.sansUI(fontSize: 8, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                                ),
                              ),
                            if (product.isSpicy)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SPICY',
                                  style: AdminColors.sansUI(fontSize: 8, fontWeight: FontWeight.bold, color: AdminColors.error),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.burgundy),
                            tooltip: 'Edit Menu',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _showAddEditProductModal(context, product: product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.error),
                            tooltip: 'Nonaktifkan',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeactivateProduct(product),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Artisanal List Row ────────────────────────────────────────────────────
  Widget _buildArtisanalProductListRow(ProductItem product) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: isNarrow ? 48 : 56,
            height: isNarrow ? 48 : 56,
            child: product.imageUrl.startsWith('assets/')
                ? Image.asset(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder())
                : Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildPlaceholder()),
          ),
        );

        final stockBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: product.stock == 0
                ? const Color(0xFFFEE2E2)
                : product.isLowStock
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            product.stock == 0 ? 'HABIS' : 'Stok: ${product.stock}',
            style: AdminColors.sansUI(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: product.stock == 0
                  ? AdminColors.error
                  : product.isLowStock
                      ? AdminColors.warning
                      : AdminColors.success,
            ),
          ),
        );

        final switchWidget = Switch(
          value: product.isAvailable && product.stock > 0,
          activeThumbColor: AdminColors.burgundy,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (val) {
            ref.read(catalogProductsProvider.notifier).toggleAvailability(product.id, val);
          },
        );

        final editButton = IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.burgundy),
          tooltip: 'Edit Menu',
          visualDensity: VisualDensity.compact,
          onPressed: () => _showAddEditProductModal(context, product: product),
        );

        final deleteButton = IconButton(
          icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.error),
          tooltip: 'Nonaktifkan',
          visualDensity: VisualDensity.compact,
          onPressed: () => _confirmDeactivateProduct(product),
        );

        if (isNarrow) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    imageWidget,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AdminColors.sandBeige.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  product.category,
                                  style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                                ),
                              ),
                              Text(
                                _formatCurrency(product.price),
                                style: AdminColors.sansUI(fontSize: 11.5, fontWeight: FontWeight.w800, color: AdminColors.burgundy),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    switchWidget,
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: AdminColors.divider),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    stockBadge,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        editButton,
                        deleteButton,
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              imageWidget,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            product.name,
                            style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AdminColors.sandBeige.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.category,
                            style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(product.price),
                      style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.burgundy),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              stockBadge,
              const SizedBox(width: 8),
              switchWidget,
              editButton,
              deleteButton,
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AdminColors.sandBeige,
      child: const Icon(Icons.restaurant, color: AdminColors.burgundy),
    );
  }

  // ── Add / Edit Product Modal ──────────────────────────────────────────────
  void _showAddEditProductModal(BuildContext context, {ProductItem? product}) {
    final isEditing = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    final stockCtrl = TextEditingController(text: product?.stock.toString() ?? '30');
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80');

    String selectedCat = product?.category ?? 'burger';
    bool isBestSeller = product?.isBestSeller ?? false;
    bool isChefsPick = product?.isChefsPick ?? false;
    bool isSpicy = product?.isSpicy ?? false;

    // Preset photo shortcuts
    final photoPresets = [
      ('Classic Burger', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80'),
      ('Gourmet Brioche', 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=800&q=80'),
      ('Truffle Croissant', 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80'),
      ('Truffle Fries', 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=800&q=80'),
      ('Artisan Drink', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80'),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Modal Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AdminColors.divider)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? 'Edit Menu Katalog' : 'Tambah Menu Baru',
                                  style: AdminColors.serifHeading(fontSize: 22),
                                ),
                                Text(
                                  'Perubahan akan langsung sinkron ke katalog pelanggan',
                                  style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(modalCtx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Modal Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormFieldLabel('NAMA PRODUK *'),
                          TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Royal Truffle Wagyu Smash',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Category Selector
                          _buildFormFieldLabel('KATEGORI PRODUK *'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCat,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'burger', child: Text('Burgers')),
                                  DropdownMenuItem(value: 'croissant', child: Text('Croissant Burgers')),
                                  DropdownMenuItem(value: 'sides', child: Text('Sides & Fries')),
                                  DropdownMenuItem(value: 'drinks', child: Text('Drinks')),
                                  DropdownMenuItem(value: 'desserts', child: Text('Desserts')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedCat = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Price & Stock
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormFieldLabel('HARGA (RP) *'),
                                    TextField(
                                      controller: priceCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. 75000',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormFieldLabel('STOK TERSEDIA *'),
                                    TextField(
                                      controller: stockCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        hintText: 'e.g. 35',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          _buildFormFieldLabel('DESKRIPSI MENU & KOMPOSISI'),
                          TextField(
                            controller: descCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Jelaskan cita rasa artisan, komposisi daging wagyu, keju leleh, dan saus truffle...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          _buildFormFieldLabel('URL FOTO KULINER'),
                          TextField(
                            controller: imageCtrl,
                            decoration: const InputDecoration(
                              hintText: 'https://images.unsplash.com/...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Preset photo chips
                          Text(
                            'Pilih foto siap pakai:',
                            style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            children: photoPresets.map((p) {
                              return ActionChip(
                                label: Text(p.$1, style: AdminColors.sansUI(fontSize: 10)),
                                backgroundColor: AdminColors.sandBeige.withValues(alpha: 0.5),
                                onPressed: () {
                                  setModalState(() {
                                    imageCtrl.text = p.$2;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Switches
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Tandai sebagai Best Seller', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Akan ditampilkan dengan lencana khusus di beranda', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                            value: isBestSeller,
                            activeThumbColor: AdminColors.burgundy,
                            onChanged: (val) => setModalState(() => isBestSeller = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text("Tandai sebagai Chef's Pick", style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Rekomendasi khusus dari head chef Bun Atelier', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                            value: isChefsPick,
                            activeThumbColor: AdminColors.burgundy,
                            onChanged: (val) => setModalState(() => isChefsPick = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Varian Pedas (Spicy Hit)', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: isSpicy,
                            activeThumbColor: AdminColors.burgundy,
                            onChanged: (val) => setModalState(() => isSpicy = val),
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () {
                                final name = nameCtrl.text.trim();
                                final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
                                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                                final desc = descCtrl.text.trim();
                                final img = imageCtrl.text.trim();

                                if (name.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama produk wajib diisi!')),
                                  );
                                  return;
                                }

                                if (price <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Harga harus valid dan lebih dari 0!')),
                                  );
                                  return;
                                }

                                if (isEditing) {
                                  final updated = product.copyWith(
                                    name: name,
                                    price: price,
                                    category: selectedCat,
                                    description: desc.isNotEmpty ? desc : product.description,
                                    imageUrl: img.isNotEmpty ? img : product.imageUrl,
                                    stock: stock,
                                    isBestSeller: isBestSeller,
                                    isChefsPick: isChefsPick,
                                    isSpicy: isSpicy,
                                    isAvailable: stock > 0,
                                  );
                                  ref.read(catalogProductsProvider.notifier).updateProduct(updated);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: AdminColors.success, content: Text('Menu ${product.name} berhasil diperbarui.')),
                                  );
                                } else {
                                  final newProd = ProductItem(
                                    id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                                    name: name,
                                    category: selectedCat,
                                    description: desc.isNotEmpty ? desc : 'Signature artisan creation by Bun Atelier.',
                                    ingredients: 'Artisanal Brioche, Gourmet Beef, House Sauce',
                                    price: price,
                                    imageUrl: img.isNotEmpty ? img : 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
                                    stock: stock,
                                    isBestSeller: isBestSeller,
                                    isChefsPick: isChefsPick,
                                    isSpicy: isSpicy,
                                    isAvailable: stock > 0,
                                  );
                                  ref.read(catalogProductsProvider.notifier).addProduct(newProd);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(backgroundColor: AdminColors.success, content: Text('Menu ${newProd.name} berhasil ditambahkan ke katalog.')),
                                  );
                                }

                                Navigator.pop(modalCtx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminColors.burgundy,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text(
                                isEditing ? 'Simpan Perubahan' : 'Tambahkan ke Katalog',
                                style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AdminColors.sansUI(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AdminColors.burgundy,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  void _confirmDeactivateProduct(ProductItem product) {
    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Nonaktifkan Menu?',
            style: AdminColors.serifHeading(fontSize: 20, color: AdminColors.error),
          ),
          content: Text(
            'Produk "${product.name}" akan dinonaktifkan dari katalog pelanggan, namun data transaksi masa lalu tetap tersimpan utuh.',
            style: AdminColors.sansUI(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(diagCtx),
              child: Text(
                'Batal',
                style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(catalogProductsProvider.notifier).deleteProduct(product.id);
                Navigator.pop(diagCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AdminColors.error,
                    content: Text('Menu ${product.name} telah dinonaktifkan.'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Nonaktifkan',
                style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
