import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../../orders/models/order_model.dart';
import '../../../catalog/providers/catalog_provider.dart';

class AdminReportsTab extends ConsumerStatefulWidget {
  const AdminReportsTab({super.key});

  @override
  ConsumerState<AdminReportsTab> createState() => _AdminReportsTabState();
}

class _AdminReportsTabState extends ConsumerState<AdminReportsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final catalogState = ref.watch(catalogProductsProvider);

    // Filter orders by date range
    final filteredOrders = ordersState.orders.where((o) {
      final isAfterStart = o.createdAt.isAfter(_selectedDateRange.start.subtract(const Duration(days: 1)));
      final isBeforeEnd = o.createdAt.isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
      return isAfterStart && isBeforeEnd;
    }).toList();

    final validOrders = filteredOrders.where((o) => o.status != 'CANCELLED').toList();
    final cancelledOrders = filteredOrders.where((o) => o.status == 'CANCELLED').toList();

    final grossSales = validOrders.fold(0, (sum, o) => sum + o.subtotal);
    final totalTax = validOrders.fold(0, (sum, o) => sum + o.tax);
    final totalDelivery = validOrders.fold(0, (sum, o) => sum + o.deliveryFee);
    final netRevenue = validOrders.fold(0, (sum, o) => sum + o.total);

    // Filter stock logs by date range
    final stockLogs = catalogState.stockLogs.where((log) {
      final isAfterStart = log.timestamp.isAfter(_selectedDateRange.start.subtract(const Duration(days: 1)));
      final isBeforeEnd = log.timestamp.isBefore(_selectedDateRange.end.add(const Duration(days: 1)));
      return isAfterStart && isBeforeEnd;
    }).toList();

    return Container(
      color: AdminColors.warmWhite,
      child: Column(
        children: [
          // ── Header & Date Range Picker ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
                    final titleWidget = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FINANCIAL & OPERATIONAL AUDIT',
                          style: AdminColors.sansUI(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.burgundy,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pusat Rekapitulasi & Laporan',
                          style: AdminColors.serifHeading(fontSize: isNarrow ? 20 : 24),
                        ),
                      ],
                    );

                    final actionsWidget = Row(
                      mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        Expanded(
                          flex: isNarrow ? 1 : 0,
                          child: OutlinedButton.icon(
                            onPressed: () => _showExportPreview(context, filteredOrders, validOrders, cancelledOrders, netRevenue),
                            icon: const Icon(Icons.print_outlined, size: 16, color: AdminColors.burgundy),
                            label: Text('Pratinjau Cetak', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AdminColors.burgundy),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: isNarrow ? 1 : 0,
                          child: ElevatedButton.icon(
                            onPressed: () => _showCsvExportModal(context, validOrders),
                            icon: const Icon(Icons.download, size: 16, color: Colors.white),
                            label: Text('Ekspor CSV', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.burgundy,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    );

                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          const SizedBox(height: 12),
                          actionsWidget,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: titleWidget),
                        const SizedBox(width: 16),
                        actionsWidget,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Active Date Range Pill & Date Picker
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    InkWell(
                      onTap: () => _pickDateRange(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AdminColors.sandBeige,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AdminColors.burgundy),
                            const SizedBox(width: 8),
                            Text(
                              '${DateFormat('dd MMM yyyy').format(_selectedDateRange.start)} — ${DateFormat('dd MMM yyyy').format(_selectedDateRange.end)}',
                              style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.darkBrown),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_drop_down, size: 18, color: AdminColors.burgundy),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      '${filteredOrders.length} Transaksi Tercatat',
                      style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.mutedText),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5 Dedicated Report Tabs
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: AdminColors.burgundy,
                  indicatorWeight: 3,
                  labelColor: AdminColors.burgundy,
                  unselectedLabelColor: AdminColors.mutedText,
                  labelStyle: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '1. Penjualan & Keuangan'),
                    Tab(text: '2. Buku Transaksi'),
                    Tab(text: '3. Produk Terjual'),
                    Tab(text: '4. Pembatalan Pesanan'),
                    Tab(text: '5. Mutasi Stok'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Bar Views ───────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Sales & Financial Statement
                _buildSalesReportTab(grossSales, totalTax, totalDelivery, netRevenue, validOrders),

                // 2. Transactions Ledger
                _buildTransactionsReportTab(filteredOrders),

                // 3. Products Sold Breakdown
                _buildProductsSoldReportTab(validOrders, catalogState),

                // 4. Cancellations Analysis
                _buildCancellationsReportTab(cancelledOrders),

                // 5. Stock Movements Log
                _buildStockMovementsReportTab(stockLogs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 1: Financial Statement ────────────────────────────────────────────
  Widget _buildSalesReportTab(
    int grossSales,
    int totalTax,
    int totalDelivery,
    int netRevenue,
    List<OrderItemModel> validOrders,
  ) {
    final paidOrders = validOrders.where((o) => o.paymentStatus == 'PAID').toList();
    final pendingOrders = validOrders.where((o) => o.paymentStatus != 'PAID').toList();
    final paidRevenue = paidOrders.fold(0, (s, o) => s + o.total);
    final pendingRevenue = pendingOrders.fold(0, (s, o) => s + o.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  'LAPORAN REKAPITULASI PENDAPATAN & PAJAK',
                  style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
                ),
                const SizedBox(height: 16),
                _buildReportRow('Penjualan Menu Kotor (Gross Subtotal)', _formatCurrency(grossSales)),
                const SizedBox(height: 10),
                _buildReportRow('Pajak PB1 Terkumpul (10%)', _formatCurrency(totalTax)),
                const SizedBox(height: 10),
                _buildReportRow('Total Ongkos Kirim Diterima', _formatCurrency(totalDelivery)),
                const Divider(color: AdminColors.divider, height: 24),
                _buildReportRow('Total Omset Bersih (Net Revenue)', _formatCurrency(netRevenue), isHighlight: true),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.warmWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Diterima Lunas (PAID)', style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.success)),
                            Text(_formatCurrency(paidRevenue), style: AdminColors.serifHeading(fontSize: 16, color: AdminColors.success)),
                            Text('${paidOrders.length} Pesanan Lunas', style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: AdminColors.divider),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Menunggu Pelunasan (PENDING)', style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                            Text(_formatCurrency(pendingRevenue), style: AdminColors.serifHeading(fontSize: 16, color: const Color(0xFFD97706))),
                            Text('${pendingOrders.length} Pesanan Kasir', style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Transactions Ledger ────────────────────────────────────────────
  Widget _buildTransactionsReportTab(List<OrderItemModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text('Tidak ada transaksi pada periode ini', style: AdminColors.sansUI(color: AdminColors.mutedText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isCancelled = order.status == 'CANCELLED';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminColors.sansUI(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.burgundy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            order.status,
                            style: AdminColors.sansUI(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCancelled ? AdminColors.error : AdminColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.customerName} • ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)} • ${order.paymentMethod}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                    ),
                    Text(order.itemsSummary, style: AdminColors.sansUI(fontSize: 11, color: AdminColors.darkBrown), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text(
                _formatCurrency(order.total),
                style: AdminColors.sansUI(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isCancelled ? AdminColors.error : AdminColors.darkBrown,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 3: Products Sold Breakdown ────────────────────────────────────────
  Widget _buildProductsSoldReportTab(List<OrderItemModel> validOrders, CatalogProductsState catalogState) {
    final Map<String, int> productUnits = {};

    for (final order in validOrders) {
      for (final entry in order.itemsSummary.split(',')) {
        final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(entry.trim());
        if (match != null) {
          final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
          final name = match.group(2)?.trim() ?? '';
          productUnits[name] = (productUnits[name] ?? 0) + qty;
        }
      }
    }

    final totalUnits = productUnits.values.fold(0, (s, q) => s + q);
    final sortedList = productUnits.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sortedList.isEmpty) {
      return Center(
        child: Text('Belum ada produk terjual pada periode ini', style: AdminColors.sansUI(color: AdminColors.mutedText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedList.length,
      itemBuilder: (context, index) {
        final entry = sortedList[index];
        final name = entry.key;
        final units = entry.value;

        // Lookup product price
        final productMatch = catalogState.products.where((p) => p.name.toLowerCase() == name.toLowerCase());
        final price = productMatch.isNotEmpty ? productMatch.first.price : 55000;
        final revenue = units * price;
        final pct = totalUnits > 0 ? ((units / totalUnits) * 100).toStringAsFixed(1) : '0';

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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: index < 3 ? AdminColors.burgundy : AdminColors.sandBeige,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: AdminColors.sansUI(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: index < 3 ? Colors.white : AdminColors.darkBrown,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('$units porsi terjual ($pct% dari total porsi)', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                  ],
                ),
              ),
              Text(
                _formatCurrency(revenue),
                style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.burgundy),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 4: Cancellations Analysis ─────────────────────────────────────────
  Widget _buildCancellationsReportTab(List<OrderItemModel> cancelledOrders) {
    final lostRevenue = cancelledOrders.fold(0, (sum, o) => sum + o.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cancel, color: AdminColors.error, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total ${cancelledOrders.length} Pesanan Dibatalkan',
                        style: AdminColors.sansUI(fontSize: 14, fontWeight: FontWeight.bold, color: AdminColors.error),
                      ),
                      Text(
                        'Potensi pendapatan batal: ${_formatCurrency(lostRevenue)} (Seluruh stok telah otomatis dikembalikan)',
                        style: AdminColors.sansUI(fontSize: 11, color: AdminColors.darkBrown),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (cancelledOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.thumb_up_alt_outlined, color: AdminColors.success, size: 40),
                    const SizedBox(height: 10),
                    Text('Tidak ada pembatalan pesanan pada periode ini!', style: AdminColors.serifHeading(fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cancelledOrders.length,
              itemBuilder: (context, index) {
                final order = cancelledOrders[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                              '${order.orderNumber} • ${order.customerName}',
                              style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_formatCurrency(order.total), style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.error)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Waktu Pesan: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
                        style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
                      ),
                      Text(order.itemsSummary, style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Tab 5: Stock Movements Log ─────────────────────────────────────────────
  Widget _buildStockMovementsReportTab(List<StockHistoryLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Text('Tidak ada mutasi stok pada rentang tanggal ini', style: AdminColors.sansUI(color: AdminColors.mutedText)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final isPositive = log.delta > 0;

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
              Icon(
                isPositive ? Icons.add_circle : Icons.remove_circle,
                size: 20,
                color: isPositive ? AdminColors.success : AdminColors.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.productName, style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${log.reason} • ${DateFormat('dd MMM, HH:mm').format(log.timestamp)}', style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : ''}${log.delta} unit',
                    style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.w800, color: isPositive ? AdminColors.success : AdminColors.error),
                  ),
                  Text('Stok: ${log.previousStock} → ${log.newStock}', style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AdminColors.sansUI(
              fontSize: isHighlight ? 14 : 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AdminColors.darkBrown : AdminColors.mutedText,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AdminColors.serifHeading(
            fontSize: isHighlight ? 18 : 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? AdminColors.burgundy : AdminColors.darkBrown,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AdminColors.burgundy,
            colorScheme: const ColorScheme.light(primary: AdminColors.burgundy),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _showExportPreview(
    BuildContext context,
    List<OrderItemModel> allOrders,
    List<OrderItemModel> validOrders,
    List<OrderItemModel> cancelledOrders,
    int netRevenue,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: AdminColors.burgundy),
              const SizedBox(width: 10),
              Text('Pratinjau Audit Resmi Gerai', style: AdminColors.serifHeading(fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Text('BUN ATELIER — CRAFTED TO CRAVE', style: AdminColors.sansUI(fontWeight: FontWeight.w800, fontSize: 13, color: AdminColors.burgundy)),
                        Text('Outlet Senopati • Official Financial Audit', style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                        Text('Periode: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange.end)}', style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                  Text('RINGKASAN EKSEKUTIF KEUANGAN', style: AdminColors.sansUI(fontWeight: FontWeight.bold, fontSize: 11, color: AdminColors.burgundy)),
                  const SizedBox(height: 6),
                  Text('• Total Transaksi Sah: ${validOrders.length} Pesanan'),
                  Text('• Total Pembatalan: ${cancelledOrders.length} Pesanan'),
                  Text('• Total Omset Bersih: ${_formatCurrency(netRevenue)}'),
                  Text('• Waktu Unduh Laporan: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())}'),
                  const SizedBox(height: 14),
                  Text('Laporan ini siap diverifikasi oleh pihak manajemen dan akuntansi Bun Atelier.', style: AdminColors.sansUI(fontSize: 11, fontStyle: FontStyle.italic, color: AdminColors.mutedText)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AdminColors.success, content: Text('Laporan siap dicetak atau disimpan.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
              child: const Text('Cetak Ringkasan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showCsvExportModal(BuildContext context, List<OrderItemModel> validOrders) {
    // Generate CSV string
    final buffer = StringBuffer();
    buffer.writeln('No. Pesanan,Tanggal,Nama Pelanggan,Tipe,Metode Pembayaran,Status,Total (IDR)');
    for (final o in validOrders) {
      final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(o.createdAt);
      buffer.writeln('${o.orderNumber},$dateStr,"${o.customerName}",${o.orderType},${o.paymentMethod},${o.status},${o.total}');
    }

    final csvText = buffer.toString();

    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Ekspor Laporan CSV', style: AdminColors.serifHeading(fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data transaksi sebanyak ${validOrders.length} baris telah disiapkan dalam format CSV standar (dapat dibuka di Microsoft Excel atau Google Sheets).', style: AdminColors.sansUI(fontSize: 12)),
              const SizedBox(height: 14),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AdminColors.warmWhite, borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  child: Text(csvText, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(diagCtx), child: const Text('Batal')),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvText));
                Navigator.pop(diagCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(backgroundColor: AdminColors.success, content: Text('Data CSV berhasil disalin ke clipboard!')),
                );
              },
              icon: const Icon(Icons.copy, size: 14, color: Colors.white),
              label: const Text('Salin CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
            ),
          ],
        );
      },
    );
  }
}
