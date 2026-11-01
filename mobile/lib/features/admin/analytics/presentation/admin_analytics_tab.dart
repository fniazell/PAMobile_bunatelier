import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../../catalog/providers/catalog_provider.dart';
import '../../../converter/services/currency_service.dart';
import '../../../../data/mock/catalog_data.dart';

class AdminAnalyticsTab extends ConsumerStatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  ConsumerState<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends ConsumerState<AdminAnalyticsTab> {
  String _selectedPeriod = 'ALL'; // 'TODAY', 'WEEK', 'MONTH', 'ALL'
  String _selectedCategory = 'ALL'; // 'ALL', 'burger', 'croissant', 'sides', 'drinks', 'desserts'

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  String _formatUsd(double amount) {
    final fmt = NumberFormat.currency(locale: 'en_US', symbol: '\$ ', decimalDigits: 2);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final catalogState = ref.watch(catalogProductsProvider);
    final now = DateTime.now();

    // 1. Filter valid transactions by period
    final periodOrders = ordersState.orders.where((o) {
      if (o.status == 'CANCELLED') return false; // Abaikan pesanan yang dibatalkan
      switch (_selectedPeriod) {
        case 'TODAY':
          return o.createdAt.year == now.year &&
                 o.createdAt.month == now.month &&
                 o.createdAt.day == now.day;
        case 'WEEK':
          return o.createdAt.isAfter(now.subtract(const Duration(days: 7)));
        case 'MONTH':
          return o.createdAt.year == now.year && o.createdAt.month == now.month;
        default:
          return true;
      }
    }).toList();

    // 2. Metrics calculation
    final totalRevenue = periodOrders.fold(0, (sum, o) => sum + o.total);
    final totalOrdersCount = periodOrders.length;
    final averageOrderValue = totalOrdersCount > 0 ? (totalRevenue / totalOrdersCount).round() : 0;

    // Convert revenue to USD via CurrencyService
    final conversion = CurrencyService.instance.convert(
      amount: totalRevenue.toDouble(),
      fromCurrency: 'IDR',
      toCurrency: 'USD',
    );
    final usdEstimated = conversion.targetAmount;
    final rateInfo = conversion.rateInfoText.isNotEmpty
        ? conversion.rateInfoText
        : '1 USD ≈ Rp 16.100 (Benchmark Bun Atelier)';

    // 3. Units and Category Breakdown
    final Map<String, int> productUnits = {};
    int totalUnitsSold = 0;

    for (final order in periodOrders) {
      final entries = order.itemsSummary.split(',');
      for (final entry in entries) {
        final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(entry.trim());
        if (match != null) {
          final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
          final name = match.group(2)?.trim() ?? '';
          productUnits[name] = (productUnits[name] ?? 0) + qty;
          totalUnitsSold += qty;
        }
      }
    }

    // Category distribution
    final Map<String, int> categoryUnits = {
      'burger': 0,
      'croissant': 0,
      'sides': 0,
      'drinks': 0,
      'desserts': 0,
    };
    final Map<String, int> categoryRevenue = {
      'burger': 0,
      'croissant': 0,
      'sides': 0,
      'drinks': 0,
      'desserts': 0,
    };

    productUnits.forEach((name, units) {
      final product = catalogState.products.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
        orElse: () => CatalogData.allProducts.first,
      );
      final cat = product.category;
      if (categoryUnits.containsKey(cat)) {
        categoryUnits[cat] = (categoryUnits[cat] ?? 0) + units;
        categoryRevenue[cat] = (categoryRevenue[cat] ?? 0) + (units * product.price);
      }
    });

    // Top Selling products
    final allProducts = catalogState.products;
    final sortedProducts = List<ProductItem>.from(allProducts);
    sortedProducts.sort((a, b) {
      final unitsA = productUnits[a.name] ?? 0;
      final unitsB = productUnits[b.name] ?? 0;
      return unitsB.compareTo(unitsA);
    });

    final topProducts = sortedProducts.where((p) {
      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) return false;
      return (productUnits[p.name] ?? 0) > 0;
    }).take(5).toList();

    final lowestProducts = sortedProducts.where((p) {
      if (_selectedCategory != 'ALL' && p.category != _selectedCategory) return false;
      return true;
    }).toList().reversed.take(4).toList();

    // 4. Past 7 Days Daily Revenue & Transaction Counts for Combo Chart
    final List<({DateTime date, String dayName, int revenue, int txCount})> last7DaysData = [];
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayOrders = ordersState.orders.where((o) {
        if (o.status == 'CANCELLED') return false;
        return o.createdAt.year == targetDate.year &&
               o.createdAt.month == targetDate.month &&
               o.createdAt.day == targetDate.day;
      }).toList();

      final dayRev = dayOrders.fold(0, (sum, o) => sum + o.total);
      final dayName = DateFormat('E', 'id_ID').format(targetDate);
      last7DaysData.add((date: targetDate, dayName: dayName, revenue: dayRev, txCount: dayOrders.length));
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Container(
      color: AdminColors.warmWhite,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & Period / Category Selectors ──────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 640;

                final filters = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Category Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          items: const [
                            DropdownMenuItem(value: 'ALL', child: Text('Semua Kategori')),
                            DropdownMenuItem(value: 'burger', child: Text('Burgers')),
                            DropdownMenuItem(value: 'croissant', child: Text('Croissant Burgers')),
                            DropdownMenuItem(value: 'sides', child: Text('Sides')),
                            DropdownMenuItem(value: 'drinks', child: Text('Drinks')),
                            DropdownMenuItem(value: 'desserts', child: Text('Desserts')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                          style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                        ),
                      ),
                    ),
                    // Period Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          items: const [
                            DropdownMenuItem(value: 'TODAY', child: Text('Hari Ini')),
                            DropdownMenuItem(value: 'WEEK', child: Text('7 Hari Terakhir')),
                            DropdownMenuItem(value: 'MONTH', child: Text('Bulan Ini')),
                            DropdownMenuItem(value: 'ALL', child: Text('Semua Waktu')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedPeriod = val);
                          },
                          style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                        ),
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
                            'PERFORMANCE INTELLIGENCE',
                            style: AdminColors.sansUI(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Analisis Penjualan & Performa',
                            style: AdminColors.serifHeading(fontSize: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      filters,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PERFORMANCE INTELLIGENCE',
                            style: AdminColors.sansUI(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Analisis Penjualan & Performa',
                            style: AdminColors.serifHeading(fontSize: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    filters,
                  ],
                );
              },
            ),
            const SizedBox(height: 18),

            // ── Dual-Currency Financial Statement Banner ───────────────────────
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'TOTAL PENDAPATAN BERSIH (IDR & USD)',
                          style: AdminColors.sansUI(fontSize: 10.5, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminColors.sandBeige.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Dasar: IDR',
                          style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Amount in IDR (Large) & Estimated USD (Responsive Wrap)
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      Text(
                        _formatCurrency(totalRevenue),
                        style: AdminColors.serifHeading(fontSize: 28, color: AdminColors.burgundy),
                      ),
                      Text(
                        '≈ ${_formatUsd(usdEstimated)} USD',
                        style: AdminColors.sansUI(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Currency Conversion Disclaimer Footnote
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 14, color: AdminColors.mutedText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$rateInfo • Nilai konversi hanya untuk referensi visual dan tidak disimpan sebagai data transaksi.',
                          style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 4 Executive KPI Cards ──────────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmall = constraints.maxWidth < 600;
                return isSmall
                    ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildMetricCard('Total Pendapatan', _formatCurrency(totalRevenue), 'Excl. pesanan batal', Icons.monetization_on_outlined, AdminColors.burgundy)),
                              const SizedBox(width: 10),
                              Expanded(child: _buildMetricCard('Transaksi Berhasil', '$totalOrdersCount Pesanan', 'Rasio sukses 100%', Icons.check_circle_outline, AdminColors.success)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: _buildMetricCard('Unit Terjual', '$totalUnitsSold Porsi', 'Varian menu dinikmati', Icons.restaurant_outlined, const Color(0xFFD97706))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildMetricCard('Avg Order Value', _formatCurrency(averageOrderValue), 'Nilai per keranjang', Icons.shopping_basket_outlined, const Color(0xFF2563EB))),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildMetricCard('Total Pendapatan', _formatCurrency(totalRevenue), 'Excl. pesanan batal', Icons.monetization_on_outlined, AdminColors.burgundy)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard('Transaksi Berhasil', '$totalOrdersCount Pesanan', 'Rasio sukses 100%', Icons.check_circle_outline, AdminColors.success)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard('Unit Terjual', '$totalUnitsSold Porsi', 'Varian menu dinikmati', Icons.restaurant_outlined, const Color(0xFFD97706))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricCard('Avg Order Value', _formatCurrency(averageOrderValue), 'Nilai per keranjang', Icons.shopping_basket_outlined, const Color(0xFF2563EB))),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),

            // ── Combo Chart: Tren Pendapatan & Jumlah Transaksi (7 Hari) ──────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 640;
                      final legend = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 10, height: 10, color: AdminColors.burgundy),
                          const SizedBox(width: 4),
                          Text('Pendapatan', style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.darkBrown)),
                          const SizedBox(width: 12),
                          Container(width: 10, height: 4, color: const Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text('Transaksi', style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.darkBrown)),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GRAFIK KOMBINASI PENJUALAN',
                              style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tren Pendapatan & Volume (7 Hari)',
                              style: AdminColors.serifHeading(fontSize: 17),
                            ),
                            const SizedBox(height: 8),
                            legend,
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
                                  'GRAFIK KOMBINASI PENJUALAN',
                                  style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tren Pendapatan & Volume Transaksi (7 Hari)',
                                  style: AdminColors.serifHeading(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          legend,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Custom Combo Chart
                  SizedBox(
                    height: 190,
                    child: _buildComboChart(last7DaysData),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Asymmetric Dual Column: Donut Category Sales vs Best Sellers ────
            isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Donut Chart on Left (5 parts)
                      Expanded(
                        flex: 5,
                        child: _buildCategoryDonutCard(categoryUnits, categoryRevenue, totalUnitsSold),
                      ),
                      const SizedBox(width: 16),
                      // Horizontal Bar Chart on Right (5 parts)
                      Expanded(
                        flex: 5,
                        child: _buildTopProductsHorizontalCard(topProducts, productUnits),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildCategoryDonutCard(categoryUnits, categoryRevenue, totalUnitsSold),
                      const SizedBox(height: 16),
                      _buildTopProductsHorizontalCard(topProducts, productUnits),
                    ],
                  ),
            const SizedBox(height: 20),

            // ── Products Needing Marketing Attention ─────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rekomendasi Menu & Evaluasi Penjualan',
                          style: AdminColors.serifHeading(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Menu berikut memiliki volume penjualan paling rendah pada periode ini. Pertimbangkan kampanye bundling atau promosi khusus voucher:',
                    style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: lowestProducts.map((p) {
                      final sold = productUnits[p.name] ?? 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdminColors.warmWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AdminColors.sandBeige,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$sold porsi',
                                style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Metric Card ───────────────────────────────────────────────────────────
  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  title,
                  style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.mutedText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AdminColors.serifHeading(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Combo Chart (Bars for Revenue + Line overlay for Tx Count) ────────────
  Widget _buildComboChart(List<({DateTime date, String dayName, int revenue, int txCount})> data) {
    final maxRevenue = data.fold<int>(1, (max, item) => item.revenue > max ? item.revenue : max);
    final maxTx = data.fold<int>(1, (max, item) => item.txCount > max ? item.txCount : max);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight - 25; // 25px for day labels
        final stepX = width / data.length;

        return Stack(
          children: [
            // Y-axis background guidelines
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(height: 1, color: AdminColors.divider),
                Container(height: 1, color: AdminColors.divider),
                Container(height: 1, color: AdminColors.divider),
              ],
            ),

            // Bar Bars (Revenue)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 25,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((d) {
                  final barHeightFraction = maxRevenue > 0 ? (d.revenue / maxRevenue).clamp(0.04, 1.0) : 0.04;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.revenue > 0)
                        Text(
                          '${(d.revenue / 1000).round()}k',
                          style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                        ),
                      const SizedBox(height: 2),
                      Container(
                        width: 22,
                        height: height * barHeightFraction * 0.8,
                        decoration: BoxDecoration(
                          color: AdminColors.burgundy,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // Line & Dots overlay (Transaction count)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 25,
              child: CustomPaint(
                painter: _ComboLinePainter(data: data, maxTx: maxTx, stepX: stepX),
              ),
            ),

            // Bottom X-Axis Day Labels
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: data.map((d) {
                  return Text(
                    d.dayName,
                    style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Donut Chart for Category Sales Composition ───────────────────────────
  Widget _buildCategoryDonutCard(
    Map<String, int> categoryUnits,
    Map<String, int> categoryRevenue,
    int totalUnitsSold,
  ) {
    final categories = [
      (key: 'burger', label: 'Burgers', color: AdminColors.burgundy),
      (key: 'croissant', label: 'Croissant Burgers', color: const Color(0xFFD97706)),
      (key: 'sides', label: 'Sides & Fries', color: const Color(0xFF0284C7)),
      (key: 'drinks', label: 'Drinks', color: const Color(0xFF0D9488)),
      (key: 'desserts', label: 'Desserts', color: const Color(0xFF9333EA)),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KOMPOSISI KULINER',
            style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
          ),
          const SizedBox(height: 2),
          Text(
            'Penjualan per Kategori Menu',
            style: AdminColors.serifHeading(fontSize: 18),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              // Custom Donut Chart Painter
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    units: categories.map((c) => categoryUnits[c.key] ?? 0).toList(),
                    colors: categories.map((c) => c.color).toList(),
                    total: totalUnitsSold,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$totalUnitsSold', style: AdminColors.serifHeading(fontSize: 18)),
                        Text('Porsi', style: AdminColors.sansUI(fontSize: 9, color: AdminColors.mutedText)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categories.map((c) {
                    final units = categoryUnits[c.key] ?? 0;
                    final pct = totalUnitsSold > 0 ? ((units / totalUnitsSold) * 100).round() : 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.label,
                              style: AdminColors.sansUI(fontSize: 10.5, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$units pcs ($pct%)',
                            style: AdminColors.sansUI(fontSize: 9.5, fontWeight: FontWeight.bold, color: AdminColors.mutedText),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Horizontal Bar Chart for Top 5 Best Sellers ───────────────────────────
  Widget _buildTopProductsHorizontalCard(List<ProductItem> topProducts, Map<String, int> productUnits) {
    final maxUnits = topProducts.isNotEmpty
        ? topProducts.fold<int>(1, (max, p) => (productUnits[p.name] ?? 0) > max ? (productUnits[p.name] ?? 0) : max)
        : 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
                      'PRODUK TERLARIS (TOP 5)',
                      style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Peringkat Berdasarkan Porsi',
                      style: AdminColors.serifHeading(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.leaderboard_outlined, color: AdminColors.burgundy, size: 20),
            ],
          ),
          const SizedBox(height: 18),

          if (topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Belum ada data pesanan pada periode ini', style: AdminColors.sansUI(color: AdminColors.mutedText)),
              ),
            )
          else
            Column(
              children: topProducts.asMap().entries.map((entry) {
                final idx = entry.key;
                final prod = entry.value;
                final units = productUnits[prod.name] ?? 0;
                final fraction = (units / maxUnits).clamp(0.05, 1.0);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: idx == 0 ? AdminColors.burgundy : AdminColors.sandBeige,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${idx + 1}',
                                      style: AdminColors.sansUI(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: idx == 0 ? Colors.white : AdminColors.darkBrown,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    prod.name,
                                    style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$units Pcs • ${_formatCurrency(units * prod.price)}',
                            style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.burgundy),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: AdminColors.warmWhite,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            idx == 0 ? AdminColors.burgundy : const Color(0xFFD97706),
                          ),
                          minHeight: 6,
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
}

// ── Custom Painter: Combo Line for Transactions ────────────────────────────
class _ComboLinePainter extends CustomPainter {
  final List<({DateTime date, String dayName, int revenue, int txCount})> data;
  final int maxTx;
  final double stepX;

  _ComboLinePainter({required this.data, required this.maxTx, required this.stepX});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final paintDot = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final paintDotBorder = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final List<Offset> points = [];

    for (int i = 0; i < data.length; i++) {
      final x = (i + 0.5) * stepX;
      final tx = data[i].txCount;
      final yFraction = maxTx > 0 ? (tx / maxTx).clamp(0.0, 1.0) : 0.0;
      final y = size.height - (yFraction * size.height * 0.75) - 10;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paintLine);

    for (final pt in points) {
      canvas.drawCircle(pt, 4.5, paintDot);
      canvas.drawCircle(pt, 4.5, paintDotBorder);
    }
  }

  @override
  bool shouldRepaint(covariant _ComboLinePainter oldDelegate) => true;
}

// ── Custom Painter: Donut Chart ─────────────────────────────────────────────
class _DonutChartPainter extends CustomPainter {
  final List<int> units;
  final List<Color> colors;
  final int total;

  _DonutChartPainter({required this.units, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    if (total == 0) {
      final emptyPaint = Paint()
        ..color = AdminColors.sandBeige.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius - strokeWidth / 2, emptyPaint);
      return;
    }

    double startAngle = -math.pi / 2;

    for (int i = 0; i < units.length; i++) {
      final sweepAngle = (units[i] / total) * (2 * math.pi);
      if (sweepAngle <= 0) continue;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) => true;
}
