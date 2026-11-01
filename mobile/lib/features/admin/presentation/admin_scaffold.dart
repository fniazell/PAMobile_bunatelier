import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/admin_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../orders/models/order_model.dart';
import '../dashboard/presentation/admin_dashboard_tab.dart';
import '../orders/presentation/admin_orders_tab.dart';
import '../menu/presentation/admin_menu_tab.dart';
import '../inventory/presentation/admin_inventory_tab.dart';
import '../analytics/presentation/admin_analytics_tab.dart';
import '../promotions/presentation/admin_promotions_tab.dart';
import '../customers/presentation/admin_customers_tab.dart';
import '../reports/presentation/admin_reports_tab.dart';
import '../settings/presentation/admin_settings_tab.dart';
import '../blockchain/presentation/admin_blockchain_verification_tab.dart';
import '../widgets/bun_atelier_logo.dart';

class AdminLayoutScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const AdminLayoutScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AdminLayoutScreen> createState() => _AdminLayoutScreenState();
}

class _AdminLayoutScreenState extends ConsumerState<AdminLayoutScreen> {
  late int _currentIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  OrderItemModel? _selectedOrderForDetail;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      _selectedOrderForDetail = null;
    });
  }

  void _viewOrderDetail(OrderItemModel order) {
    setState(() {
      _selectedOrderForDetail = order;
      _currentIndex = 1; // Orders Tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    // Active orders badge counter
    final activeOrdersCount = ordersState.orders.where((o) =>
      o.status == 'CONFIRMED' ||
      o.status == 'PREPARING' ||
      o.status == 'READY_FOR_PICKUP' ||
      o.status == 'PENDING'
    ).length;

    final isWide = MediaQuery.of(context).size.width >= 800;

    final pages = [
      AdminDashboardTab(
        onNavigateToTab: _navigateToTab,
        onViewOrderDetail: _viewOrderDetail,
      ),
      AdminOrdersTab(
        key: ValueKey(_selectedOrderForDetail?.id ?? 'orders-tab'),
        initialSelectedOrder: _selectedOrderForDetail,
      ),
      const AdminMenuTab(),
      const AdminInventoryTab(),
      const AdminAnalyticsTab(),
      const AdminPromotionsTab(),
      const AdminCustomersTab(),
      const AdminReportsTab(),
      const AdminSettingsTab(),
      const AdminBlockchainVerificationTab(),
    ];

    if (isWide) {
      // ── Wide Tablet / Desktop Layout with Persistent Sidebar ───────────────
      return Scaffold(
        backgroundColor: AdminColors.warmWhite,
        body: Row(
          children: [
            // Sidebar
            SizedBox(
              width: 250,
              child: _buildSidebar(context, activeOrdersCount),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: AdminColors.border),
            // Main content
            Expanded(
              child: Scaffold(
                backgroundColor: AdminColors.warmWhite,
                appBar: _buildAppBar(context, activeOrdersCount, isWide: true),
                body: pages[_currentIndex],
              ),
            ),
          ],
        ),
      );
    }

    // ── Phone Layout with Drawer and Bottom Nav ─────────────────────────────
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminColors.warmWhite,
      appBar: _buildAppBar(context, activeOrdersCount, isWide: false),
      drawer: _buildDrawer(context, activeOrdersCount),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(activeOrdersCount),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, int activeOrdersCount, {required bool isWide}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;

    return AppBar(
      backgroundColor: AdminColors.surface,
      elevation: 0,
      centerTitle: false,
      leading: isWide
          ? null
          : IconButton(
              icon: const Icon(Icons.menu_rounded, color: AdminColors.burgundy, size: 26),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      title: SizedBox(
        height: 34,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: BunAtelierLogo(variant: LogoVariant.horizontal, size: isCompact ? 28 : 34),
          ),
        ),
      ),
      actions: [
        // Active orders quick pill
        GestureDetector(
          onTap: () => _navigateToTab(1),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: 4),
            decoration: BoxDecoration(
              color: activeOrdersCount > 0 ? AdminColors.burgundy : AdminColors.warmWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 14,
                  color: activeOrdersCount > 0 ? Colors.white : AdminColors.mutedText,
                ),
                const SizedBox(width: 4),
                Text(
                  isCompact ? '$activeOrdersCount' : '$activeOrdersCount Aktif',
                  style: AdminColors.sansUI(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeOrdersCount > 0 ? Colors.white : AdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),
      ],
    );
  }

  Widget _buildBottomNav(int activeOrdersCount) {
    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.border, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                label: 'Dashboard',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'Orders',
                badgeCount: activeOrdersCount > 0 ? activeOrdersCount : null,
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: 'Menu',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: 'Stok',
              ),
              // More Drawer item
              Expanded(
                child: InkWell(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.more_horiz_rounded, size: 22, color: AdminColors.mutedText),
                      const SizedBox(height: 2),
                      Text(
                        'Lainnya',
                        style: AdminColors.sansUI(fontSize: 10, color: AdminColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _navigateToTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AdminColors.burgundy : AdminColors.mutedText,
                ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AdminColors.burgundy,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AdminColors.sansUI(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AdminColors.burgundy : AdminColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, int activeOrdersCount) {
    return Drawer(
      backgroundColor: AdminColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.warmWhite,
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: const BunAtelierLogo(variant: LogoVariant.sidebar, size: 38),
            ),

            // 10 Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    title: '1. Dashboard',
                    icon: Icons.dashboard_outlined,
                  ),
                  _buildDrawerItem(
                    index: 1,
                    title: '2. Orders (Pesanan)',
                    icon: Icons.receipt_long_outlined,
                    badgeCount: activeOrdersCount > 0 ? activeOrdersCount : null,
                  ),
                  _buildDrawerItem(
                    index: 2,
                    title: '3. Menu Management',
                    icon: Icons.restaurant_menu_outlined,
                  ),
                  _buildDrawerItem(
                    index: 3,
                    title: '4. Inventory (Stok)',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildDrawerItem(
                    index: 4,
                    title: '5. Sales Analytics',
                    icon: Icons.insights_outlined,
                  ),
                  _buildDrawerItem(
                    index: 5,
                    title: '6. Promotions (Voucher)',
                    icon: Icons.local_offer_outlined,
                  ),
                  _buildDrawerItem(
                    index: 6,
                    title: '7. Customers (Pelanggan)',
                    icon: Icons.people_outline,
                  ),
                  _buildDrawerItem(
                    index: 7,
                    title: '8. Reports (Laporan)',
                    icon: Icons.description_outlined,
                  ),
                  _buildDrawerItem(
                    index: 8,
                    title: '9. Settings (Pengaturan)',
                    icon: Icons.settings_outlined,
                  ),
                  _buildDrawerItem(
                    index: 9,
                    title: '10. Blockchain Verification',
                    icon: Icons.verified_user_outlined,
                  ),
                  const Divider(color: AdminColors.divider, height: 16),
                  // 11. Logout
                  ListTile(
                    leading: const Icon(Icons.logout, color: AdminColors.burgundy),
                    title: Text(
                      '11. Logout (Keluar)',
                      style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.burgundy),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmLogout(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required String title,
    required IconData icon,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AdminColors.sandBeige : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? AdminColors.burgundy : AdminColors.darkBrown, size: 20),
        title: Text(
          title,
          style: AdminColors.sansUI(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AdminColors.burgundy : AdminColors.darkBrown,
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminColors.burgundy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(context);
          _navigateToTab(index);
        },
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, int activeOrdersCount) {
    return Container(
      color: AdminColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: BunAtelierLogo(variant: LogoVariant.sidebar, size: 36),
            ),
            const Divider(color: AdminColors.divider, height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildSidebarItem(0, 'Dashboard', Icons.dashboard_outlined),
                  _buildSidebarItem(1, 'Orders', Icons.receipt_long_outlined, badgeCount: activeOrdersCount > 0 ? activeOrdersCount : null),
                  _buildSidebarItem(2, 'Menu Management', Icons.restaurant_menu_outlined),
                  _buildSidebarItem(3, 'Inventory', Icons.inventory_2_outlined),
                  _buildSidebarItem(4, 'Sales Analytics', Icons.insights_outlined),
                  _buildSidebarItem(5, 'Promotions', Icons.local_offer_outlined),
                  _buildSidebarItem(6, 'Customers', Icons.people_outline),
                  _buildSidebarItem(7, 'Reports', Icons.description_outlined),
                  _buildSidebarItem(8, 'Settings', Icons.settings_outlined),
                  _buildSidebarItem(9, 'Blockchain Verification', Icons.verified_user_outlined),
                  const Divider(color: AdminColors.divider, height: 16),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout, color: AdminColors.burgundy, size: 20),
                    title: Text('Logout', style: AdminColors.sansUI(fontSize: 13, fontWeight: FontWeight.bold, color: AdminColors.burgundy)),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon, {int? badgeCount}) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AdminColors.sandBeige : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? AdminColors.burgundy : AdminColors.darkBrown, size: 20),
        title: Text(
          title,
          style: AdminColors.sansUI(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AdminColors.burgundy : AdminColors.darkBrown,
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AdminColors.burgundy, borderRadius: BorderRadius.circular(10)),
                child: Text('$badgeCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              )
            : null,
        onTap: () => _navigateToTab(index),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (diagCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Keluar dari Admin?', style: AdminColors.serifHeading(fontSize: 18, color: AdminColors.burgundy)),
          content: Text(
            'Sesi admin akan diakhiri dan dialihkan kembali ke login.',
            style: AdminColors.sansUI(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(diagCtx),
              child: Text('Batal', style: AdminColors.sansUI(color: AdminColors.mutedText)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(diagCtx);
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AdminColors.burgundy),
              child: Text('Ya, Logout', style: AdminColors.sansUI(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
