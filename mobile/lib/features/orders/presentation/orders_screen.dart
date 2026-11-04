import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feedback/models/feedback_model.dart';
import '../../feedback/providers/feedback_provider.dart';
import '../models/order_model.dart';
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
    final feedbackMap = ref.watch(orderFeedbacksMapProvider);

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
          onRefresh: () async {
            await Future.wait([
              ref
                  .read(ordersProvider.notifier)
                  .syncOrdersFromCloud(userId: authUser?.id),
              ref.read(feedbackFeedProvider.notifier).fetchFeedbacks(),
            ]);
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(userOrders, feedbackMap),
              _buildOrdersList(
                userOrders
                    .where(
                      (o) => o.status != 'COMPLETED' && o.status != 'CANCELLED',
                    )
                    .toList(),
                feedbackMap,
              ),
              _buildOrdersList(
                userOrders.where((o) => o.status == 'COMPLETED').toList(),
                feedbackMap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(
    List<OrderItemModel> list,
    Map<String, FeedbackModel> feedbackMap,
  ) {
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
        final feedback =
            feedbackMap[order.id] ?? feedbackMap[order.orderNumber];
        final isCompleted = order.status == 'COMPLETED';

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
              const SizedBox(height: 12),

              // Action Buttons Row
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Hanya pesanan COMPLETED yang bisa diberi Feedback
                    if (isCompleted) ...[
                      if (feedback != null)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC77800),
                            side: const BorderSide(
                              color: Color(0xFFF5A623),
                              width: 1.2,
                            ),
                            backgroundColor: const Color(0xFFF5A623)
                                .withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: Color(0xFFF5A623),
                          ),
                          label: Text(
                            'View Feedback (${feedback.rating}★)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () => _showViewFeedbackDialog(
                            context,
                            order,
                            feedback,
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Give Feedback',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final created = await context
                                .push<FeedbackModel?>(
                              '/feedback/give',
                              extra: order,
                            );

                            if (created != null && context.mounted) {
                              ref
                                  .read(feedbackFeedProvider.notifier)
                                  .fetchFeedbacks();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.forestGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Feedback berhasil dikirim! Terima kasih atas ulasan Anda.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            }
                          },
                        ),
                    ],

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

  void _showViewFeedbackDialog(
    BuildContext context,
    OrderItemModel order,
    FeedbackModel feedback,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        final formattedDate = DateFormat(
          'dd MMMM yyyy, HH:mm',
        ).format(feedback.createdAt.toLocal());

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.surface(dialogCtx),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Feedback',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text(dialogCtx),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5A623).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: Color(0xFFF5A623),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${feedback.rating}/5',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC77800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesanan: ${order.orderNumber}',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    color: AppColors.subtext(dialogCtx),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),

                // Star row
                Row(
                  children: List.generate(5, (index) {
                    final starNum = index + 1;
                    final isFilled = starNum <= feedback.rating;
                    return Icon(
                      isFilled
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 26,
                      color: isFilled
                          ? const Color(0xFFF5A623)
                          : AppColors.border(dialogCtx),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Comment box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cream.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(dialogCtx)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komentar / Catatan Pengalaman:',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.subtext(dialogCtx),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feedback.comment != null &&
                                feedback.comment!.trim().isNotEmpty
                            ? feedback.comment!.trim()
                            : 'Tidak ada ulasan teks yang disertakan.',
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontStyle: feedback.comment == null ||
                                  feedback.comment!.trim().isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: AppColors.text(dialogCtx),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Date
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Dikirim pada $formattedDate',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.espresso,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(
                      'TUTUP',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
