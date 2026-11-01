import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../catalog/providers/catalog_provider.dart';
import '../../../../data/mock/catalog_data.dart';

class AdminInventoryTab extends ConsumerStatefulWidget {
  const AdminInventoryTab({super.key});

  @override
  ConsumerState<AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends ConsumerState<AdminInventoryTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _stockHealthFilter = 'ALL'; // 'ALL', 'LOW', 'OUT', 'SAFE'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(catalogProductsProvider);
    final products = catalogState.products;
    final logs = catalogState.stockLogs;

    // Stock metrics
    final totalSkus = products.length;
    final safeCount = products.where((p) => p.stock > p.minStock).length;
    final lowCount = products.where((p) => p.isLowStock && p.stock > 0).length;
    final outCount = products.where((p) => p.stock == 0).length;

    // Filter products
    final filtered = products.where((p) {
      if (_stockHealthFilter == 'SAFE' && (p.stock <= p.minStock || p.stock == 0)) {
        return false;
      }
      if (_stockHealthFilter == 'LOW' && (!p.isLowStock || p.stock == 0)) {
        return false;
      }
      if (_stockHealthFilter == 'OUT' && p.stock > 0) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    final isStockTab = _tabController.index == 0;

    return Container(
      color: AdminColors.warmWhite,
      child: CustomScrollView(
        slivers: [
          // ── Header & Operational Health Metrics + TabBar ────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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

                      final restockBtn = ElevatedButton.icon(
                        onPressed: () => _promptQuickRestockDialog(products),
                        icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                        label: Text(
                          'Restock Masuk',
                          style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.burgundy,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PANTRY & LOGISTICS CONTROLLER',
                                  style: AdminColors.sansUI(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AdminColors.burgundy,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manajemen Inventaris & Bahan',
                                  style: AdminColors.serifHeading(fontSize: 22),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            restockBtn,
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
                                  'PANTRY & LOGISTICS CONTROLLER',
                                  style: AdminColors.sansUI(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AdminColors.burgundy,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Manajemen Inventaris & Bahan',
                                  style: AdminColors.serifHeading(fontSize: 24),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          restockBtn,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),

                  // 4 Operational KPI Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isSmall = constraints.maxWidth < 600;
                      return isSmall
                          ? Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _buildHealthCard('Total SKU', '$totalSkus Item', Icons.inventory_2_outlined, AdminColors.burgundy, Colors.white, () => setState(() => _stockHealthFilter = 'ALL'), _stockHealthFilter == 'ALL')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildHealthCard('Stok Aman', '$safeCount SKU', Icons.check_circle_outline, AdminColors.success, const Color(0xFFDCFCE7), () => setState(() => _stockHealthFilter = 'SAFE'), _stockHealthFilter == 'SAFE')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(child: _buildHealthCard('Menipis', '$lowCount SKU', Icons.warning_amber_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7), () => setState(() => _stockHealthFilter = 'LOW'), _stockHealthFilter == 'LOW')),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildHealthCard('Habis', '$outCount SKU', Icons.error_outline_rounded, AdminColors.error, const Color(0xFFFEE2E2), () => setState(() => _stockHealthFilter = 'OUT'), _stockHealthFilter == 'OUT')),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildHealthCard('Total SKU', '$totalSkus Item', Icons.inventory_2_outlined, AdminColors.burgundy, Colors.white, () => setState(() => _stockHealthFilter = 'ALL'), _stockHealthFilter == 'ALL')),
                                const SizedBox(width: 10),
                                Expanded(child: _buildHealthCard('Stok Aman', '$safeCount SKU', Icons.check_circle_outline, AdminColors.success, const Color(0xFFDCFCE7), () => setState(() => _stockHealthFilter = 'SAFE'), _stockHealthFilter == 'SAFE')),
                                const SizedBox(width: 10),
                                Expanded(child: _buildHealthCard('Menipis', '$lowCount SKU', Icons.warning_amber_rounded, const Color(0xFFD97706), const Color(0xFFFEF3C7), () => setState(() => _stockHealthFilter = 'LOW'), _stockHealthFilter == 'LOW')),
                                const SizedBox(width: 10),
                                Expanded(child: _buildHealthCard('Habis', '$outCount SKU', Icons.error_outline_rounded, AdminColors.error, const Color(0xFFFEE2E2), () => setState(() => _stockHealthFilter = 'OUT'), _stockHealthFilter == 'OUT')),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Subtabs: Status Stok vs Mutasi
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    onTap: (index) => setState(() {}),
                    indicatorColor: AdminColors.burgundy,
                    indicatorWeight: 3,
                    labelColor: AdminColors.burgundy,
                    unselectedLabelColor: AdminColors.mutedText,
                    labelStyle: AdminColors.sansUI(fontSize: 12.5, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.assessment_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text('Ketersediaan Stok & Reorder (${filtered.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_edu_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text('Buku Mutasi Stok (${logs.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Tab 1: Ketersediaan Stok & Reorder ──────────────────────────────
          if (isStockTab) ...[
            // Search inside stock list
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari SKU menu atau kategori bahan...',
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              ),
            ),

            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_outlined, size: 48, color: AdminColors.mutedText),
                        const SizedBox(height: 10),
                        Text('Tidak ada item inventaris yang cocok', style: AdminColors.serifHeading(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return _buildArtisanalStockLedgerCard(product);
                  },
                ),
              ),
          ] else ...[
            // ── Tab 2: Buku Mutasi Stok ────────────────────────────────────────
            if (logs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_outlined, size: 48, color: AdminColors.mutedText),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat mutasi stok',
                          style: AdminColors.serifHeading(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Perubahan stok dan pesanan akan otomatis tercatat di sini',
                          style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                sliver: SliverList.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildStockHistoryItem(log);
                  },
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color bgColor,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AdminColors.border,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.mutedText),
                  ),
                  Text(
                    value,
                    style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.w800, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildArtisanalStockLedgerCard(ProductItem product) {
    Color statusBg;
    Color statusColor;
    String statusText;

    if (product.stock == 0) {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = AdminColors.error;
      statusText = 'HABIS';
    } else if (product.isLowStock) {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusText = 'MENIPIS';
    } else {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = AdminColors.success;
      statusText = 'AMAN';
    }

    // Ratio progress
    final maxRatio = (product.minStock * 2.5).clamp(10, 100).toDouble();
    final progress = (product.stock / maxRatio).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Product thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: product.imageUrl.startsWith('assets/')
                      ? Image.asset(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.lunch_dining))
                      : Image.network(product.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.lunch_dining)),
                ),
              ),
              const SizedBox(width: 14),

              // Title & Category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Kategori: ${product.category} • Batas Minimum Reorder: ${product.minStock} porsi',
                      style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stock health progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AdminColors.sandBeige.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),

          // Stock value & Quick Action Buttons
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Stok Tersedia: ',
                      style: AdminColors.sansUI(fontSize: 12, color: AdminColors.darkBrown),
                    ),
                    Text(
                      '${product.stock}',
                      style: AdminColors.serifHeading(
                        fontSize: 18,
                        color: product.stock == 0 ? AdminColors.error : AdminColors.burgundy,
                      ),
                    ),
                    Text(
                      ' porsi',
                      style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                    ),
                  ],
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick -1
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AdminColors.burgundy, size: 20),
                      tooltip: 'Kurangi 1',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        if (product.stock > 0) {
                          ref.read(catalogProductsProvider.notifier).adjustStock(
                            product.id,
                            -1,
                            reason: 'Pengurangan Operasional Dapur',
                          );
                        }
                      },
                    ),
                    // Quick +1
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AdminColors.burgundy, size: 20),
                      tooltip: 'Tambah 1',
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: () {
                        ref.read(catalogProductsProvider.notifier).adjustStock(
                          product.id,
                          1,
                          reason: 'Penambahan Cepat Dapur',
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    // Detailed stock adjustment button
                    OutlinedButton.icon(
                      onPressed: () => _promptStockAdjustmentModal(product),
                      icon: const Icon(Icons.tune, size: 13, color: AdminColors.burgundy),
                      label: Text(
                        'Sesuaikan',
                        style: AdminColors.sansUI(fontSize: 10.5, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        minimumSize: const Size(54, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AdminColors.burgundy),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Stock Mutation Ledger Helper ───────────────────────────────────
  Widget _buildStockHistoryItem(StockHistoryLog log) {
    final isPositive = log.delta > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isPositive ? AdminColors.success : AdminColors.error,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.productName,
                  style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.reason} • ${DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp)}',
                  style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${log.delta} unit',
                style: AdminColors.sansUI(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isPositive ? AdminColors.success : AdminColors.error,
                ),
              ),
              Text(
                'Stok: ${log.previousStock} → ${log.newStock}',
                style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stock Adjustment Modal ────────────────────────────────────────────────
  void _promptStockAdjustmentModal(ProductItem product) {
    int adjustmentType = 1; // 1: Restock (+), 2: Opname/Koreksi (=), 3: Kerusakan (-)
    final qtyCtrl = TextEditingController(text: '10');
    final reasonCtrl = TextEditingController(text: 'Penerimaan stok dari supplier pusat');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sesuaikan Stok Inventaris', style: AdminColors.serifHeading(fontSize: 20)),
                            Text(product.name, style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.warmWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Stok Saat Ini:', style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText)),
                          Text('${product.stock} porsi', style: AdminColors.sansUI(fontSize: 15, fontWeight: FontWeight.w800, color: AdminColors.darkBrown)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Adjustment Mode Chips
                    Text('Tipe Penyesuaian:', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('+ Restock'),
                            selected: adjustmentType == 1,
                            selectedColor: AdminColors.success,
                            labelStyle: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: adjustmentType == 1 ? Colors.white : AdminColors.darkBrown),
                            onSelected: (_) => setModalState(() {
                              adjustmentType = 1;
                              reasonCtrl.text = 'Penerimaan stok dari supplier pusat';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('= Opname Fisik'),
                            selected: adjustmentType == 2,
                            selectedColor: AdminColors.burgundy,
                            labelStyle: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: adjustmentType == 2 ? Colors.white : AdminColors.darkBrown),
                            onSelected: (_) => setModalState(() {
                              adjustmentType = 2;
                              qtyCtrl.text = product.stock.toString();
                              reasonCtrl.text = 'Hasil Stock Opname Dapur';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('- Kerusakan'),
                            selected: adjustmentType == 3,
                            selectedColor: AdminColors.error,
                            labelStyle: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: adjustmentType == 3 ? Colors.white : AdminColors.darkBrown),
                            onSelected: (_) => setModalState(() {
                              adjustmentType = 3;
                              reasonCtrl.text = 'Bahan kadaluarsa atau rusak saat persiapan';
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: adjustmentType == 2 ? 'Total Stok Fisik yang Ditemukan' : 'Jumlah Unit Penyesuaian',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan / Alasan Mutasi',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final val = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                          final reason = reasonCtrl.text.trim();

                          if (adjustmentType == 2) {
                            // Opname
                            final delta = val - product.stock;
                            ref.read(catalogProductsProvider.notifier).adjustStock(
                              product.id,
                              delta,
                              reason: reason.isNotEmpty ? reason : 'Stock Opname Fisik',
                            );
                          } else if (adjustmentType == 1) {
                            if (val <= 0) return;
                            ref.read(catalogProductsProvider.notifier).adjustStock(
                              product.id,
                              val,
                              reason: reason.isNotEmpty ? reason : 'Penerimaan Restock',
                            );
                          } else {
                            if (val <= 0) return;
                            ref.read(catalogProductsProvider.notifier).adjustStock(
                              product.id,
                              -val,
                              reason: reason.isNotEmpty ? reason : 'Penghapusan Bahan Rusak',
                            );
                          }

                          Navigator.pop(modalCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AdminColors.success,
                              content: Text('Stok ${product.name} berhasil diperbarui.'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.burgundy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Simpan Penyesuaian',
                          style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Quick Restock Dialog for any product
  void _promptQuickRestockDialog(List<ProductItem> products) {
    if (products.isEmpty) return;
    ProductItem selected = products.first;
    final qtyCtrl = TextEditingController(text: '20');

    showDialog(
      context: context,
      builder: (diagCtx) {
        return StatefulBuilder(
          builder: (diagCtx, setDiagState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Penerimaan Restock Masuk', style: AdminColors.serifHeading(fontSize: 20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pilih Menu / Bahan:', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ProductItem>(
                        value: selected,
                        isExpanded: true,
                        items: products.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (Stok: ${p.stock})', style: AdminColors.sansUI(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setDiagState(() => selected = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Jumlah Restock (Unit):', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '20'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(diagCtx),
                  child: Text('Batal', style: AdminColors.sansUI(color: AdminColors.mutedText)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                    if (qty <= 0) return;
                    ref.read(catalogProductsProvider.notifier).adjustStock(
                      selected.id,
                      qty,
                      reason: 'Restock Batch Logistik Masuk',
                    );
                    Navigator.pop(diagCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AdminColors.success, content: Text('Berhasil menambahkan +$qty unit ke ${selected.name}')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
                  child: Text('Tambah Stok', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
