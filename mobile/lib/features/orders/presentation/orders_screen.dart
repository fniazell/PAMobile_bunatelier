import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ordersState = ref.watch(ordersProvider);
    final authUser = ref.watch(authProvider).user;

    // Filter order untuk customer aktif (atau tampilkan seluruh pesanan lokal jika order lokal belum memiliki userId)
    final userOrders = ordersState.orders.where((o) {
      if (authUser == null || authUser.isAdmin) return true;
      return o.userId == authUser.id ||
          o.userId == null ||
          o.customerName == authUser.fullName;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'ORDER HISTORY',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/main'),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.coral,
          unselectedLabelColor: AppColors.mutedText,
          indicatorColor: AppColors.coral,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.coral,
          onRefresh: () => ref
              .read(ordersProvider.notifier)
              .syncOrdersFromCloud(userId: authUser?.id),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(userOrders),
              _buildOrdersList(
                userOrders
                    .where(
                      (o) => o.status != 'COMPLETED' && o.status != 'CANCELLED',
                    )
                    .toList(),
              ),
              _buildOrdersList(
                userOrders.where((o) => o.status == 'COMPLETED').toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: AppColors.mutedText,
            ),
            const SizedBox(height: 12),
            const Text(
              'No orders in this category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Your future burger cravings will appear here.',
              style: TextStyle(color: AppColors.mutedText),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = list[index];

        Color badgeColor;
        switch (order.status) {
          case 'CONFIRMED':
            badgeColor = Colors.blue.shade700;
            break;
          case 'PREPARING':
            badgeColor = Colors.orange.shade800;
            break;
          case 'READY_FOR_PICKUP':
            badgeColor = AppColors.coral;
            break;
          case 'COMPLETED':
            badgeColor = AppColors.forestGreen;
            break;
          default:
            badgeColor = AppColors.mutedText;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.espresso.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              if (order.branchName != null && order.branchName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 13,
                            color: AppColors.forestGreen,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.branchName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.forestGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        order.formattedTransactionTime(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  order.formattedTransactionTime(),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Items
              Text(
                order.itemsSummary,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.orderType} • ${order.paymentMethod} • ${order.formattedTotal}',
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),

              const Divider(),
              _buildCustomerStatusInfo(order.status),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: order.isConfirmed
                          ? AppColors.forestGreen
                          : AppColors.mutedText,
                      side: BorderSide(
                        color: order.isConfirmed
                            ? AppColors.forestGreen
                            : AppColors.borderLight,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      order.isConfirmed
                          ? Icons.receipt_long_rounded
                          : Icons.lock_outline_rounded,
                      size: 15,
                    ),
                    label: Text(
                      order.isConfirmed
                          ? 'Lihat & Unduh E-Receipt'
                          : 'E-Receipt (Menunggu Konfirmasi)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () =>
                        context.push('/order-confirmed', extra: order),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerStatusInfo(String status) {
    IconData icon;
    Color color;
    String statusTitle;
    String statusDesc;

    switch (status) {
      case 'PENDING':
      case 'CONFIRMED':
        icon = Icons.access_time_filled_rounded;
        color = Colors.blue.shade700;
        statusTitle = 'Pesanan Dikonfirmasi';
        statusDesc = 'Pesanan telah diterima & menunggu antrean dapur';
        break;
      case 'PREPARING':
        icon = Icons.soup_kitchen_rounded;
        color = Colors.orange.shade800;
        statusTitle = 'Sedang Disiapkan';
        statusDesc = 'Chef Bun Atelier sedang meracik burger pesanan Anda';
        break;
      case 'READY_FOR_PICKUP':
        icon = Icons.takeout_dining_rounded;
        color = AppColors.coral;
        statusTitle = 'Siap Diambil';
        statusDesc = 'Pesanan sudah siap! Silakan ambil di pick-up counter';
        break;
      case 'COMPLETED':
        icon = Icons.check_circle_rounded;
        color = AppColors.forestGreen;
        statusTitle = 'Pesanan Selesai';
        statusDesc = 'Terima kasih telah menikmati sajian Bun Atelier';
        break;
      case 'CANCELLED':
        icon = Icons.cancel_rounded;
        color = Colors.red.shade700;
        statusTitle = 'Pesanan Dibatalkan';
        statusDesc = 'Pesanan telah dibatalkan oleh pihak restoran';
        break;
      default:
        icon = Icons.info_rounded;
        color = AppColors.mutedText;
        statusTitle = status;
        statusDesc = 'Status dikelola oleh admin restoran';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  statusDesc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
