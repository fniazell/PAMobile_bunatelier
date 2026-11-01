import 'dart:convert';
import 'package:crypto/crypto.dart';

class CanonicalReceiptItem {
  final String name;
  final int quantity;
  final int price;
  final int subtotal;

  const CanonicalReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'subtotal': subtotal,
  };

  factory CanonicalReceiptItem.fromMap(Map<String, dynamic> map) {
    return CanonicalReceiptItem(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      price: (map['price'] as num?)?.toInt() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class CanonicalReceiptData {
  final String orderId;
  final String orderType;
  final String branchId;
  final String currency;
  final List<CanonicalReceiptItem> items;
  final int subtotal;
  final int discount;
  final int tax;
  final int deliveryFee;
  final int total;
  final String paymentMethod;
  final String paymentStatus;

  const CanonicalReceiptData({
    required this.orderId,
    required this.orderType,
    required this.branchId,
    required this.currency,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
  });

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'orderType': orderType,
    'branchId': branchId,
    'currency': currency,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'tax': tax,
    'deliveryFee': deliveryFee,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
  };

  factory CanonicalReceiptData.fromMap(Map<String, dynamic> map) {
    return CanonicalReceiptData(
      orderId: map['orderId'] as String? ?? '',
      orderType: map['orderType'] as String? ?? 'PICKUP',
      branchId: map['branchId'] as String? ?? 'out-1',
      currency: map['currency'] as String? ?? 'IDR',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => CanonicalReceiptItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num?)?.toInt() ?? 0,
      discount: (map['discount'] as num?)?.toInt() ?? 0,
      tax: (map['tax'] as num?)?.toInt() ?? 0,
      deliveryFee: (map['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
      paymentMethod: map['paymentMethod'] as String? ?? 'QRIS',
      paymentStatus: map['paymentStatus'] as String? ?? 'PAID',
    );
  }
}

/// Normalizes e-receipt data into a strictly deterministic canonical string.
String buildCanonicalReceiptString(CanonicalReceiptData data) {
  final sortedItems = List<CanonicalReceiptItem>.from(data.items)
    ..sort((a, b) => a.name.compareTo(b.name));

  final itemsStr = sortedItems.map((item) {
    final cleanName = item.name.trim();
    final qty = item.quantity;
    final price = item.price;
    final sub = item.subtotal;
    return '$cleanName:$qty:$price:$sub';
  }).join(';');

  final orderId = data.orderId.trim();
  final orderType = data.orderType.trim().toUpperCase();
  final branchId = data.branchId.trim();
  final currency = data.currency.trim().toUpperCase();
  final subtotal = data.subtotal;
  final discount = data.discount;
  final tax = data.tax;
  final deliveryFee = data.deliveryFee;
  final total = data.total;
  final paymentMethod = data.paymentMethod.trim().toUpperCase();
  final paymentStatus = data.paymentStatus.trim().toUpperCase();

  return [
    'BUN_RECEIPT_V1',
    orderId,
    orderType,
    branchId,
    currency,
    itemsStr,
    subtotal.toString(),
    discount.toString(),
    tax.toString(),
    deliveryFee.toString(),
    total.toString(),
    paymentMethod,
    paymentStatus,
  ].join('|');
}

/// Computes standard SHA-256 hash of the canonical receipt string.
String computeReceiptHash(CanonicalReceiptData data) {
  final canonical = buildCanonicalReceiptString(data);
  final digest = sha256.convert(utf8.encode(canonical));
  return '0x$digest'.toLowerCase();
}

