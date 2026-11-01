import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../orders/providers/orders_provider.dart';
import '../../branch/providers/branch_provider.dart';
import '../../branch/presentation/widgets/branch_selection_bottom_sheet.dart';
import '../../../../core/services/google_maps_service.dart';
import '../../rewards/models/voucher_model.dart';
import '../../rewards/providers/vouchers_provider.dart';
import '../../blockchain/services/blockchain_receipt_service.dart';
import 'widgets/checkout_currency_card.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _orderType = 'PICKUP'; // 'PICKUP' or 'DELIVERY'
  String _paymentMethod = 'QRIS'; // 'QRIS', 'EWALLET', 'CASHIER'
  final _addressController = TextEditingController(
    text: 'Jl. Senopati No. 45, Kebayoran Baru, Jakarta Selatan',
  );
  final _notesController = TextEditingController();
  final _promoController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    if (_isSubmitting) return;

    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) {
      context.pop();
      return;
    }

    // 1. Validasi ketersediaan dan stok produk secara langsung
    final catalogState = ref.read(catalogProductsProvider);
    for (final item in cartState.items) {
      final product = catalogState.products.firstWhere(
        (p) => p.id == item.product.id,
        orElse: () => item.product,
      );
      if (product.isOutOfStock || product.stock < item.quantity) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Maaf, stok ${product.name} tidak mencukupi (${product.stock} tersisa).',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            messenger.hideCurrentSnackBar();
          }
        });
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final authUser = ref.read(authProvider).user;
      final selectedBranch = ref.read(branchProvider).selectedBranch;
      final voucherState = authUser != null
          ? ref.read(userVouchersProvider(authUser.id))
          : const VoucherState();
      final selectedVoucher = voucherState.selectedVoucherForCheckout;
      final discount = selectedVoucher != null
          ? selectedVoucher.calculateDiscount(cartState.subtotal)
          : 0;

      final newOrder = await ref
          .read(ordersProvider.notifier)
          .createOrder(
            userId: authUser?.id,
            cartItems: cartState.items,
            orderType: _orderType,
            paymentMethod: _paymentMethod,
            deliveryAddress: _orderType == 'DELIVERY'
                ? _addressController.text.trim()
                : null,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            customerName: authUser?.fullName ?? 'Pelanggan Bun Atelier',
            customerPhone: authUser?.phone,
            branchId: selectedBranch.id,
            branchName: selectedBranch.name,
            branchTimezone: selectedBranch.timezone,
            branchCurrency: selectedBranch.currencyCode,
            voucherCode: selectedVoucher?.code,
            voucherDiscountPercent: selectedVoucher?.discountPercent,
            voucherDiscountAmount: discount > 0 ? discount : null,
            voucherReferenceId: selectedVoucher?.redemptionReferenceId,
            voucherRedemptionTxHash: selectedVoucher?.redemptionTxHash,
            voucherBlockchainTxHash: selectedVoucher?.redemptionTxHash,
            voucherIsSimulated: true,
          );

      if (selectedVoucher != null && authUser != null) {
        unawaited(() async {
          try {
            final receipt = await ref
                .read(userVouchersProvider(authUser.id).notifier)
                .consumeVoucherForOrder(
                  voucher: selectedVoucher,
                  order: newOrder,
                );
            if (receipt != null && receipt.txHash.isNotEmpty) {
              ref
                  .read(ordersProvider.notifier)
                  .updateOrderVoucherUsage(
                    orderId: newOrder.id,
                    usageTxHash: receipt.txHash,
                    isSimulated: receipt.isSimulated,
                  );
            }
          } catch (_) {}
        }());
      }

      if (newOrder.isConfirmed ||
          newOrder.paymentStatus == 'PAID' ||
          newOrder.paymentStatus == 'CONFIRMED') {
        unawaited(() async {
          try {
            await BlockchainReceiptService.instance.recordOrderReceipt(
              order: newOrder,
              cartItems: cartState.items,
            );
          } catch (e) {
            debugPrint('Automatic blockchain recording failed: $e');
          }
        }());
      }

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        context.go('/order-confirmed', extra: newOrder);
      }
    } catch (e) {
      debugPrint('Checkout failed to save order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Pesanan gagal disimpan. Periksa koneksi dan coba lagi.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cartState = ref.watch(cartProvider);
    final selectedBranch = ref.watch(branchProvider).selectedBranch;
    final authUser = ref.watch(authProvider).user;
    final voucherState = authUser != null
        ? ref.watch(userVouchersProvider(authUser.id))
        : const VoucherState();
    final selectedVoucher = voucherState.selectedVoucherForCheckout;

    final subtotal = cartState.subtotal;
    final discount = selectedVoucher != null
        ? selectedVoucher.calculateDiscount(subtotal)
        : 0;
    final discountedSubtotal = (subtotal - discount).clamp(0, subtotal);
    final tax = (discountedSubtotal * 0.1).round();
    final deliveryFee = _orderType == 'DELIVERY' ? 12000 : 0;
    final grandTotal = discountedSubtotal + tax + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(
          'CHECKOUT',
          style: textTheme.headlineMedium?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Selected Branch Header Card
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forestGreen.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: AppColors.butterYellow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'FULFILLMENT ATELIER',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.butterYellow,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => BranchSelectionBottomSheet.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ubah Cabang',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedBranch.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${selectedBranch.displayLocation} • ${selectedBranch.timezoneLabel} • ${selectedBranch.currencyLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () {
                        GoogleMapsService.openBranch(
                          query: selectedBranch.effectiveMapsQuery,
                          latitude: selectedBranch.latitude,
                          longitude: selectedBranch.longitude,
                          isVerified: selectedBranch.isVerified,
                          label: selectedBranch.name,
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_rounded,
                            size: 14,
                            color: AppColors.coral,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Buka di Google Maps',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.butterYellow,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1. Order Type Selector
              Text(
                'ORDER TYPE',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      title: 'Pick Up',
                      subtitle: 'At ${selectedBranch.city} Atelier',
                      icon: Icons.storefront_rounded,
                      isSelected: _orderType == 'PICKUP',
                      onTap: () => setState(() => _orderType = 'PICKUP'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      title: 'Delivery',
                      subtitle: 'Flat Rp 12.000',
                      icon: Icons.delivery_dining_rounded,
                      isSelected: _orderType == 'DELIVERY',
                      onTap: () => setState(() => _orderType = 'DELIVERY'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Delivery Address Form (If Delivery selected)
              if (_orderType == 'DELIVERY') ...[
                Text(
                  'DELIVERY ADDRESS',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    letterSpacing: 1.1,
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.coral,
                    ),
                    hintText: 'Enter complete street address...',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 2. Order Items Summary
              Text(
                'ITEMS SUMMARY (${cartState.items.length})',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    ...cartState.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.product.name}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rp ${item.totalPrice}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 18),

                    // ── Voucher & Promo Card ──
                    if (selectedVoucher != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF34A853),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: Color(0xFF137333),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${selectedVoucher.type.title} (${selectedVoucher.code})',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF137333),
                                      ),
                                    ),
                                    Text(
                                      'Hemat Rp $discount • Blockchain Verified',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: const Color(0xFF137333),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.grey,
                              ),
                              tooltip: 'Hapus voucher',
                              onPressed: () {
                                if (authUser != null) {
                                  ref
                                      .read(
                                        userVouchersProvider(authUser.id)
                                            .notifier,
                                      )
                                      .clearSelectedVoucher();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _promoController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Ketik Kode Promo (BUN...)',
                                  hintStyle: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedText,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.local_offer_outlined,
                                    size: 16,
                                    color: AppColors.coral,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () =>
                                  _handleApplyPromo(context, ref, authUser?.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              child: const Text(
                                'GUNAKAN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _openVoucherPicker(
                            context,
                            ref,
                            voucherState.availableVouchers,
                            authUser?.id,
                          ),
                          icon: const Icon(
                            Icons.confirmation_number_outlined,
                            size: 16,
                            color: AppColors.coral,
                          ),
                          label: Text(
                            'Pilih dari Voucher Saya (${voucherState.availableVouchers.length} tersedia)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                        Text(
                          'Rp $subtotal',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (selectedVoucher != null && discount > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Diskon Voucher (${selectedVoucher.discountPercent}%)',
                            style: const TextStyle(
                              color: Color(0xFF137333),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '-Rp $discount',
                            style: const TextStyle(
                              color: Color(0xFF137333),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Restaurant Tax (10%)',
                          style: TextStyle(color: AppColors.mutedText),
                        ),
                        Text(
                          'Rp $tax',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (_orderType == 'DELIVERY') ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Fee',
                            style: TextStyle(color: AppColors.mutedText),
                          ),
                          Text(
                            'Rp $deliveryFee',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Rp $grandTotal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.coral,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Multi-Currency Indicative Conversion (Automatic by Selected Branch)
              CheckoutCurrencyCard(
                totalInIdr: grandTotal,
                branch: selectedBranch,
              ),
              const SizedBox(height: 28),

              // 4. Official Payment Method Selection
              Text(
                'METODE PEMBAYARAN',
                style: textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '🔒 Pembayaran terenkripsi & verifikasi instan otomatis.',
                style: TextStyle(fontSize: 11, color: AppColors.mutedText),
              ),
              const SizedBox(height: 12),

              _buildPaymentRadio(
                id: 'QRIS',
                title: 'QRIS Dinamis (Semua Bank & E-Wallet)',
                subtitle: 'Scan langsung dari BCA, Mandiri, GoPay, OVO, DANA',
                icon: Icons.qr_code_scanner_rounded,
              ),
              const SizedBox(height: 8),
              _buildPaymentRadio(
                id: 'EWALLET',
                title: 'Dompet Digital (E-Wallet)',
                subtitle: 'GoPay, OVO, ShopeePay, DANA terverifikasi instan',
                icon: Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 8),
              _buildPaymentRadio(
                id: 'CASHIER',
                title: 'Bayar Langsung di Kasir',
                subtitle:
                    'Tunai (Cash) atau Kartu Debit/Kredit EDC saat pick-up',
                icon: Icons.point_of_sale_rounded,
              ),
              const SizedBox(height: 28),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handlePlaceOrder,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text('PLACE ORDER — RP $grandTotal'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.butterYellow.withValues(alpha: 0.3)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.coral : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.coral : AppColors.mutedText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRadio({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.butterYellow.withValues(alpha: 0.3)
              : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.forestGreen : AppColors.borderLight,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.forestGreen : AppColors.mutedText,
              size: 20,
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.forestGreen.withValues(alpha: 0.1)
                    : AppColors.creamDarker,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.forestGreen : AppColors.espresso,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
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
      ),
    );
  }

  Future<void> _handleApplyPromo(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk menggunakan voucher diskon.'),
        ),
      );
      return;
    }

    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan masukkan kode voucher terlebih dahulu.'),
        ),
      );
      return;
    }

    try {
      final voucher = await ref
          .read(userVouchersProvider(userId).notifier)
          .applyPromoCode(code);
      _promoController.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF137333),
            content: Text(
              'Voucher ${voucher.type.title} (${voucher.code}) berhasil diterapkan!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              e
                  .toString()
                  .replaceAll('Exception: ', '')
                  .replaceAll('Bad state: ', ''),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _openVoucherPicker(
    BuildContext context,
    WidgetRef ref,
    List<VoucherModel> availableVouchers,
    String? userId,
  ) {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk melihat voucher milik Anda.'),
        ),
      );
      return;
    }

    if (availableVouchers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada voucher tersedia. Tukarkan Bun Points Anda di menu Rewards!',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PILIH VOUCHER ANDA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forestGreen,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(bctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih satu voucher untuk mendapatkan potongan harga pada pesanan ini.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: availableVouchers.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final v = availableVouchers[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${v.discountPercent}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.type.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'Kode: ${v.code} • Berlaku s/d ${v.formattedExpiry}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(userVouchersProvider(userId).notifier)
                                    .selectVoucherForCheckout(v);
                                Navigator.pop(bctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF137333),
                                    content: Text(
                                      'Voucher ${v.type.title} berhasil diterapkan!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.forestGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'PILIH',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
