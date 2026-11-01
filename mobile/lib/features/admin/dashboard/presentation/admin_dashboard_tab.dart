import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../../orders/models/order_model.dart';
import '../../../catalog/providers/catalog_provider.dart';
import '../../../../data/mock/catalog_data.dart';

class AdminDashboardTab extends ConsumerStatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final Function(OrderItemModel order)? onViewOrderDetail;

  const AdminDashboardTab({
    super.key,
    this.onNavigateToTab,
    this.onViewOrderDetail,
  });

  @override
  ConsumerState<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends ConsumerState<AdminDashboardTab> {
  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final catalogState = ref.watch(catalogProductsProvider);

    final allOrders = ordersState.orders;
    final validOrders = allOrders.where((o) => o.status != 'CANCELLED').toList();

    // Key metrics calculations
    final totalSales = validOrders.fold(0, (sum, o) => sum + o.total);
    final totalOrdersCount = allOrders.length;
    final activeOrdersCount = allOrders.where((o) =>
      o.status == 'CONFIRMED' ||
      o.status == 'PREPARING' ||
      o.status == 'READY_FOR_PICKUP' ||
      o.status == 'PENDING'
    ).length;

    // Calculate product sales frequency from valid orders
    final Map<String, int> productUnitsSold = {};
    for (final order in validOrders) {
      final entries = order.itemsSummary.split(',');
      for (final entry in entries) {
        final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(entry.trim());
        if (match != null) {
          final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
          final name = match.group(2)?.trim() ?? '';
          productUnitsSold[name] = (productUnitsSold[name] ?? 0) + qty;
        }
      }
    }

    // Determine Best Seller
    String bestSellerName = '-';
    int bestSellerUnits = 0;
    productUnitsSold.forEach((name, units) {
      if (units > bestSellerUnits) {
        bestSellerUnits = units;
        bestSellerName = name;
      }
    });

    final lowStockItems = catalogState.products.where((p) => p.isLowStock || p.isOutOfStock).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Editorial Header ─────────────────────────────────────────────
              _buildHeader(context),
              const SizedBox(height: 20),

              // ── 4 Key KPI Metrics Cards ──────────────────────────────────────
              _buildMetricsRow(
                isWide: isWide,
                totalSales: totalSales,
                totalOrdersCount: totalOrdersCount,
                activeOrdersCount: activeOrdersCount,
                bestSellerName: bestSellerName,
                bestSellerUnits: bestSellerUnits,
                lowStockCount: lowStockItems.length,
                allProducts: catalogState.products,
              ),
              const SizedBox(height: 24),

              // ── Main Content Grid (Responsive Asymmetric) ────────────────────
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Charts & Queue)
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildSalesPerformanceCard(validOrders),
                          const SizedBox(height: 22),
                          _buildRecentOrdersSection(allOrders),
                        ],
                      ),
                    ),
                    const SizedBox(width: 22),
                    // Right Column (Stock & Top Products)
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildStockAlertSection(lowStockItems),
                          const SizedBox(height: 22),
                          _buildTopProductsSection(catalogState.products, productUnitsSold),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildSalesPerformanceCard(validOrders),
                    const SizedBox(height: 20),
                    if (lowStockItems.isNotEmpty) ...[
                      _buildStockAlertSection(lowStockItems),
                      const SizedBox(height: 20),
                    ],
                    _buildRecentOrdersSection(allOrders),
                    const SizedBox(height: 20),
                    _buildTopProductsSection(catalogState.products, productUnitsSold),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final nowFormatted = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());

    final operationalStatusBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'Outlet Buka',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF047857),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        if (isNarrow) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AdminColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'DASHBOARD OPERASIONAL • SENOPATI FLAGSHIP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.burgundy,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    operationalStatusBadge,
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Ringkasan Bisnis & Dapur',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 20,
                    color: AdminColors.darkBrown,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AdminColors.warmWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AdminColors.burgundy),
                      const SizedBox(width: 6),
                      Text(
                        nowFormatted,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DASHBOARD OPERASIONAL • SENOPATI FLAGSHIP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.burgundy,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ringkasan Bisnis & Dapur',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        color: AdminColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  operationalStatusBadge,
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.warmWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: AdminColors.burgundy),
                        const SizedBox(width: 6),
                        Text(
                          nowFormatted,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.darkBrown,
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
      },
    );
  }

  Widget _buildMetricsRow({
    required bool isWide,
    required int totalSales,
    required int totalOrdersCount,
    required int activeOrdersCount,
    required String bestSellerName,
    required int bestSellerUnits,
    required int lowStockCount,
    required List<ProductItem> allProducts,
  }) {
    ProductItem? bestSellerProduct;
    if (bestSellerName != '-' && bestSellerName.isNotEmpty) {
      for (final p in allProducts) {
        if (p.name.toLowerCase() == bestSellerName.toLowerCase()) {
          bestSellerProduct = p;
          break;
        }
      }
    }

    final cards = [
      _buildLedgerCard(
        title: 'TOTAL PENJUALAN',
        value: _formatCurrency(totalSales),
        subtitle: 'Transaksi terverifikasi',
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF047857),
        accentBg: const Color(0xFFECFDF5),
        badgeText: '✓ 100% Berhasil',
        badgeColor: const Color(0xFF047857),
        badgeBg: const Color(0xFFECFDF5),
        onTap: () => widget.onNavigateToTab?.call(4), // Sales Analytics
      ),
      _buildLedgerCard(
        title: 'ANTREAN PESANAN',
        value: '$totalOrdersCount Pesanan',
        subtitle: '$activeOrdersCount sedang diproses dapur',
        icon: Icons.receipt_long_rounded,
        iconColor: AdminColors.burgundy,
        accentBg: const Color(0xFFFDF2F4),
        badgeText: activeOrdersCount > 0 ? '$activeOrdersCount Proses' : 'Antrean Bersih',
        badgeColor: activeOrdersCount > 0 ? const Color(0xFFB45309) : AdminColors.success,
        badgeBg: activeOrdersCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
        onTap: () => widget.onNavigateToTab?.call(1), // Orders
      ),
      _buildBestSellerCard(
        product: bestSellerProduct,
        name: bestSellerName,
        unitsSold: bestSellerUnits,
        onTap: () => widget.onNavigateToTab?.call(2), // Menu Management
      ),
      _buildLedgerCard(
        title: 'KESEHATAN STOK',
        value: lowStockCount > 0 ? '$lowStockCount Item Kritis' : 'Stok Aman',
        subtitle: lowStockCount > 0 ? 'Perlu pengadaan segera' : 'Semua item di atas kuota',
        icon: lowStockCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
        iconColor: lowStockCount > 0 ? AdminColors.error : AdminColors.success,
        accentBg: lowStockCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        badgeText: lowStockCount > 0 ? 'Restock!' : '38 SKU Siap',
        badgeColor: lowStockCount > 0 ? AdminColors.error : AdminColors.success,
        badgeBg: lowStockCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        progressValue: lowStockCount > 0 ? 0.6 : 1.0,
        onTap: () => widget.onNavigateToTab?.call(3), // Inventory
      ),
    ];

    if (isWide) {
      return Row(
        children: cards.map((c) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: c,
          ),
        )).toList(),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double ratio = constraints.maxWidth < 380
            ? 1.28
            : (constraints.maxWidth < 550 ? 1.38 : 1.50);

        return GridView.count(
          crossAxisCount: constraints.maxWidth >= 550 ? 4 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: ratio,
          children: cards,
        );
      },
    );
  }

  Widget _buildBestSellerCard({
    required ProductItem? product,
    required String name,
    required int unitsSold,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.surface,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'PRODUK TERLARIS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.mutedText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFD97706)),
                      const SizedBox(width: 2),
                      Text(
                        '#1',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: product != null
                        ? _buildProductThumbnail(product)
                        : _buildProductPlaceholder(name),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.darkBrown,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unitsSold > 0 ? '$unitsSold unit terjual' : 'Belum ada data',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color accentBg,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBg,
    double? progressValue,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.surface,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.mutedText,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: accentBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: iconColor),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.darkBrown,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                if (progressValue != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 45,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              minHeight: 4,
                              backgroundColor: AdminColors.sandBeige.withValues(alpha: 0.5),
                              valueColor: AlwaysStoppedAnimation(
                                progressValue == 1.0 ? AdminColors.success : AdminColors.warning,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText ?? subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (badgeText != null)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeBg ?? AdminColors.warmWhite,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: badgeColor ?? AdminColors.burgundy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.0,
                            color: AdminColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: AdminColors.mutedText,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesPerformanceCard(List<OrderItemModel> validOrders) {
    final now = DateTime.now();
    final List<({String label, int total, int count, bool isToday})> days = [];
    int sevenDaysTotal = 0;
    int highestDayTotal = 0;
    String highestDayName = '-';

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayLabel = DateFormat('E', 'id_ID').format(targetDate);
      final isToday = i == 0;

      final matching = validOrders.where((o) =>
        o.createdAt.year == targetDate.year &&
        o.createdAt.month == targetDate.month &&
        o.createdAt.day == targetDate.day
      ).toList();

      final dayTotal = matching.fold(0, (sum, o) => sum + o.total);
      sevenDaysTotal += dayTotal;
      if (dayTotal > highestDayTotal) {
        highestDayTotal = dayTotal;
        highestDayName = DateFormat('EEEE', 'id_ID').format(targetDate);
      }
      days.add((label: dayLabel, total: dayTotal, count: matching.length, isToday: isToday));
    }

    final maxVal = days.fold(1, (max, d) => d.total > max ? d.total : max);
    final avgDaily = (sevenDaysTotal / 7).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AKTIVITAS OMSET 7 HARI TERAKHIR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.burgundy,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Grafik Penjualan Ringkas',
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AdminColors.darkBrown),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab?.call(4), // Sales Analytics
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Lihat Detail →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),

          // ── Quick Financial Trend Strip ─────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AdminColors.warmWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AdminColors.border),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL OMSET 7 HARI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatCurrency(sevenDaysTotal),
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.burgundy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 26,
                    width: 1,
                    color: AdminColors.border,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RATA-RATA / HARI',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.mutedText,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatCurrency(avgDaily),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.darkBrown,
                        ),
                      ),
                    ],
                  ),
                  if (highestDayTotal > 0) ...[
                    const SizedBox(width: 12),
                    Container(
                      height: 26,
                      width: 1,
                      color: AdminColors.border,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.trending_up_rounded, size: 13, color: Color(0xFF047857)),
                          const SizedBox(width: 3),
                          Text(
                            'Puncak: $highestDayName',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Daily Pillar Bars with Background Track ─────────────────
          SizedBox(
            height: 145,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final hasSales = day.total > 0;
                final factor = hasSales ? (day.total / maxVal).clamp(0.12, 1.0) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nominal on top of column
                        SizedBox(
                          height: 16,
                          child: Center(
                            child: hasSales
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${(day.total / 1000).toStringAsFixed(0)}k',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AdminColors.burgundy,
                                      ),
                                    ),
                                  )
                                : Text(
                                    '-',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      color: AdminColors.mutedText.withValues(alpha: 0.6),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Background pillar track container
                        Container(
                          width: 22,
                          height: 75,
                          decoration: BoxDecoration(
                            color: AdminColors.sandBeige.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: day.isToday
                                  ? AdminColors.burgundy.withValues(alpha: 0.4)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: hasSales
                              ? Container(
                                  width: 22,
                                  height: (75 * factor).clamp(8.0, 75.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: day.isToday
                                          ? [AdminColors.burgundy, const Color(0xFF9E2A2B)]
                                          : [const Color(0xFF8B2635), const Color(0xFFA63D40)],
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                )
                              : Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 6),
                                  decoration: const BoxDecoration(
                                    color: AdminColors.sandBeige,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        // Day label with today indicator
                        Container(
                          padding: day.isToday
                              ? const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5)
                              : EdgeInsets.zero,
                          decoration: day.isToday
                              ? BoxDecoration(
                                  color: AdminColors.burgundy,
                                  borderRadius: BorderRadius.circular(6),
                                )
                              : null,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              day.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w700,
                                color: day.isToday ? Colors.white : AdminColors.darkBrown,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<OrderItemModel> allOrders) {
    final recent = allOrders.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANTREAN PESANAN TERAKHIR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.burgundy,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pesanan Masuk Terbaru',
                      style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AdminColors.darkBrown),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab?.call(1), // Orders
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Semua Antrean →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada pesanan masuk',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AdminColors.mutedText),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, _) => const Divider(color: AdminColors.divider, height: 16),
              itemBuilder: (context, index) {
                final order = recent[index];
                return InkWell(
                  onTap: () => widget.onViewOrderDetail?.call(order),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                runSpacing: 2,
                                children: [
                                  Text(
                                    order.orderNumber,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AdminColors.darkBrown,
                                    ),
                                  ),
                                  _buildBadge(order.status),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${order.customerName} • ${order.itemsSummary}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: AdminColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(order.total),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.burgundy,
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm').format(order.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: AdminColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStockAlertSection(List<ProductItem> lowStockItems) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lowStockItems.isNotEmpty ? const Color(0xFFFEF2F2) : AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lowStockItems.isNotEmpty ? const Color(0xFFFCA5A5) : AdminColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    lowStockItems.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                    color: lowStockItems.isNotEmpty ? AdminColors.error : AdminColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lowStockItems.isNotEmpty ? 'Peringatan Stok Menipis' : 'Status Persediaan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: lowStockItems.isNotEmpty ? AdminColors.error : AdminColors.darkBrown,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => widget.onNavigateToTab?.call(3), // Inventory
                child: Text(
                  'Buka Stok →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (lowStockItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Seluruh bahan baku & menu utama berada di atas batas minimum persediaan.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AdminColors.mutedText),
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lowStockItems.take(4).map((p) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.darkBrown,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: p.stock == 0 ? AdminColors.error : AdminColors.warning,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.stock == 0 ? 'HABIS' : '${p.stock} pcs',
                          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTopProductsSection(List<ProductItem> allProducts, Map<String, int> productUnitsSold) {
    final sorted = List<ProductItem>.from(allProducts);
    sorted.sort((a, b) {
      final sA = productUnitsSold[a.name] ?? 0;
      final sB = productUnitsSold[b.name] ?? 0;
      return sB.compareTo(sA);
    });

    final top4 = sorted.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'PRODUK TERLARIS MINGGU INI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => widget.onNavigateToTab?.call(2), // Menu
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(
                  'Katalog Menu →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: top4.length,
            separatorBuilder: (_, _) => const Divider(color: AdminColors.divider, height: 14),
            itemBuilder: (ctx, idx) {
              final prod = top4[idx];
              final sold = productUnitsSold[prod.name] ?? 0;
              return Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: idx == 0 ? AdminColors.burgundy : AdminColors.sandBeige,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: idx == 0 ? Colors.white : AdminColors.darkBrown,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Product Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: _buildProductThumbnail(prod),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.darkBrown,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${prod.category.toUpperCase()} • ${_formatCurrency(prod.price)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: AdminColors.mutedText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AdminColors.sandBeige.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$sold Unit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.burgundy,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumbnail(ProductItem prod) {
    if (prod.imageUrl.isNotEmpty) {
      if (prod.imageUrl.startsWith('assets/')) {
        return Image.asset(
          prod.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildProductPlaceholder(prod.name),
        );
      }
      return Image.network(
        prod.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildProductPlaceholder(prod.name),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AdminColors.sandBeige.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.burgundy),
              ),
            ),
          );
        },
      );
    }
    return _buildProductPlaceholder(prod.name);
  }

  Widget _buildProductPlaceholder(String name) {
    return Container(
      color: AdminColors.sandBeige.withValues(alpha: 0.5),
      child: const Center(
        child: Icon(Icons.lunch_dining_rounded, size: 22, color: AdminColors.burgundy),
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'PENDING':
        bg = AdminColors.statusPendingBg;
        text = AdminColors.statusPendingText;
        label = 'Menunggu';
        break;
      case 'CONFIRMED':
        bg = AdminColors.statusConfirmedBg;
        text = AdminColors.statusConfirmedText;
        label = 'Dikonfirmasi';
        break;
      case 'PREPARING':
        bg = AdminColors.statusPreparingBg;
        text = AdminColors.statusPreparingText;
        label = 'Disiapkan';
        break;
      case 'READY_FOR_PICKUP':
        bg = AdminColors.statusReadyBg;
        text = AdminColors.statusReadyText;
        label = 'Siap Ambil';
        break;
      case 'COMPLETED':
        bg = AdminColors.statusCompletedBg;
        text = AdminColors.statusCompletedText;
        label = 'Selesai';
        break;
      case 'CANCELLED':
        bg = AdminColors.statusCancelledBg;
        text = AdminColors.statusCancelledText;
        label = 'Batal';
        break;
      default:
        bg = AdminColors.warmWhite;
        text = AdminColors.darkBrown;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(fontSize: 8.5, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
