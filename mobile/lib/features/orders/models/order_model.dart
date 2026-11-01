import 'package:intl/intl.dart';
import '../../converter/services/currency_service.dart';

class OrderItemModel {
  final String id;
  final String? userId;
  final String orderNumber;
  final DateTime createdAt;
  final String orderType; // 'PICKUP' | 'DELIVERY'
  final String paymentMethod; // 'QRIS' | 'EWALLET' | 'CASHIER'
  final String paymentStatus; // 'PENDING' | 'PAID' | 'FAILED'
  final String status; // 'CONFIRMED' | 'PREPARING' | 'READY_FOR_PICKUP' | 'OUT_FOR_DELIVERY' | 'COMPLETED' | 'CANCELLED'
  final int subtotal;
  final int tax;
  final int deliveryFee;
  final int total;
  final String? deliveryAddress;
  final String? notes;
  final String itemsSummary;
  final String customerName;
  final String? customerPhone;
  final String? branchId;
  final String? branchName;
  final String? branchTimezone;
  final String? branchCurrency;
  final String? voucherCode;
  final int? voucherDiscountPercent;
  final int? voucherDiscountAmount;
  final String? voucherBlockchainTxHash;
  final String? voucherReferenceId;
  final String? voucherRedemptionTxHash;
  final String? voucherUsageTxHash;
  final bool voucherIsSimulated;
  final String? receiptHash;
  final String? receiptPreviousHash;
  final String? receiptBlockchainTxHash;
  final String? receiptExplorerUrl;
  final bool receiptIsSimulated;

  OrderItemModel({
    required this.id,
    this.userId,
    required this.orderNumber,
    required this.createdAt,
    required this.orderType,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.subtotal,
    required this.tax,
    this.deliveryFee = 0,
    required this.total,
    this.deliveryAddress,
    this.notes,
    required this.itemsSummary,
    this.customerName = 'Pelanggan Bun Atelier',
    this.customerPhone,
    this.branchId,
    this.branchName,
    this.branchTimezone,
    this.branchCurrency,
    this.voucherCode,
    this.voucherDiscountPercent,
    this.voucherDiscountAmount,
    this.voucherBlockchainTxHash,
    this.voucherReferenceId,
    this.voucherRedemptionTxHash,
    this.voucherUsageTxHash,
    this.voucherIsSimulated = true,
    this.receiptHash,
    this.receiptPreviousHash,
    this.receiptBlockchainTxHash,
    this.receiptExplorerUrl,
    this.receiptIsSimulated = true,
  });

  String get timezoneLabel {
    switch (branchTimezone) {
      case 'Asia/Jayapura':
        return 'WIT (UTC+9)';
      case 'Asia/Makassar':
        return 'WITA (UTC+8)';
      case 'Asia/Jakarta':
        return 'WIB (UTC+7)';
      case 'Europe/London':
        return 'GMT (UTC+0)';
      case 'Asia/Kuala_Lumpur':
        return 'MYT (UTC+8)';
      case 'Asia/Singapore':
        return 'SGT (UTC+8)';
      default:
        return 'WIB (UTC+7)';
    }
  }

  DateTime get transactionTimeInBranchTimezone {
    final utc = createdAt.toUtc();
    int offsetHours;
    switch (branchTimezone) {
      case 'Asia/Jayapura':
        offsetHours = 9;
        break;
      case 'Asia/Makassar':
      case 'Asia/Kuala_Lumpur':
      case 'Asia/Singapore':
        offsetHours = 8;
        break;
      case 'Asia/Jakarta':
        offsetHours = 7;
        break;
      case 'Europe/London':
        offsetHours = 0;
        break;
      default:
        offsetHours = 7;
    }
    return utc.add(Duration(hours: offsetHours));
  }

  String formattedTransactionTime() {
    final dt = transactionTimeInBranchTimezone;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm $timezoneLabel';
  }

  bool get isForeignCurrency {
    final c = (branchCurrency ?? 'IDR').toUpperCase();
    return c.isNotEmpty && c != 'IDR';
  }

  String get effectiveCurrencyCode => (branchCurrency ?? 'IDR').toUpperCase();

  String get currencyName {
    switch (effectiveCurrencyCode) {
      case 'GBP':
        return 'British Pound';
      case 'MYR':
        return 'Malaysian Ringgit';
      case 'SGD':
        return 'Singapore Dollar';
      case 'IDR':
      default:
        return 'Rupiah Indonesia';
    }
  }

  String get currencyFlag {
    switch (effectiveCurrencyCode) {
      case 'GBP':
        return '🇬🇧';
      case 'MYR':
        return '🇲🇾';
      case 'SGD':
        return '🇸🇬';
      case 'IDR':
      default:
        return '🇮🇩';
    }
  }

  String get currencySymbol {
    switch (effectiveCurrencyCode) {
      case 'GBP':
        return '£';
      case 'MYR':
        return 'RM ';
      case 'SGD':
        return 'S\$ ';
      case 'IDR':
      default:
        return 'Rp ';
    }
  }

  /// Formats an IDR amount into the branch's local currency.
  /// - For Indonesia (IDR): 'Rp 150.000'
  /// - For London (GBP): '£ 7.21'
  /// - For Malaysia (MYR): 'RM 40.00'
  /// - For Singapore (SGD): 'S$ 12.30'
  String formatBranchAmount(int amountInIdr) {
    if (!isForeignCurrency) {
      return formatIdr(amountInIdr);
    }

    final conv = CurrencyService.instance.convert(
      amount: amountInIdr.toDouble(),
      fromCurrency: 'IDR',
      toCurrency: effectiveCurrencyCode,
    );
    return '$currencySymbol ${conv.formattedTarget}';
  }

  /// Formats an amount directly as Indonesian Rupiah: 'Rp 150.000'
  String formatIdr(int amountInIdr) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(amountInIdr);
    return 'Rp $formatted';
  }

  String get formattedSubtotal => formatBranchAmount(subtotal);
  String get formattedTax => formatBranchAmount(tax);
  String get formattedDeliveryFee => formatBranchAmount(deliveryFee);
  String get formattedTotal => formatBranchAmount(total);

  String get formattedIdrTotal => formatIdr(total);
  String get formattedIdrSubtotal => formatIdr(subtotal);

  bool get hasVoucher => (voucherDiscountAmount ?? 0) > 0;
  String get formattedVoucherDiscount => formatBranchAmount(voucherDiscountAmount ?? 0);
  String get formattedIdrVoucherDiscount => formatIdr(voucherDiscountAmount ?? 0);

  /// Human-readable exchange rate for foreign branch currency
  String? get branchExchangeRateInfo {
    if (!isForeignCurrency) return null;
    final conv = CurrencyService.instance.convert(
      amount: 1.0,
      fromCurrency: effectiveCurrencyCode,
      toCurrency: 'IDR',
    );
    final formattedRate = NumberFormat('#,##0', 'id_ID').format(conv.targetAmount.round());
    return '1 $effectiveCurrencyCode ≈ Rp $formattedRate';
  }

  /// True if the order has been confirmed by the kitchen / restaurant.
  /// Pending orders or cancelled orders are not confirmed.
  bool get isConfirmed {
    final s = status.trim().toUpperCase();
    return s == 'CONFIRMED' ||
        s == 'PREPARING' ||
        s == 'READY_FOR_PICKUP' ||
        s == 'OUT_FOR_DELIVERY' ||
        s == 'COMPLETED';
  }

  OrderItemModel copyWith({
    String? userId,
    String? status,
    String? paymentStatus,
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
    bool? voucherIsSimulated,
    String? receiptHash,
    String? receiptPreviousHash,
    String? receiptBlockchainTxHash,
    String? receiptExplorerUrl,
    bool? receiptIsSimulated,
  }) {
    return OrderItemModel(
      id: id,
      userId: userId ?? this.userId,
      orderNumber: orderNumber,
      createdAt: createdAt,
      orderType: orderType,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      subtotal: subtotal,
      tax: tax,
      deliveryFee: deliveryFee,
      total: total,
      deliveryAddress: deliveryAddress,
      notes: notes,
      itemsSummary: itemsSummary,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchTimezone: branchTimezone ?? this.branchTimezone,
      branchCurrency: branchCurrency ?? this.branchCurrency,
      voucherCode: voucherCode ?? this.voucherCode,
      voucherDiscountPercent: voucherDiscountPercent ?? this.voucherDiscountPercent,
      voucherDiscountAmount: voucherDiscountAmount ?? this.voucherDiscountAmount,
      voucherBlockchainTxHash: voucherBlockchainTxHash ?? this.voucherBlockchainTxHash,
      voucherReferenceId: voucherReferenceId ?? this.voucherReferenceId,
      voucherRedemptionTxHash: voucherRedemptionTxHash ?? this.voucherRedemptionTxHash,
      voucherUsageTxHash: voucherUsageTxHash ?? this.voucherUsageTxHash,
      voucherIsSimulated: voucherIsSimulated ?? this.voucherIsSimulated,
      receiptHash: receiptHash ?? this.receiptHash,
      receiptPreviousHash: receiptPreviousHash ?? this.receiptPreviousHash,
      receiptBlockchainTxHash: receiptBlockchainTxHash ?? this.receiptBlockchainTxHash,
      receiptExplorerUrl: receiptExplorerUrl ?? this.receiptExplorerUrl,
      receiptIsSimulated: receiptIsSimulated ?? this.receiptIsSimulated,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> r) {
    return OrderItemModel(
      id: r['id']?.toString() ?? '',
      userId: r['user_id']?.toString(),
      orderNumber: r['order_number']?.toString() ?? '',
      createdAt: DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
      orderType: r['order_type']?.toString() ?? 'PICKUP',
      paymentMethod: r['payment_method']?.toString() ?? 'QRIS',
      paymentStatus: r['payment_status']?.toString() ?? 'PAID',
      status: r['status']?.toString() ?? 'CONFIRMED',
      subtotal: (r['subtotal'] as num?)?.toInt() ?? 0,
      tax: (r['tax'] as num?)?.toInt() ?? 0,
      deliveryFee: (r['delivery_fee'] as num?)?.toInt() ?? 0,
      total: (r['total'] as num?)?.toInt() ?? 0,
      itemsSummary: r['items_summary']?.toString() ?? '',
      customerName: r['customer_name']?.toString() ?? 'Pelanggan Bun Atelier',
      customerPhone: r['customer_phone']?.toString(),
      deliveryAddress: r['delivery_address']?.toString(),
      notes: r['notes']?.toString(),
      branchId: r['branch_id']?.toString() ?? 'out-1',
      branchName: r['branch_name']?.toString() ?? 'Bun Atelier — Senopati Flagship',
      branchTimezone: r['branch_timezone']?.toString() ?? 'Asia/Jakarta',
      branchCurrency: r['branch_currency']?.toString() ?? 'IDR',
      voucherCode: r['voucher_code']?.toString(),
      voucherDiscountAmount: (r['voucher_discount_amount'] as num?)?.toInt(),
      voucherBlockchainTxHash: r['voucher_tx_hash']?.toString(),
      voucherReferenceId: r['voucher_reference_id']?.toString(),
      voucherRedemptionTxHash: r['voucher_redemption_tx_hash']?.toString() ?? r['voucher_tx_hash']?.toString(),
      voucherUsageTxHash: r['voucher_usage_tx_hash']?.toString(),
      voucherIsSimulated: (r['voucher_is_simulated'] as int?) != 0,
      receiptHash: r['receipt_hash']?.toString(),
      receiptPreviousHash: r['receipt_previous_hash']?.toString(),
      receiptBlockchainTxHash: r['receipt_tx_hash']?.toString(),
      receiptExplorerUrl: r['receipt_explorer_url']?.toString(),
      receiptIsSimulated: (r['receipt_is_simulated'] as int?) != 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'order_number': orderNumber,
      'created_at': createdAt.toIso8601String(),
      'order_type': orderType,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'status': status,
      'subtotal': subtotal,
      'tax': tax,
      'delivery_fee': deliveryFee,
      'total': total,
      'items_summary': itemsSummary,
      'customer_name': customerName,
      if (customerPhone != null) 'customer_phone': customerPhone,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      if (notes != null) 'notes': notes,
      if (branchId != null) 'branch_id': branchId,
      if (branchName != null) 'branch_name': branchName,
      if (branchTimezone != null) 'branch_timezone': branchTimezone,
      if (branchCurrency != null) 'branch_currency': branchCurrency,
      if (voucherCode != null) 'voucher_code': voucherCode,
      if (voucherDiscountAmount != null) 'voucher_discount_amount': voucherDiscountAmount,
      if (voucherBlockchainTxHash != null) 'voucher_tx_hash': voucherBlockchainTxHash,
      if (voucherReferenceId != null) 'voucher_reference_id': voucherReferenceId,
      if (voucherRedemptionTxHash != null) 'voucher_redemption_tx_hash': voucherRedemptionTxHash,
      if (voucherUsageTxHash != null) 'voucher_usage_tx_hash': voucherUsageTxHash,
      'voucher_is_simulated': voucherIsSimulated ? 1 : 0,
      if (receiptHash != null) 'receipt_hash': receiptHash,
      if (receiptPreviousHash != null) 'receipt_previous_hash': receiptPreviousHash,
      if (receiptBlockchainTxHash != null) 'receipt_tx_hash': receiptBlockchainTxHash,
      if (receiptExplorerUrl != null) 'receipt_explorer_url': receiptExplorerUrl,
      'receipt_is_simulated': receiptIsSimulated ? 1 : 0,
    };
  }
}

