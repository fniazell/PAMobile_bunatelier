import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blockchain/services/blockchain_voucher_service.dart';
import '../../orders/models/order_model.dart';
import '../data/reward_repository.dart';
import '../models/voucher_model.dart';
import 'rewards_provider.dart';

class VoucherState {
  final List<VoucherModel> vouchers;
  final bool isLoading;
  final bool isRedeeming;
  final String? errorMessage;
  final VoucherModel? selectedVoucherForCheckout;

  const VoucherState({
    this.vouchers = const [],
    this.isLoading = false,
    this.isRedeeming = false,
    this.errorMessage,
    this.selectedVoucherForCheckout,
  });

  List<VoucherModel> get availableVouchers =>
      vouchers.where((v) => v.isAvailable).toList();

  List<VoucherModel> get usedVouchers =>
      vouchers.where((v) => v.isUsed).toList();

  List<VoucherModel> get expiredVouchers =>
      vouchers.where((v) => v.isExpired).toList();

  VoucherState copyWith({
    List<VoucherModel>? vouchers,
    bool? isLoading,
    bool? isRedeeming,
    String? errorMessage,
    bool clearError = false,
    VoucherModel? selectedVoucherForCheckout,
    bool clearSelectedVoucher = false,
  }) {
    return VoucherState(
      vouchers: vouchers ?? this.vouchers,
      isLoading: isLoading ?? this.isLoading,
      isRedeeming: isRedeeming ?? this.isRedeeming,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedVoucherForCheckout: clearSelectedVoucher
          ? null
          : selectedVoucherForCheckout ?? this.selectedVoucherForCheckout,
    );
  }
}

final userVouchersProvider =
    StateNotifierProvider.family<VoucherNotifier, VoucherState, String>((
  ref,
  userId,
) {
  final repository = ref.watch(rewardRepositoryProvider);
  return VoucherNotifier(userId, repository, ref);
});

// Shortcut provider for the currently logged in user
final currentUserVouchersProvider = Provider<VoucherState>((ref) {
  final userId = ref.watch(authProvider).user?.id;
  if (userId == null) return const VoucherState();
  return ref.watch(userVouchersProvider(userId));
});

class VoucherNotifier extends StateNotifier<VoucherState> {
  final String userId;
  final RewardRepository _repository;
  final Ref _ref;

  VoucherNotifier(this.userId, this._repository, this._ref)
      : super(const VoucherState()) {
    unawaited(loadVouchers());
  }

  Future<void> loadVouchers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.loadVouchersForUser(userId);
      state = state.copyWith(vouchers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat daftar voucher: $e',
      );
    }
  }

  /// Tukar poin dengan voucher (Dijamin idempotensi & proteksi tombol berulang)
  Future<VoucherModel> redeemVoucher(VoucherType type) async {
    if (state.isRedeeming) {
      throw StateError('Transaksi penukaran sedang diproses. Mohon tunggu.');
    }

    state = state.copyWith(isRedeeming: true, clearError: true);

    try {
      // 1. Redeem di SQLite Database (potong poin secara atomik)
      final voucher = await _repository.redeemVoucher(userId, type);

      // Refresh list voucher dan poin customer seketika
      await loadVouchers();
      await _ref.read(rewardsProvider(userId).notifier).load();

      // 2. Asynchronous Blockchain Recording (Latar belakang tanpa memblokir customer)
      unawaited(_recordRedemptionOnBlockchain(voucher));

      state = state.copyWith(isRedeeming: false);
      return voucher;
    } catch (e) {
      state = state.copyWith(isRedeeming: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> _recordRedemptionOnBlockchain(VoucherModel voucher) async {
    try {
      final receipt = await BlockchainVoucherService.instance.recordRedemption(
        voucher: voucher,
      );

      final newStatus = receipt.success
          ? BlockchainStatus.confirmed
          : BlockchainStatus.failed;

      await _repository.updateVoucherBlockchainStatus(
        voucher.id,
        status: newStatus,
        txHash: receipt.txHash.isNotEmpty ? receipt.txHash : null,
        explorerUrl: receipt.explorerUrl,
      );

      // Update state in memory
      await loadVouchers();
    } catch (_) {
      await _repository.updateVoucherBlockchainStatus(
        voucher.id,
        status: BlockchainStatus.failed,
      );
      await loadVouchers();
    }
  }

  /// Terapkan kode promo di halaman Checkout
  Future<VoucherModel> applyPromoCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      throw ArgumentError('Silakan masukkan kode voucher.');
    }

    final voucher = await _repository.findVoucherByCode(userId, code);
    if (voucher == null) {
      throw ArgumentError('Kode voucher tidak ditemukan atau bukan milik akun Anda.');
    }

    if (voucher.isUsed) {
      throw StateError('Voucher ini sudah pernah digunakan sebelumnya.');
    }

    if (voucher.isExpired) {
      throw StateError('Voucher ini telah kedaluwarsa.');
    }

    if (!voucher.isAvailable) {
      throw StateError('Voucher tidak dapat digunakan saat ini.');
    }

    state = state.copyWith(selectedVoucherForCheckout: voucher);
    return voucher;
  }

  void selectVoucherForCheckout(VoucherModel? voucher) {
    if (voucher == null) {
      state = state.copyWith(clearSelectedVoucher: true);
    } else {
      state = state.copyWith(selectedVoucherForCheckout: voucher);
    }
  }

  void clearSelectedVoucher() {
    state = state.copyWith(clearSelectedVoucher: true);
  }

  /// Catat penggunaan voucher setelah order checkout berhasil
  Future<BlockchainTxReceipt?> consumeVoucherForOrder({
    required VoucherModel voucher,
    required OrderItemModel order,
  }) async {
    try {
      // 1. Catat ke blockchain
      final receipt = await BlockchainVoucherService.instance.recordUsage(
        voucher: voucher,
        order: order,
      );

      // 2. Tandai voucher sebagai Used di database
      await _repository.markVoucherUsed(
        voucher.id,
        order.id,
        usageTxHash: receipt.txHash.isNotEmpty ? receipt.txHash : null,
        usageReferenceId: receipt.referenceId,
      );

      clearSelectedVoucher();
      await loadVouchers();
      return receipt;
    } catch (e) {
      // Tandai used di database agar voucher tidak bisa dipakai ulang
      await _repository.markVoucherUsed(voucher.id, order.id);
      clearSelectedVoucher();
      await loadVouchers();
      return null;
    }
  }

  /// Retry pencatatan blockchain jika sebelumnya gagal
  Future<void> retryBlockchainRecording(VoucherModel voucher) async {
    await _recordRedemptionOnBlockchain(voucher);
  }
}
