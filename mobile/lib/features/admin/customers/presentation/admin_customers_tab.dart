import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/admin_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/auth_service.dart';
import '../../../orders/providers/orders_provider.dart';
import '../../../orders/models/order_model.dart';

class AdminCustomersTab extends ConsumerStatefulWidget {
  const AdminCustomersTab({super.key});

  @override
  ConsumerState<AdminCustomersTab> createState() => _AdminCustomersTabState();
}

class _AdminCustomersTabState extends ConsumerState<AdminCustomersTab> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  List<AccountRecord> _customers = [];
  bool _isLoading = true;
  String? _selectedCustomerId;
  String _tierFilter = 'ALL'; // 'ALL', 'VIP', 'ACTIVE', 'INACTIVE'

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final authService = ref.read(authProvider.notifier).authService;
    final list = await authService.getAllCustomers();
    if (mounted) {
      setState(() {
        _customers = list;
        _isLoading = false;
        if (list.isNotEmpty && _selectedCustomerId == null) {
          _selectedCustomerId = list.first.id;
        }
      });
    }
  }

  String _formatCurrency(int amount) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return fmt.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);
    final allOrders = ordersState.orders;

    // Filter customers
    final filtered = _customers.where((c) {
      // Find orders
      final cOrders = allOrders.where((o) =>
        o.customerName.toLowerCase() == c.fullName.toLowerCase() ||
        (c.phone.isNotEmpty && o.customerPhone == c.phone)
      ).toList();

      final totalSpent = cOrders
          .where((o) => o.status != 'CANCELLED')
          .fold(0, (sum, o) => sum + o.total);

      if (_tierFilter == 'VIP' && totalSpent < 500000) return false;
      if (_tierFilter == 'ACTIVE' && cOrders.isEmpty) return false;
      if (_tierFilter == 'INACTIVE' && cOrders.isNotEmpty) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.fullName.toLowerCase().contains(q) ||
               c.email.toLowerCase().contains(q) ||
               c.username.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Summary calculations
    final totalRegistered = _customers.length;
    int activeBuyersCount = 0;
    int totalCustomerSpend = 0;

    for (final c in _customers) {
      final cOrders = allOrders.where((o) =>
        o.customerName.toLowerCase() == c.fullName.toLowerCase() ||
        (c.phone.isNotEmpty && o.customerPhone == c.phone)
      ).toList();
      if (cOrders.isNotEmpty) {
        activeBuyersCount++;
        totalCustomerSpend += cOrders.where((o) => o.status != 'CANCELLED').fold(0, (s, o) => s + o.total);
      }
    }

    final avgSpend = activeBuyersCount > 0 ? (totalCustomerSpend / activeBuyersCount).round() : 0;
    final isWide = MediaQuery.of(context).size.width >= 900;

    AccountRecord? selectedCustomer;
    if (_selectedCustomerId != null) {
      final match = _customers.where((c) => c.id == _selectedCustomerId);
      if (match.isNotEmpty) selectedCustomer = match.first;
    }
    if (selectedCustomer == null && filtered.isNotEmpty) {
      selectedCustomer = filtered.first;
      _selectedCustomerId = selectedCustomer.id;
    }

    return Container(
      color: AdminColors.warmWhite,
      child: Column(
        children: [
          // ── Header & KPI Cards ─────────────────────────────────────────────
          Container(
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
                            'GUEST RELATIONSHIP & DIRECTORY',
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
                            'Direktori Tamu & Pelanggan',
                            style: AdminColors.serifHeading(fontSize: 22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AdminColors.burgundy),
                      tooltip: 'Muat Ulang Data Pelanggan',
                      onPressed: _loadCustomers,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3 CRM Summary Cards (Adaptive layout)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 520;
                    if (isSmall) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCrmPill('Total Terdaftar', '$totalRegistered Tamu', Icons.people_outline, AdminColors.burgundy, Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCrmPill('Pelanggan Aktif', '$activeBuyersCount Pembeli', Icons.shopping_bag_outlined, AdminColors.success, const Color(0xFFDCFCE7)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildCrmPill('Rata-rata LTV', _formatCurrency(avgSpend), Icons.account_balance_wallet_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildCrmPill('Total Terdaftar', '$totalRegistered Tamu', Icons.people_outline, AdminColors.burgundy, Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCrmPill('Pelanggan Aktif', '$activeBuyersCount Pembeli', Icons.shopping_bag_outlined, AdminColors.success, const Color(0xFFDCFCE7)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildCrmPill('Rata-rata LTV', _formatCurrency(avgSpend), Icons.account_balance_wallet_outlined, const Color(0xFFD97706), const Color(0xFFFEF3C7)),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Search Bar & Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'Cari nama tamu, username, email...',
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.border)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTierChip('Semua (${_customers.length})', 'ALL'),
                      const SizedBox(width: 8),
                      _buildTierChip('VIP Gourmet (> 500k)', 'VIP'),
                      const SizedBox(width: 8),
                      _buildTierChip('Aktif Berbelanja', 'ACTIVE'),
                      const SizedBox(width: 8),
                      _buildTierChip('Belum Bertransaksi', 'INACTIVE'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main Content Area (Responsive Master-Detail or List) ─────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminColors.burgundy))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline, size: 48, color: AdminColors.mutedText),
                            const SizedBox(height: 12),
                            Text('Belum ada tamu ditemukan', style: AdminColors.serifHeading(fontSize: 18)),
                            const SizedBox(height: 4),
                            Text('Pelanggan yang mendaftar akun atau memesan akan muncul di sini', style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText)),
                          ],
                        ),
                      )
                    : (isWide
                        // ── Wide Screen Master-Detail ───────────────────────────
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 380,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 24),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final customer = filtered[index];
                                    final customerOrders = allOrders.where((o) =>
                                      o.customerName.toLowerCase() == customer.fullName.toLowerCase() ||
                                      (customer.phone.isNotEmpty && o.customerPhone == customer.phone)
                                    ).toList();
                                    final totalSpent = customerOrders
                                        .where((o) => o.status != 'CANCELLED')
                                        .fold(0, (sum, o) => sum + o.total);

                                    return _buildCustomerTile(
                                      customer: customer,
                                      customerOrders: customerOrders,
                                      totalSpent: totalSpent,
                                      isSelected: customer.id == selectedCustomer?.id,
                                      onTap: () => setState(() => _selectedCustomerId = customer.id),
                                    );
                                  },
                                ),
                              ),
                              const VerticalDivider(width: 1, thickness: 1, color: AdminColors.border),
                              Expanded(
                                child: selectedCustomer != null
                                    ? SingleChildScrollView(
                                        padding: const EdgeInsets.all(24),
                                        child: _buildCustomerDossier(selectedCustomer, allOrders),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          )
                        // ── Mobile Screen List with Bottom Sheet ───────────────
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final customer = filtered[index];
                              final customerOrders = allOrders.where((o) =>
                                o.customerName.toLowerCase() == customer.fullName.toLowerCase() ||
                                (customer.phone.isNotEmpty && o.customerPhone == customer.phone)
                              ).toList();
                              final totalSpent = customerOrders
                                  .where((o) => o.status != 'CANCELLED')
                                  .fold(0, (sum, o) => sum + o.total);

                              return _buildCustomerTile(
                                customer: customer,
                                customerOrders: customerOrders,
                                totalSpent: totalSpent,
                                isSelected: false,
                                onTap: () => _showCustomerDetailModal(customer, customerOrders, totalSpent),
                              );
                            },
                          )),
          ),
        ],
      ),
    );
  }

  Widget _buildCrmPill(String title, String val, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.mutedText)),
                Text(val, style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.w800, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip(String label, String key) {
    final isSelected = _tierFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AdminColors.burgundy,
      backgroundColor: AdminColors.sandBeige,
      labelStyle: AdminColors.sansUI(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AdminColors.darkBrown,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _tierFilter = key),
    );
  }

  // ── Customer Card / Tile ──────────────────────────────────────────────────
  Widget _buildCustomerTile({
    required AccountRecord customer,
    required List<OrderItemModel> customerOrders,
    required int totalSpent,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isVip = totalSpent >= 500000;

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
            ? [BoxShadow(color: AdminColors.burgundy.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 3))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminColors.burgundy,
                  child: Text(
                    customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : 'G',
                    style: AdminColors.serifHeading(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              customer.fullName,
                              style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVip)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                              child: Text('VIP', style: AdminColors.sansUI(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                            ),
                        ],
                      ),
                      Text(
                        '@${customer.username} • ${customer.email}',
                        style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${customerOrders.length} Pesanan',
                            style: AdminColors.sansUI(fontSize: 10, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                          ),
                          Text(
                            _formatCurrency(totalSpent),
                            style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.w800, color: AdminColors.darkBrown),
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
      ),
    );
  }

  // ── Wide Screen Customer Dossier ──────────────────────────────────────────
  Widget _buildCustomerDossier(AccountRecord customer, List<OrderItemModel> allOrders) {
    final customerOrders = allOrders.where((o) =>
      o.customerName.toLowerCase() == customer.fullName.toLowerCase() ||
      (customer.phone.isNotEmpty && o.customerPhone == customer.phone)
    ).toList();

    final validOrders = customerOrders.where((o) => o.status != 'CANCELLED').toList();
    final totalSpent = validOrders.fold(0, (sum, o) => sum + o.total);
    final aov = validOrders.isNotEmpty ? (totalSpent / validOrders.length).round() : 0;

    // Discover favorite item
    final Map<String, int> dishCounts = {};
    for (final o in validOrders) {
      for (final item in o.itemsSummary.split(',')) {
        final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(item.trim());
        if (match != null) {
          final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
          final name = match.group(2)?.trim() ?? '';
          dishCounts[name] = (dishCounts[name] ?? 0) + qty;
        }
      }
    }
    String? favoriteDish;
    if (dishCounts.isNotEmpty) {
      final sorted = dishCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      favoriteDish = '${sorted.first.key} (${sorted.first.value}x dipesan)';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.border),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AdminColors.burgundy,
                child: Text(
                  customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : 'G',
                  style: AdminColors.serifHeading(fontSize: 26, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(customer.fullName, style: AdminColors.serifHeading(fontSize: 22)),
                        const SizedBox(width: 8),
                        if (totalSpent >= 500000)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                            child: Text('VIP GOURMET', style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                          ),
                      ],
                    ),
                    Text('@${customer.username} • Role: ${customer.role.toUpperCase()}', style: AdminColors.sansUI(fontSize: 12, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                    Text(customer.email, style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText)),
                    if (customer.phone.isNotEmpty)
                      Text(customer.phone, style: AdminColors.sansUI(fontSize: 12, color: AdminColors.mutedText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Metrics Ribbon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AdminColors.warmWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDossierStat('LIFETIME VALUE (LTV)', _formatCurrency(totalSpent), AdminColors.burgundy),
                Container(width: 1, height: 35, color: AdminColors.divider),
                _buildDossierStat('TOTAL TRANSAKSI', '${customerOrders.length} Pesanan', AdminColors.darkBrown),
                Container(width: 1, height: 35, color: AdminColors.divider),
                _buildDossierStat('AVG KERANJANG', _formatCurrency(aov), const Color(0xFFD97706)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (favoriteDish != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AdminColors.sandBeige.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite, size: 16, color: AdminColors.burgundy),
                  const SizedBox(width: 8),
                  Text('Menu Favorit Tamu: ', style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.bold, color: AdminColors.darkBrown)),
                  Text(favoriteDish, style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.burgundy)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Purchase History Table
          Text(
            'RIWAYAT TRANSAKSI LENGKAP',
            style: AdminColors.sansUI(fontSize: 11, fontWeight: FontWeight.w800, color: AdminColors.burgundy, letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          if (customerOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Pelanggan ini belum melakukan pemesanan transaksi', style: AdminColors.sansUI(color: AdminColors.mutedText)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: customerOrders.length,
              separatorBuilder: (_, _) => const Divider(color: AdminColors.divider, height: 16),
              itemBuilder: (context, idx) {
                final ord = customerOrders[idx];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminColors.sandBeige.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_long, size: 18, color: AdminColors.burgundy),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(ord.orderNumber, style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ord.status == 'COMPLETED' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  ord.status,
                                  style: AdminColors.sansUI(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: ord.status == 'COMPLETED' ? AdminColors.success : AdminColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(ord.itemsSummary, style: AdminColors.sansUI(fontSize: 11, color: AdminColors.mutedText), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(DateFormat('dd MMMM yyyy, HH:mm').format(ord.createdAt), style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText)),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(ord.total),
                      style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.burgundy),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDossierStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AdminColors.sansUI(fontSize: 9, fontWeight: FontWeight.bold, color: AdminColors.mutedText)),
        const SizedBox(height: 3),
        Text(value, style: AdminColors.serifHeading(fontSize: 16, color: color)),
      ],
    );
  }

  // ── Mobile Customer Detail Modal ──────────────────────────────────────────
  void _showCustomerDetailModal(AccountRecord customer, List<OrderItemModel> customerOrders, int totalSpent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AdminColors.divider))),
                child: Column(
                  children: [
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dossier Tamu', style: AdminColors.serifHeading(fontSize: 20)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildCustomerDossier(customer, ref.watch(ordersProvider).orders),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
