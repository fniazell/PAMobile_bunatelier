import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/admin_colors.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../../orders/models/order_model.dart';

class AdminOrdersTab extends ConsumerStatefulWidget {
  final OrderItemModel? initialSelectedOrder;

  const AdminOrdersTab({super.key, this.initialSelectedOrder});

  @override
  ConsumerState<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends ConsumerState<AdminOrdersTab> {
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String? _selectedOrderId;

  final List<({String key, String label})> _filterTabs = const [
    (key: 'ALL', label: 'Semua'),
    (key: 'PENDING', label: 'Menunggu'),
    (key: 'CONFIRMED', label: 'Dikonfirmasi'),
    (key: 'PREPARING', label: 'Disiapkan'),
    (key: 'READY_FOR_PICKUP', label: 'Siap Diambil'),
    (key: 'COMPLETED', label: 'Selesai'),
    (key: 'CANCELLED', label: 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedOrder != null) {
      _selectedOrderId = widget.initialSelectedOrder!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // If on small screen, open sheet
        if (mounted && MediaQuery.of(context).size.width < 900) {
          _showOrderDetailModal(widget.initialSelectedOrder!);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final allOrders = ordersState.orders;

    // Filter by status and search query
    final filteredOrders = allOrders.where((order) {
      if (_selectedStatusFilter != 'ALL' &&
          order.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchNumber = order.orderNumber.toLowerCase().contains(q);
        final matchCustomer = order.customerName.toLowerCase().contains(q);
        final matchSummary = order.itemsSummary.toLowerCase().contains(q);
        if (!matchNumber && !matchCustomer && !matchSummary) return false;
      }
      return true;
    }).toList();

    // Ensure selected order is valid if available
    OrderItemModel? selectedOrder;
    if (_selectedOrderId != null) {
      final match = allOrders.where((o) => o.id == _selectedOrderId);
      if (match.isNotEmpty) {
        selectedOrder = match.first;
      }
    }
    if (selectedOrder == null && filteredOrders.isNotEmpty) {
      selectedOrder = filteredOrders.first;
      _selectedOrderId = selectedOrder.id;
    }

    final isWide = MediaQuery.of(context).size.width >= 900;

    final headerAndFilters = Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: const BoxDecoration(
              color: AdminColors.warmWhite,
              border: Border(bottom: BorderSide(color: AdminColors.border)),
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
                            'KITCHEN & DISPATCH OPERATIONS',
                            style: AdminColors.sansUI(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                              letterSpacing: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Antrean Pesanan',
                            style: AdminColors.serifHeading(fontSize: 22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AdminColors.burgundy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${filteredOrders.length} Pesanan',
                        style: AdminColors.sansUI(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search field & quick counts
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari no. pesanan, pelanggan, menu...',
                          hintStyle: AdminColors.sansUI(
                            color: AdminColors.mutedText,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AdminColors.burgundy,
                            size: 20,
                          ),
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AdminColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AdminColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal Status Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filterTabs.map((tab) {
                      final isSelected = _selectedStatusFilter == tab.key;
                      final count = tab.key == 'ALL'
                          ? allOrders.length
                          : allOrders.where((o) => o.status == tab.key).length;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${tab.label} ($count)'),
                          labelStyle: AdminColors.sansUI(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AdminColors.darkBrown,
                          ),
                          selected: isSelected,
                          selectedColor: AdminColors.burgundy,
                          backgroundColor: AdminColors.sandBeige,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          side: BorderSide.none,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedStatusFilter = tab.key),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );

    if (isWide) {
      return Container(
        color: AdminColors.warmWhite,
        child: Column(
          children: [
            headerAndFilters,
            Expanded(
              child: filteredOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.receipt_outlined,
                            size: 48,
                            color: AdminColors.mutedText,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ada pesanan ditemukan',
                            style: AdminColors.serifHeading(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coba ubah kata kunci pencarian atau filter status',
                            style: AdminColors.sansUI(
                              fontSize: 12,
                              color: AdminColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 380,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              16,
                              12,
                              12,
                              24,
                            ),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final isItemActive =
                                  order.id == selectedOrder?.id;
                              return _buildOrderListItem(
                                order: order,
                                isSelected: isItemActive,
                                onTap: () {
                                  setState(
                                    () => _selectedOrderId = order.id,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(
                          width: 1,
                          thickness: 1,
                          color: AdminColors.border,
                        ),
                        Expanded(
                          child: selectedOrder != null
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(24),
                                  child: _buildDetailPanel(
                                    selectedOrder,
                                    ref,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    // ── Mobile Screen: Unified CustomScrollView (Header, filters, search, and list scroll together) ──
    return Container(
      color: AdminColors.warmWhite,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: headerAndFilters,
          ),
          if (filteredOrders.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 20,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.receipt_outlined,
                        size: 48,
                        color: AdminColors.mutedText,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada pesanan ditemukan',
                        style: AdminColors.serifHeading(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coba ubah kata kunci pencarian atau filter status',
                        style: AdminColors.sansUI(
                          fontSize: 12,
                          color: AdminColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              sliver: SliverList.builder(
                itemCount: filteredOrders.length,
                itemBuilder: (context, index) {
                  final order = filteredOrders[index];
                  return _buildOrderListItem(
                    order: order,
                    isSelected: false,
                    onTap: () => _showOrderDetailModal(order),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Order Item Card / Tile ────────────────────────────────────────────────
  Widget _buildOrderListItem({
    required OrderItemModel order,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AdminColors.burgundy : AdminColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AdminColors.burgundy.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top: Order Number & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminColors.sansUI(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                            ),
                          ),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(order.createdAt),
                      style: AdminColors.sansUI(
                        fontSize: 11,
                        color: AdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Customer Name & Order Type
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 15,
                      color: AdminColors.darkBrown,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: AdminColors.sansUI(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: order.orderType == 'DELIVERY'
                            ? const Color(0xFFEFF6FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        order.orderType,
                        style: AdminColors.sansUI(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: order.orderType == 'DELIVERY'
                              ? Colors.blue.shade800
                              : AdminColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Items summary
                Text(
                  order.itemsSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminColors.sansUI(
                    fontSize: 11,
                    color: AdminColors.mutedText,
                  ),
                ),
                const Divider(color: AdminColors.divider, height: 16),

                // Bottom row: Payment status + Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: order.paymentStatus == 'PAID'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${order.paymentStatus} • ${order.paymentMethod}',
                        style: AdminColors.sansUI(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: order.paymentStatus == 'PAID'
                              ? AdminColors.success
                              : AdminColors.warning,
                        ),
                      ),
                    ),
                    Text(
                      _formatCurrency(order.total),
                      style: AdminColors.sansUI(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wide Screen Order Detail Panel ────────────────────────────────────────
  Widget _buildDetailPanel(OrderItemModel liveOrder, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order Number, Date, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        liveOrder.orderNumber,
                        style: AdminColors.serifHeading(fontSize: 26),
                      ),
                      const SizedBox(width: 12),
                      _buildStatusBadge(liveOrder.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat(
                      'EEEE, dd MMMM yyyy • HH:mm',
                      'id_ID',
                    ).format(liveOrder.createdAt),
                    style: AdminColors.sansUI(
                      fontSize: 12,
                      color: AdminColors.mutedText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.sandBeige,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  liveOrder.orderType,
                  style: AdminColors.sansUI(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.burgundy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Stepper Visual
          _buildStatusProgressStepper(liveOrder.status),
          const SizedBox(height: 24),

          // Two-column layout for details: Customer on Left, Financial on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Information Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INFORMASI PELANGGAN',
                        style: AdminColors.sansUI(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.burgundy,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 16,
                            color: AdminColors.darkBrown,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            liveOrder.customerName,
                            style: AdminColors.sansUI(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (liveOrder.customerPhone != null &&
                          liveOrder.customerPhone!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: AdminColors.mutedText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              liveOrder.customerPhone!,
                              style: AdminColors.sansUI(
                                fontSize: 12,
                                color: AdminColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (liveOrder.deliveryAddress != null &&
                          liveOrder.deliveryAddress!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: AdminColors.burgundy,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                liveOrder.deliveryAddress!,
                                style: AdminColors.sansUI(
                                  fontSize: 12,
                                  color: AdminColors.darkBrown,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (liveOrder.notes != null &&
                          liveOrder.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 14,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Catatan: "${liveOrder.notes}"',
                                  style: AdminColors.sansUI(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF92400E),
                                  ),
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
              const SizedBox(width: 16),

              // Payment & Pricing Breakdown Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RINCIAN PEMBAYARAN',
                        style: AdminColors.sansUI(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.burgundy,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPriceRow(
                        'Subtotal',
                        _formatCurrency(liveOrder.subtotal),
                      ),
                      const SizedBox(height: 4),
                      _buildPriceRow(
                        'Pajak PB1 (10%)',
                        _formatCurrency(liveOrder.tax),
                      ),
                      if (liveOrder.deliveryFee > 0) ...[
                        const SizedBox(height: 4),
                        _buildPriceRow(
                          'Biaya Antar',
                          _formatCurrency(liveOrder.deliveryFee),
                        ),
                      ],
                      const Divider(color: AdminColors.divider, height: 16),
                      _buildPriceRow(
                        'Total Pembayaran',
                        _formatCurrency(liveOrder.total),
                        isBold: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode: ${liveOrder.paymentMethod}',
                            style: AdminColors.sansUI(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              final nextPay = liveOrder.paymentStatus == 'PAID'
                                  ? 'PENDING'
                                  : 'PAID';
                              ref
                                  .read(ordersProvider.notifier)
                                  .updatePaymentStatus(liveOrder.id, nextPay);
                            },
                            icon: Icon(
                              liveOrder.paymentStatus == 'PAID'
                                  ? Icons.check_circle
                                  : Icons.schedule,
                              size: 13,
                              color: liveOrder.paymentStatus == 'PAID'
                                  ? AdminColors.success
                                  : AdminColors.warning,
                            ),
                            label: Text(
                              liveOrder.paymentStatus == 'PAID'
                                  ? 'LUNAS (Ubah)'
                                  : 'PENDING (Ubah)',
                              style: AdminColors.sansUI(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: liveOrder.paymentStatus == 'PAID'
                                    ? AdminColors.success
                                    : AdminColors.warning,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              minimumSize: const Size(60, 26),
                              side: BorderSide(
                                color: liveOrder.paymentStatus == 'PAID'
                                    ? AdminColors.success
                                    : AdminColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Order Items Table / List
          Text(
            'DAFTAR PRODUK PESANAN',
            style: AdminColors.sansUI(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AdminColors.burgundy,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              children: liveOrder.itemsSummary.split(',').map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AdminColors.sandBeige.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: AdminColors.burgundy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.trim(),
                          style: AdminColors.sansUI(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Operational Action Workflow Buttons
          Text(
            'TINDAKAN OPERASIONAL STATUS',
            style: AdminColors.sansUI(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AdminColors.burgundy,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _buildStatusTransitionButtons(context, liveOrder, ref),
        ],
      ),
    );
  }

  // ── Visual Progress Stepper ───────────────────────────────────────────────
  Widget _buildStatusProgressStepper(String status) {
    if (status == 'CANCELLED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AdminColors.statusCancelledBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cancel,
              size: 16,
              color: AdminColors.statusCancelledText,
            ),
            const SizedBox(width: 8),
            Text(
              'Pesanan telah Dibatalkan. Stok telah dikembalikan ke inventaris.',
              style: AdminColors.sansUI(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AdminColors.statusCancelledText,
              ),
            ),
          ],
        ),
      );
    }

    final steps = [
      (key: 'PENDING', label: 'Menunggu'),
      (key: 'CONFIRMED', label: 'Dikonfirmasi'),
      (key: 'PREPARING', label: 'Disiapkan'),
      (key: 'READY_FOR_PICKUP', label: 'Siap Diambil'),
      (key: 'COMPLETED', label: 'Selesai'),
    ];

    int currentIndex = steps.indexWhere((s) => s.key == status);
    if (currentIndex == -1) currentIndex = 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              // Connecting line
              final stepBefore = index ~/ 2;
              final isPassed = stepBefore < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  color: isPassed ? AdminColors.burgundy : AdminColors.border,
                ),
              );
            } else {
              // Step circle & label
              final stepIdx = index ~/ 2;
              final isDone = stepIdx <= currentIndex;
              final isCurrent = stepIdx == currentIndex;

              return SizedBox(
                width: constraints.maxWidth < 360 ? 46 : 56,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? AdminColors.burgundy : Colors.white,
                        border: Border.all(
                          color: isDone
                              ? AdminColors.burgundy
                              : AdminColors.border,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              )
                            : Text(
                                '${stepIdx + 1}',
                                style: AdminColors.sansUI(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: AdminColors.mutedText,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[stepIdx].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AdminColors.sansUI(
                        fontSize: 8.5,
                        fontWeight: isCurrent
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isCurrent
                            ? AdminColors.burgundy
                            : AdminColors.mutedText,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        );
      },
    );
  }

  // ── Bottom Sheet Detail for Compact/Mobile Screens ───────────────────────
  void _showOrderDetailModal(OrderItemModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentOrders = ref.watch(ordersProvider).orders;
            final liveOrder = currentOrders.firstWhere(
              (o) => o.id == order.id,
              orElse: () => order,
            );

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle Bar & Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AdminColors.divider),
                      ),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        liveOrder.orderNumber,
                                        style: AdminColors.serifHeading(
                                          fontSize: 19,
                                        ),
                                      ),
                                      _buildStatusBadge(liveOrder.status),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat(
                                      'EEEE, dd MMMM yyyy • HH:mm',
                                      'id_ID',
                                    ).format(liveOrder.createdAt),
                                    style: AdminColors.sansUI(
                                      fontSize: 10.5,
                                      color: AdminColors.mutedText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Detail Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusProgressStepper(liveOrder.status),
                          const SizedBox(height: 18),

                          // Customer Card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminColors.warmWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INFORMASI PELANGGAN',
                                  style: AdminColors.sansUI(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AdminColors.burgundy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      size: 16,
                                      color: AdminColors.darkBrown,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      liveOrder.customerName,
                                      style: AdminColors.sansUI(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (liveOrder.customerPhone != null &&
                                    liveOrder.customerPhone!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone,
                                        size: 16,
                                        color: AdminColors.mutedText,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        liveOrder.customerPhone!,
                                        style: AdminColors.sansUI(
                                          fontSize: 12,
                                          color: AdminColors.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (liveOrder.deliveryAddress != null &&
                                    liveOrder.deliveryAddress!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 16,
                                        color: AdminColors.burgundy,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          liveOrder.deliveryAddress!,
                                          style: AdminColors.sansUI(
                                            fontSize: 12,
                                            color: AdminColors.darkBrown,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (liveOrder.notes != null &&
                                    liveOrder.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.note_alt_outlined,
                                        size: 16,
                                        color: AdminColors.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Catatan: "${liveOrder.notes}"',
                                          style: AdminColors.sansUI(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: AdminColors.darkBrown,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Order Items
                          Text(
                            'DAFTAR PRODUK',
                            style: AdminColors.sansUI(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: liveOrder.itemsSummary.split(',').map((
                                item,
                              ) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.restaurant_menu,
                                        size: 14,
                                        color: AdminColors.burgundy,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.trim(),
                                          style: AdminColors.sansUI(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pricing Breakdown
                          Text(
                            'RINCIAN BIAYA & PEMBAYARAN',
                            style: AdminColors.sansUI(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AdminColors.warmWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AdminColors.border),
                            ),
                            child: Column(
                              children: [
                                _buildPriceRow(
                                  'Subtotal',
                                  _formatCurrency(liveOrder.subtotal),
                                ),
                                const SizedBox(height: 4),
                                _buildPriceRow(
                                  'Pajak PB1 (10%)',
                                  _formatCurrency(liveOrder.tax),
                                ),
                                if (liveOrder.deliveryFee > 0) ...[
                                  const SizedBox(height: 4),
                                  _buildPriceRow(
                                    'Biaya Antar',
                                    _formatCurrency(liveOrder.deliveryFee),
                                  ),
                                ],
                                const Divider(
                                  color: AdminColors.divider,
                                  height: 16,
                                ),
                                _buildPriceRow(
                                  'Total Pembayaran',
                                  _formatCurrency(liveOrder.total),
                                  isBold: true,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Metode: ${liveOrder.paymentMethod}',
                                      style: AdminColors.sansUI(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        final nextPay =
                                            liveOrder.paymentStatus == 'PAID'
                                            ? 'PENDING'
                                            : 'PAID';
                                        ref
                                            .read(ordersProvider.notifier)
                                            .updatePaymentStatus(
                                              liveOrder.id,
                                              nextPay,
                                            );
                                      },
                                      icon: Icon(
                                        liveOrder.paymentStatus == 'PAID'
                                            ? Icons.check_circle
                                            : Icons.schedule,
                                        size: 14,
                                        color: liveOrder.paymentStatus == 'PAID'
                                            ? AdminColors.success
                                            : AdminColors.warning,
                                      ),
                                      label: Text(
                                        liveOrder.paymentStatus == 'PAID'
                                            ? 'LUNAS (Ubah)'
                                            : 'PENDING (Ubah)',
                                        style: AdminColors.sansUI(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              liveOrder.paymentStatus == 'PAID'
                                              ? AdminColors.success
                                              : AdminColors.warning,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        minimumSize: const Size(60, 30),
                                        side: BorderSide(
                                          color:
                                              liveOrder.paymentStatus == 'PAID'
                                              ? AdminColors.success
                                              : AdminColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons
                          Text(
                            'PILIHAN TINDAKAN STATUS',
                            style: AdminColors.sansUI(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.burgundy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildStatusTransitionButtons(ctx, liveOrder, ref),
                          const SizedBox(height: 16),
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

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AdminColors.sansUI(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AdminColors.darkBrown : AdminColors.mutedText,
          ),
        ),
        Text(
          value,
          style: AdminColors.sansUI(
            fontSize: isBold ? 15 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AdminColors.burgundy : AdminColors.darkBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTransitionButtons(
    BuildContext ctx,
    OrderItemModel order,
    WidgetRef ref,
  ) {
    final status = order.status;

    if (status == 'COMPLETED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.statusCompletedBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '✓ Pesanan ini telah SELESAI',
            style: AdminColors.sansUI(
              fontWeight: FontWeight.bold,
              color: AdminColors.statusCompletedText,
            ),
          ),
        ),
      );
    }

    if (status == 'CANCELLED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminColors.statusCancelledBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            '✕ Pesanan ini telah DIBATALKAN (Stok telah dipulihkan)',
            style: AdminColors.sansUI(
              fontWeight: FontWeight.bold,
              color: AdminColors.statusCancelledText,
            ),
          ),
        ),
      );
    }

    String nextStatus = '';
    String nextLabel = '';
    IconData nextIcon = Icons.arrow_forward;

    if (status == 'PENDING') {
      nextStatus = 'CONFIRMED';
      nextLabel = 'Konfirmasi Pesanan';
      nextIcon = Icons.check_circle_outline;
    } else if (status == 'CONFIRMED') {
      nextStatus = 'PREPARING';
      nextLabel = 'Mulai Sedang Disiapkan';
      nextIcon = Icons.outdoor_grill_outlined;
    } else if (status == 'PREPARING') {
      nextStatus = 'READY_FOR_PICKUP';
      nextLabel = 'Tandai Siap Diambil';
      nextIcon = Icons.shopping_bag_outlined;
    } else if (status == 'READY_FOR_PICKUP') {
      nextStatus = 'COMPLETED';
      nextLabel = 'Selesaikan Pesanan';
      nextIcon = Icons.done_all;
    }

    return Column(
      children: [
        if (nextStatus.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(ordersProvider.notifier)
                    .updateOrderStatus(order.id, nextStatus);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AdminColors.success,
                    content: Text('Status pesanan diubah ke $nextLabel'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(nextIcon, color: Colors.white, size: 20),
              label: Text(
                nextLabel,
                style: AdminColors.sansUI(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.burgundy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Cancel order button with confirmation
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _confirmCancelOrder(ctx, order, ref),
            icon: const Icon(
              Icons.cancel_outlined,
              color: AdminColors.error,
              size: 18,
            ),
            label: Text(
              'Batalkan Pesanan',
              style: AdminColors.sansUI(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AdminColors.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AdminColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmCancelOrder(
    BuildContext modalContext,
    OrderItemModel order,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Batalkan Pesanan?',
            style: AdminColors.serifHeading(
              fontSize: 20,
              color: AdminColors.error,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin membatalkan pesanan ${order.orderNumber}? Stok produk yang dipesan akan otomatis dikembalikan ke inventaris.',
            style: AdminColors.sansUI(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(diagCtx),
              child: Text(
                'Kembali',
                style: AdminColors.sansUI(
                  fontWeight: FontWeight.bold,
                  color: AdminColors.darkBrown,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .read(ordersProvider.notifier)
                    .updateOrderStatus(order.id, 'CANCELLED');
                Navigator.pop(diagCtx);
                if (Navigator.canPop(modalContext)) {
                  Navigator.pop(modalContext);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AdminColors.error,
                    content: Text(
                      'Pesanan berhasil dibatalkan dan stok dikembalikan.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Ya, Batalkan',
                style: AdminColors.sansUI(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
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
        label = 'Siap Diambil';
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AdminColors.sansUI(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
