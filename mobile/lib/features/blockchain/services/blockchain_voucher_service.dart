import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import '../../rewards/models/voucher_model.dart';
import '../../orders/models/order_model.dart';

class BlockchainTxReceipt {
  final bool success;
  final String network;
  final String txHash;
  final int blockNumber;
  final String timestamp;
  final String referenceId;
  final bool isSimulated;
  final String? explorerUrl;
  final String? errorMessage;

  const BlockchainTxReceipt({
    required this.success,
    required this.network,
    required this.txHash,
    required this.blockNumber,
    required this.timestamp,
    required this.referenceId,
    this.isSimulated = false,
    this.explorerUrl,
    this.errorMessage,
  });

  factory BlockchainTxReceipt.fromMap(Map<String, dynamic> map) {
    return BlockchainTxReceipt(
      success: map['success'] as bool? ?? false,
      network: map['network'] as String? ?? 'EVM Network',
      txHash: map['txHash'] as String? ?? '',
      blockNumber: (map['blockNumber'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      referenceId: map['referenceId'] as String? ?? '',
      isSimulated: map['isSimulated'] as bool? ?? false,
      explorerUrl: map['explorerUrl'] as String?,
      errorMessage: map['error'] as String?,
    );
  }
}

class BlockchainVoucherVerificationResult {
  final bool isValid;
  final String status;
  final bool isRecorded;
  final bool isConsumed;
  final bool isSimulated;
  final String referenceId;
  final String network;
  final String? redemptionTxHash;
  final String? usageTxHash;
  final String reason;
  final String timestamp;

  const BlockchainVoucherVerificationResult({
    required this.isValid,
    required this.status,
    required this.isRecorded,
    required this.isConsumed,
    this.isSimulated = true,
    required this.referenceId,
    this.network = 'EVM_LOCAL_SIMULATOR (Sepolia Compatible)',
    this.redemptionTxHash,
    this.usageTxHash,
    required this.reason,
    required this.timestamp,
  });

  factory BlockchainVoucherVerificationResult.fromMap(Map<String, dynamic> map) {
    final redemption = map['redemption'] as Map<String, dynamic>?;
    final usage = map['usage'] as Map<String, dynamic>?;
    return BlockchainVoucherVerificationResult(
      isValid: map['isValid'] as bool? ?? false,
      status: map['status'] as String? ?? 'UNKNOWN',
      isRecorded: map['isRecorded'] as bool? ?? false,
      isConsumed: map['isConsumed'] as bool? ?? false,
      isSimulated: map['isSimulated'] as bool? ?? true,
      referenceId: map['referenceId'] as String? ?? '',
      network: map['network'] as String? ?? 'EVM_LOCAL_SIMULATOR (Sepolia Compatible)',
      redemptionTxHash: redemption?['txHash'] as String?,
      usageTxHash: usage?['txHash'] as String?,
      reason: map['reason'] as String? ?? '',
      timestamp: map['verifiedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}

class BlockchainVoucherService {
  static final BlockchainVoucherService instance = BlockchainVoucherService._();
  BlockchainVoucherService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Catat penukaran voucher ke blockchain (Backend relayer atau fallback simulator)
  Future<BlockchainTxReceipt> recordRedemption({
    required VoucherModel voucher,
  }) async {
    // 1. Buat cryptographic proof hash tanpa memuat data pribadi customer
    final proofRaw = 'REDEMPTION_PROOF|${voucher.id}|${voucher.userId}|${voucher.pointsCost}|${voucher.issuedAt.millisecondsSinceEpoch}';
    final proofHash = sha256.convert(utf8.encode(proofRaw)).toString();

    final payload = {
      'referenceId': voucher.redemptionReferenceId,
      'discountPercent': voucher.discountPercent,
      'pointsBurned': voucher.pointsCost,
      'proofHash': '0x$proofHash',
    };

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/blockchain/record-redemption',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockchainTxReceipt.fromMap(response.data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Blockchain backend unreachable ($e). Using local EVM simulator receipt.');
    }

    // Fallback: Deterministic local EVM transaction generation for offline/isolated tests
    final rawTx = 'SIMULATED_TX|REDEMPTION|${voucher.redemptionReferenceId}|$proofHash|${voucher.issuedAt.toIso8601String()}';
    final localTxHash = '0x${sha256.convert(utf8.encode(rawTx)).toString()}';

    return BlockchainTxReceipt(
      success: true,
      network: 'EVM_LOCAL_SIMULATOR (Sepolia Compatible)',
      txHash: localTxHash,
      blockNumber: 7248100 + (voucher.issuedAt.millisecondsSinceEpoch % 10000),
      timestamp: voucher.issuedAt.toIso8601String(),
      referenceId: voucher.redemptionReferenceId,
      isSimulated: true,
    );
  }

  /// Catat penggunaan voucher saat checkout ke blockchain
  Future<BlockchainTxReceipt> recordUsage({
    required VoucherModel voucher,
    required OrderItemModel order,
  }) async {
    // 1. Buat order hash tanpa memuat data sensitif pengguna
    final orderProofRaw = 'ORDER_USAGE|${order.id}|${order.orderNumber}|${order.total}|${order.createdAt.millisecondsSinceEpoch}';
    final orderHash = '0x${sha256.convert(utf8.encode(orderProofRaw)).toString()}';

    final payload = {
      'referenceId': voucher.redemptionReferenceId,
      'orderHash': orderHash,
      'discountPercent': voucher.discountPercent,
    };

    try {
      final response = await _dio.post(
        '${ApiConstants.baseUrl}/blockchain/record-usage',
        data: payload,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockchainTxReceipt.fromMap(response.data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Blockchain backend usage unreachable ($e). Using local EVM simulator receipt.');
    }

    final rawTx = 'SIMULATED_TX|USAGE|${voucher.redemptionReferenceId}|$orderHash|${DateTime.now().toIso8601String()}';
    final localTxHash = '0x${sha256.convert(utf8.encode(rawTx)).toString()}';

    return BlockchainTxReceipt(
      success: true,
      network: 'EVM_LOCAL_SIMULATOR (Sepolia Compatible)',
      txHash: localTxHash,
      blockNumber: 7248101 + (DateTime.now().millisecondsSinceEpoch % 10000),
      timestamp: DateTime.now().toIso8601String(),
      referenceId: voucher.redemptionReferenceId,
      isSimulated: true,
    );
  }

  /// Verifikasi integritas bukti voucher (penukaran & pemakaian)
  Future<BlockchainVoucherVerificationResult> verifyVoucher({
    required String referenceId,
    String? proofHash,
    String? orderHash,
    VoucherModel? voucher,
    OrderItemModel? order,
  }) async {
    // 1. Tentukan proofHash & orderHash jika voucher & order diberikan
    String? effectiveProof = proofHash;
    if (effectiveProof == null && voucher != null) {
      final proofRaw =
          'REDEMPTION_PROOF|${voucher.id}|${voucher.userId}|${voucher.pointsCost}|${voucher.issuedAt.millisecondsSinceEpoch}';
      effectiveProof = '0x${sha256.convert(utf8.encode(proofRaw))}';
    }

    String? effectiveOrderHash = orderHash;
    if (effectiveOrderHash == null && order != null) {
      final orderProofRaw =
          'ORDER_USAGE|${order.id}|${order.orderNumber}|${order.total}|${order.createdAt.millisecondsSinceEpoch}';
      effectiveOrderHash = '0x${sha256.convert(utf8.encode(orderProofRaw))}';
    }

    // 2. Hubungi backend jika tersedia
    try {
      final Map<String, dynamic> requestData = {'referenceId': referenceId};
      if (effectiveProof != null) requestData['proofHash'] = effectiveProof;
      if (effectiveOrderHash != null) requestData['orderHash'] = effectiveOrderHash;

      final response = await _dio.post(
        '${ApiConstants.baseUrl}/blockchain/voucher/verify',
        data: requestData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return BlockchainVoucherVerificationResult.fromMap(
          response.data['data'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Backend voucher verify unreachable ($e). Menggunakan verifikasi lokal.');
    }

    // 3. Fallback verifikasi lokal jika backend offline
    if (voucher != null) {
      final proofRaw =
          'REDEMPTION_PROOF|${voucher.id}|${voucher.userId}|${voucher.pointsCost}|${voucher.issuedAt.millisecondsSinceEpoch}';
      final expectedProof = '0x${sha256.convert(utf8.encode(proofRaw))}';

      if (effectiveProof != null &&
          effectiveProof.toLowerCase() != expectedProof.toLowerCase()) {
        return BlockchainVoucherVerificationResult(
          isValid: false,
          status: 'PROOF_MISMATCH',
          isRecorded: true,
          isConsumed: voucher.isUsed,
          isSimulated: true,
          referenceId: referenceId,
          reason:
              'Fingerprint voucher tidak cocok! Terdeteksi modifikasi pada data penukaran poin.',
          timestamp: DateTime.now().toIso8601String(),
        );
      }
    }

    final hasUsage = order?.voucherUsageTxHash != null &&
        order!.voucherUsageTxHash!.isNotEmpty;

    return BlockchainVoucherVerificationResult(
      isValid: true,
      status: 'VERIFIED_SIMULATED',
      isRecorded: true,
      isConsumed: hasUsage,
      isSimulated: true,
      referenceId: referenceId,
      redemptionTxHash: voucher?.redemptionTxHash ?? order?.voucherRedemptionTxHash,
      usageTxHash: order?.voucherUsageTxHash,
      reason:
          'Fingerprint voucher terverifikasi valid (Mode Simulasi Lokal). Belum tercatat on-chain di jaringan Ethereum Sepolia.',
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}
