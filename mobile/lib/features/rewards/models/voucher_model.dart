import 'package:intl/intl.dart';

enum VoucherType {
  discount5,
  discount15,
  discount20;

  int get discountPercent {
    switch (this) {
      case VoucherType.discount5:
        return 5;
      case VoucherType.discount15:
        return 15;
      case VoucherType.discount20:
        return 20;
    }
  }

  int get pointsCost {
    switch (this) {
      case VoucherType.discount5:
        return 15;
      case VoucherType.discount15:
        return 350;
      case VoucherType.discount20:
        return 500;
    }
  }

  String get title {
    switch (this) {
      case VoucherType.discount5:
        return 'Diskon 5%';
      case VoucherType.discount15:
        return 'Diskon 15%';
      case VoucherType.discount20:
        return 'Diskon 20%';
    }
  }

  String get subtitle {
    switch (this) {
      case VoucherType.discount5:
        return 'Potongan 5% untuk semua menu burger & side';
      case VoucherType.discount15:
        return 'Potongan 15% untuk santapan atelier spesial';
      case VoucherType.discount20:
        return 'Potongan 20% hemat maksimal artisan grill';
    }
  }
}

enum VoucherStatus {
  available,
  used,
  expired;

  String get label {
    switch (this) {
      case VoucherStatus.available:
        return 'Available';
      case VoucherStatus.used:
        return 'Used';
      case VoucherStatus.expired:
        return 'Expired';
    }
  }
}

enum BlockchainStatus {
  pending,
  confirmed,
  failed;

  String get label {
    switch (this) {
      case BlockchainStatus.pending:
        return 'Pending';
      case BlockchainStatus.confirmed:
        return 'Confirmed';
      case BlockchainStatus.failed:
        return 'Failed';
    }
  }
}

class VoucherModel {
  final String id;
  final String userId;
  final String code; // E.g. BUN5-9B2F
  final VoucherType type;
  final int discountPercent;
  final int pointsCost;
  final VoucherStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final String? usedOrderId;

  // Blockchain Audit Fields
  final String redemptionReferenceId;
  final String? redemptionTxHash;
  final BlockchainStatus blockchainStatus;
  final String? usageTxHash;
  final String? usageReferenceId;
  final String? explorerUrl;

  const VoucherModel({
    required this.id,
    required this.userId,
    required this.code,
    required this.type,
    required this.discountPercent,
    required this.pointsCost,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.usedAt,
    this.usedOrderId,
    required this.redemptionReferenceId,
    this.redemptionTxHash,
    this.blockchainStatus = BlockchainStatus.pending,
    this.usageTxHash,
    this.usageReferenceId,
    this.explorerUrl,
  });

  bool get isAvailable =>
      status == VoucherStatus.available && DateTime.now().isBefore(expiresAt);

  bool get isExpired =>
      status == VoucherStatus.expired || DateTime.now().isAfter(expiresAt);

  bool get isUsed => status == VoucherStatus.used;

  int calculateDiscount(int subtotal) {
    if (subtotal <= 0) return 0;
    return (subtotal * (discountPercent / 100.0)).round();
  }

  String get formattedExpiry {
    return DateFormat('dd MMM yyyy, HH:mm').format(expiresAt);
  }

  String get truncatedTxHash {
    if (redemptionTxHash == null || redemptionTxHash!.isEmpty) return '-';
    if (redemptionTxHash!.length <= 14) return redemptionTxHash!;
    return '${redemptionTxHash!.substring(0, 8)}...${redemptionTxHash!.substring(redemptionTxHash!.length - 6)}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'code': code,
      'voucher_type': type.name,
      'discount_percent': discountPercent,
      'points_cost': pointsCost,
      'status': status.name.toUpperCase(),
      'issued_at': issuedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'used_order_id': usedOrderId,
      'redemption_reference_id': redemptionReferenceId,
      'redemption_tx_hash': redemptionTxHash,
      'blockchain_status': blockchainStatus.name.toUpperCase(),
      'usage_tx_hash': usageTxHash,
      'usage_reference_id': usageReferenceId,
    };
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    final typeName = map['voucher_type'] as String? ?? 'discount5';
    final type = VoucherType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => VoucherType.discount5,
    );

    final statusStr = (map['status'] as String? ?? 'AVAILABLE').toLowerCase();
    VoucherStatus status;
    if (statusStr == 'used') {
      status = VoucherStatus.used;
    } else if (statusStr == 'expired') {
      status = VoucherStatus.expired;
    } else {
      status = VoucherStatus.available;
    }

    final bcStr = (map['blockchain_status'] as String? ?? 'PENDING').toLowerCase();
    BlockchainStatus bcStatus;
    if (bcStr == 'confirmed') {
      bcStatus = BlockchainStatus.confirmed;
    } else if (bcStr == 'failed') {
      bcStatus = BlockchainStatus.failed;
    } else {
      bcStatus = BlockchainStatus.pending;
    }

    final issuedAt = DateTime.parse(map['issued_at'] as String);
    final expiresAt = DateTime.parse(map['expires_at'] as String);

    return VoucherModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      code: map['code'] as String,
      type: type,
      discountPercent: (map['discount_percent'] as num?)?.toInt() ?? type.discountPercent,
      pointsCost: (map['points_cost'] as num?)?.toInt() ?? type.pointsCost,
      status: status,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      usedAt: map['used_at'] != null ? DateTime.tryParse(map['used_at'] as String) : null,
      usedOrderId: map['used_order_id'] as String?,
      redemptionReferenceId: map['redemption_reference_id'] as String? ?? '',
      redemptionTxHash: map['redemption_tx_hash'] as String?,
      blockchainStatus: bcStatus,
      usageTxHash: map['usage_tx_hash'] as String?,
      usageReferenceId: map['usage_reference_id'] as String?,
      explorerUrl: map['explorer_url'] as String?,
    );
  }

  VoucherModel copyWith({
    VoucherStatus? status,
    DateTime? usedAt,
    String? usedOrderId,
    BlockchainStatus? blockchainStatus,
    String? redemptionTxHash,
    String? usageTxHash,
    String? usageReferenceId,
    String? explorerUrl,
  }) {
    return VoucherModel(
      id: id,
      userId: userId,
      code: code,
      type: type,
      discountPercent: discountPercent,
      pointsCost: pointsCost,
      status: status ?? this.status,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedOrderId: usedOrderId ?? this.usedOrderId,
      redemptionReferenceId: redemptionReferenceId,
      redemptionTxHash: redemptionTxHash ?? this.redemptionTxHash,
      blockchainStatus: blockchainStatus ?? this.blockchainStatus,
      usageTxHash: usageTxHash ?? this.usageTxHash,
      usageReferenceId: usageReferenceId ?? this.usageReferenceId,
      explorerUrl: explorerUrl ?? this.explorerUrl,
    );
  }
}
