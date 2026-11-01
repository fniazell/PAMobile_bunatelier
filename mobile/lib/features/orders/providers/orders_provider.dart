import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/supabase_service.dart';
import '../../cart/models/cart_item_model.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../blockchain/services/blockchain_receipt_service.dart';
import '../models/order_model.dart';

class OrdersState {
  final List<OrderItemModel> orders;
  final bool isLoading;

  const OrdersState({this.orders = const [], this.isLoading = false});

  OrdersState copyWith({List<OrderItemModel>? orders, bool? isLoading}) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OrdersNotifier extends StateNotifier<OrdersState> {
  static final Random _secureRandom = Random.secure();

  final Ref? _ref;
  final Future<bool> Function(OrderItemModel) _syncOrderToCloud;

  OrdersNotifier([
    this._ref,
    Future<bool> Function(OrderItemModel)? syncOrderToCloud,
  ]) : _syncOrderToCloud =
           syncOrderToCloud ?? SupabaseService.instance.syncOrderToCloud,
       super(const OrdersState()) {
    _loadInitialOrders();
  }

  Future<void> _loadInitialOrders() async {
    // 1. Muat dari database offline sqflite
    try {
      final rows = await AppDatabase.instance.getCachedOrders();
      if (rows.isNotEmpty) {
        final loaded = rows.map((r) {
          return OrderItemModel(
            id: r['id']?.toString() ?? '',
            userId: r['user_id']?.toString(),
            orderNumber: r['order_number']?.toString() ?? '',
            createdAt:
                DateTime.tryParse(r['created_at']?.toString() ?? '') ??
                DateTime.now(),
            orderType: r['order_type']?.toString() ?? 'PICKUP',
            paymentMethod: r['payment_method']?.toString() ?? 'QRIS',
            paymentStatus: r['payment_status']?.toString() ?? 'PAID',
            status: r['status']?.toString() ?? 'CONFIRMED',
            subtotal: (r['subtotal'] as int?) ?? 0,
            tax: (r['tax'] as int?) ?? 0,
            deliveryFee: (r['delivery_fee'] as int?) ?? 0,
            total: (r['total'] as int?) ?? 0,
            itemsSummary: r['items_summary']?.toString() ?? '',
            deliveryAddress: r['delivery_address']?.toString(),
            notes: r['notes']?.toString(),
            customerName:
                r['customer_name']?.toString() ?? 'Pelanggan Bun Atelier',
            customerPhone: r['customer_phone']?.toString(),
            branchId: r['branch_id']?.toString() ?? 'out-1',
            branchName:
                r['branch_name']?.toString() ??
                'Bun Atelier — Senopati Flagship',
            branchTimezone: r['branch_timezone']?.toString() ?? 'Asia/Jakarta',
            branchCurrency: r['branch_currency']?.toString() ?? 'IDR',
            voucherCode: r['voucher_code']?.toString(),
            voucherDiscountAmount: r['voucher_discount_amount'] as int?,
            voucherBlockchainTxHash: r['voucher_tx_hash']?.toString(),
            voucherReferenceId: r['voucher_reference_id']?.toString(),
            voucherRedemptionTxHash:
                r['voucher_redemption_tx_hash']?.toString() ??
                r['voucher_tx_hash']?.toString(),
            voucherUsageTxHash: r['voucher_usage_tx_hash']?.toString(),
            voucherIsSimulated: (r['voucher_is_simulated'] as int?) != 0,
            receiptHash: r['receipt_hash']?.toString(),
            receiptPreviousHash: r['receipt_previous_hash']?.toString(),
            receiptBlockchainTxHash: r['receipt_tx_hash']?.toString(),
            receiptExplorerUrl: r['receipt_explorer_url']?.toString(),
            receiptIsSimulated: (r['receipt_is_simulated'] as int?) != 0,
          );
        }).toList();

        state = state.copyWith(orders: loaded);
      }
    } catch (_) {}
  }

  String _generateUuid() {
    final bytes = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  Future<OrderItemModel> createOrder({
    String? userId,
    required List<CartItem> cartItems,
    required String orderType,
    required String paymentMethod,
    String? deliveryAddress,
    String? notes,
    String? customerName,
    String? customerPhone,
    String? branchId,
    String? branchName,
    String? branchTimezone,
    String? branchCurrency,
    String? voucherCode,
    int? voucherDiscountPercent,
    int? voucherDiscountAmount,
    String? voucherBlockchainTxHash,
    String? voucherReferenceId,
    String? voucherRedemptionTxHash,
    String? voucherUsageTxHash,
    bool voucherIsSimulated = true,
  }) async {
    final subtotal = cartItems.fold(0, (sum, i) => sum + i.totalPrice);
    final discount = voucherDiscountAmount ?? 0;
    final taxableSubtotal = (subtotal - discount).clamp(0, subtotal);
    final tax = (taxableSubtotal * 0.1).round();
    final deliveryFee = orderType == 'DELIVERY' ? 12000 : 0;
    final total = (subtotal - discount + tax + deliveryFee).clamp(0, 999999999);

    final summary = cartItems
        .map((i) => '${i.quantity}x ${i.product.name}')
        .join(', ');
    final createdAt = DateTime.now();
    final orderUuid = _generateUuid();
    final datePart =
        '${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';

    final effectiveRedemptionTx =
        voucherRedemptionTxHash ?? voucherBlockchainTxHash;
    final effectiveBlockchainTx = voucherUsageTxHash ?? effectiveRedemptionTx;

    final newOrder = OrderItemModel(
      id: 'ord-$orderUuid',
      userId: userId,
      orderNumber: 'BA-$datePart-${orderUuid.substring(0, 8).toUpperCase()}',
      createdAt: createdAt,
      orderType: orderType,
      paymentMethod: paymentMethod,
      paymentStatus: paymentMethod == 'CASHIER' ? 'PENDING' : 'PAID',
      status: 'CONFIRMED',
      subtotal: subtotal,
      tax: tax,
      deliveryFee: deliveryFee,
      total: total,
      deliveryAddress: deliveryAddress,
      notes: notes,
      itemsSummary: summary,
      customerName: customerName ?? 'Pelanggan Bun Atelier',
      customerPhone: customerPhone,
      branchId: branchId,
      branchName: branchName,
      branchTimezone: branchTimezone,
      branchCurrency: branchCurrency,
      voucherCode: voucherCode,
      voucherDiscountPercent: voucherDiscountPercent,
      voucherDiscountAmount: voucherDiscountAmount,
      voucherBlockchainTxHash: effectiveBlockchainTx,
      voucherReferenceId: voucherReferenceId,
      voucherRedemptionTxHash: effectiveRedemptionTx,
      voucherUsageTxHash: voucherUsageTxHash,
      voucherIsSimulated: voucherIsSimulated,
    );

    // Coba simpan ke cloud Supabase secara graceful (jika offline, tetap simpan lokal)
    bool savedToCloud = false;
    try {
      savedToCloud = await _syncOrderToCloud(newOrder);
      if (savedToCloud) {
        unawaited(SupabaseService.instance.syncOrderItemsToCloud(newOrder.id, cartItems));
      }
    } catch (e) {
      debugPrint('Sync order to cloud failed or offline: $e');
      savedToCloud = false;
    }

    // 0. Kurangi stok produk secara atomik di catalogProductsProvider
    _ref?.read(catalogProductsProvider.notifier).deductStockForOrder(cartItems);

    state = state.copyWith(orders: [newOrder, ...state.orders]);

    // 1. Simpan ke database lokal SQFLITE (Offline Persistence)
    AppDatabase.instance.insertCachedOrder({
      'id': newOrder.id,
      'user_id': newOrder.userId,
      'order_number': newOrder.orderNumber,
      'created_at': newOrder.createdAt.toIso8601String(),
      'order_type': newOrder.orderType,
      'payment_method': newOrder.paymentMethod,
      'payment_status': newOrder.paymentStatus,
      'status': newOrder.status,
      'subtotal': newOrder.subtotal,
      'tax': newOrder.tax,
      'delivery_fee': newOrder.deliveryFee,
      'total': newOrder.total,
      'items_summary': newOrder.itemsSummary,
      'customer_name': newOrder.customerName,
      'customer_phone': newOrder.customerPhone,
      'delivery_address': newOrder.deliveryAddress,
      'notes': newOrder.notes,
      'branch_id': newOrder.branchId,
      'branch_name': newOrder.branchName,
      'branch_timezone': newOrder.branchTimezone,
      'branch_currency': newOrder.branchCurrency,
      'voucher_code': newOrder.voucherCode,
      'voucher_discount_amount': newOrder.voucherDiscountAmount,
      'voucher_tx_hash': newOrder.voucherBlockchainTxHash,
      'voucher_reference_id': newOrder.voucherReferenceId,
      'voucher_redemption_tx_hash': newOrder.voucherRedemptionTxHash,
      'voucher_usage_tx_hash': newOrder.voucherUsageTxHash,
      'voucher_is_simulated': newOrder.voucherIsSimulated ? 1 : 0,
      'is_synced': savedToCloud ? 1 : 0,
    });

    // 3. Pemicu Notifikasi Pesanan Dikonfirmasi (Push Notification & In-App Center)
    _ref
        ?.read(notificationProvider.notifier)
        .triggerOrderConfirmedNotification(
          orderNumber: newOrder.orderNumber,
          itemsSummary: newOrder.itemsSummary,
          total: newOrder.total,
        );

    // 4. Pencatatan Asynchronous E-Receipt ke Blockchain Ledger
    unawaited(_recordOrderOnBlockchain(newOrder, cartItems));

    return newOrder;
  }

  Future<void> _recordOrderOnBlockchain(
    OrderItemModel order,
    List<CartItem> cartItems,
  ) async {
    try {
      final receiptResult = await BlockchainReceiptService.instance
          .recordOrderReceipt(order: order, cartItems: cartItems);

      final updated = order.copyWith(
        receiptHash: receiptResult.receiptHash,
        receiptPreviousHash: receiptResult.previousReceiptHash,
        receiptBlockchainTxHash: receiptResult.txHash,
        receiptExplorerUrl: receiptResult.explorerUrl,
        receiptIsSimulated: receiptResult.isSimulated,
      );

      final updatedList = state.orders
          .map((o) => o.id == order.id ? updated : o)
          .toList();
      state = state.copyWith(orders: updatedList);

      await AppDatabase.instance.updateOrderReceiptBlockchain(
        orderId: order.id,
        receiptHash: receiptResult.receiptHash,
        receiptPreviousHash: receiptResult.previousReceiptHash,
        txHash: receiptResult.txHash,
        explorerUrl: receiptResult.explorerUrl,
        isSimulated: receiptResult.isSimulated ? 1 : 0,
      );

      // Sinkronkan hash blockchain ke Supabase Cloud
      unawaited(
        SupabaseService.instance.updateCloudOrderReceipt(
          orderId: order.id,
          receiptHash: receiptResult.receiptHash,
          txHash: receiptResult.txHash,
        ),
      );
    } catch (_) {}
  }

  void updateOrderVoucherUsage({
    required String orderId,
    required String usageTxHash,
    bool isSimulated = true,
  }) {
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == orderId) {
          return o.copyWith(
            voucherUsageTxHash: usageTxHash,
            voucherBlockchainTxHash: usageTxHash,
            voucherIsSimulated: isSimulated,
          );
        }
        return o;
      }).toList(),
    );

    AppDatabase.instance.updateOrderVoucherUsage(
      orderId: orderId,
      usageTxHash: usageTxHash,
      isSimulated: isSimulated,
    );
  }

  void updateOrderStatus(String orderId, String newStatus) {
    OrderItemModel? updatedOrder;
    String? previousStatus;

    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == orderId) {
          previousStatus = o.status;
          final next = o.copyWith(status: newStatus);
          updatedOrder = next;
          return next;
        }
        return o;
      }).toList(),
    );

    if (updatedOrder != null) {
      // Jika pesanan dibatalkan dan sebelumnya belum dibatalkan, kembalikan stok
      if (newStatus == 'CANCELLED' && previousStatus != 'CANCELLED') {
        _ref
            ?.read(catalogProductsProvider.notifier)
            .restoreStockForOrderSummary(updatedOrder!.itemsSummary);
      }

      // Update di SQFLITE
      AppDatabase.instance.updateCachedOrderStatus(orderId, newStatus);

      // Update di SUPABASE
      SupabaseService.instance.updateCloudOrderStatus(orderId, newStatus);

      // Pemicu Notifikasi Status Dapur
      _ref
          ?.read(notificationProvider.notifier)
          .triggerOrderStatusNotification(
            orderNumber: updatedOrder!.orderNumber,
            newStatus: newStatus,
          );
    }
  }

  void updatePaymentStatus(String orderId, String newPaymentStatus) {
    state = state.copyWith(
      orders: state.orders.map((o) {
        if (o.id == orderId) {
          return o.copyWith(paymentStatus: newPaymentStatus);
        }
        return o;
      }).toList(),
    );
  }

  /// Sinkronisasi pesanan dari Supabase Cloud (baik per user atau seluruhnya untuk Admin)
  Future<void> syncOrdersFromCloud({String? userId}) async {
    try {
      final cloudOrders = userId != null && userId.isNotEmpty
          ? await SupabaseService.instance.fetchOrdersForUser(userId)
          : await SupabaseService.instance.fetchAllCloudOrders();

      if (cloudOrders.isNotEmpty) {
        final existingIds = state.orders.map((o) => o.id).toSet();
        final newOrders =
            cloudOrders.where((o) => !existingIds.contains(o.id)).toList();

        if (newOrders.isNotEmpty) {
          for (final order in newOrders) {
            await AppDatabase.instance.insertCachedOrder({
              'id': order.id,
              'user_id': order.userId,
              'order_number': order.orderNumber,
              'created_at': order.createdAt.toIso8601String(),
              'order_type': order.orderType,
              'payment_method': order.paymentMethod,
              'payment_status': order.paymentStatus,
              'status': order.status,
              'subtotal': order.subtotal,
              'tax': order.tax,
              'delivery_fee': order.deliveryFee,
              'total': order.total,
              'items_summary': order.itemsSummary,
              'customer_name': order.customerName,
              'customer_phone': order.customerPhone,
              'delivery_address': order.deliveryAddress,
              'notes': order.notes,
              'branch_id': order.branchId,
              'branch_name': order.branchName,
              'branch_timezone': order.branchTimezone,
              'branch_currency': order.branchCurrency,
              'receipt_hash': order.receiptHash,
              'receipt_tx_hash': order.receiptBlockchainTxHash,
              'is_synced': 1,
            });
          }
          final allOrders = [...state.orders, ...newOrders];
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          state = state.copyWith(orders: allOrders);
        }
      }
    } catch (e) {
      debugPrint('syncOrdersFromCloud error: $e');
    }
  }
}

final ordersProvider = StateNotifierProvider<OrdersNotifier, OrdersState>((
  ref,
) {
  return OrdersNotifier(ref);
});
