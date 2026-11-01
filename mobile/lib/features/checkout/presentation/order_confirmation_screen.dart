import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../orders/models/order_model.dart';
import '../../orders/services/receipt_download_service.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final OrderItemModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;

  OrderItemModel get order => widget.order;

  Future<void> _downloadReceipt() async {
    if (_isDownloading) return;

    if (!order.isConfirmed) {
      _showFeedback(
        message:
            'E-Receipt hanya dapat diunduh untuk pesanan yang telah berstatus Confirmed.',
        isSuccess: false,
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // 1. Render receipt widget to high-res PNG image
      final pngBytes =
          await ReceiptDownloadService.instance.captureReceiptPng(_receiptKey);

      if (pngBytes == null || pngBytes.isEmpty) {
        if (!mounted) return;
        _showFeedback(
          message:
              'Gagal merender e-receipt menjadi gambar. Silakan coba lagi.',
          isSuccess: false,
        );
        return;
      }

      // 2. Save directly to native Photo Gallery using Gal
      final result = await ReceiptDownloadService.instance.saveReceiptToGallery(
        imageBytes: pngBytes,
        orderNumber: order.orderNumber,
      );

      if (!mounted) return;
      _showFeedback(
        message: result.message,
        isSuccess: result.isSuccess,
      );
    } catch (e) {
      if (!mounted) return;
      _showFeedback(
        message: 'Terjadi kesalahan saat menyimpan e-receipt: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showFeedback({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isSuccess ? AppColors.forestGreen : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_rounded
                  : Icons.error_outline_rounded,
              color: AppColors.cream,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.cream,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isConfirmed = order.isConfirmed;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: Navigator.of(context).canPop()
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.espresso),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'E-RECEIPT',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.espresso,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Success Indicator
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isConfirmed
                        ? AppColors.forestGreen
                        : Colors.orange.shade800,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isConfirmed
                                ? AppColors.forestGreen
                                : Colors.orange)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    isConfirmed ? Icons.check_rounded : Icons.hourglass_top_rounded,
                    color: AppColors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  isConfirmed ? 'Order Confirmed!' : 'Order Placed',
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isConfirmed
                      ? 'The kitchen has received your order and the grill is fired up.'
                      : 'Pesanan Anda telah masuk dan menunggu konfirmasi dari pihak dapur.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 24),

                // ── RepaintBoundary: E-Receipt Card for Export ──────────────
                RepaintBoundary(
                  key: _receiptKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 22),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.espresso.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Logo & Brand Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/splash/splash_frame_1.png',
                              height: 42,
                              width: 42,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.lunch_dining_rounded,
                                color: AppColors.coral,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUN ATELIER',
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.2,
                                    color: AppColors.forestGreen,
                                    fontSize: 17,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: AppColors.coral.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'WORTH THE MESS.',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: AppColors.coral,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (order.branchName != null &&
                            order.branchName!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            order.branchName!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),
                        _buildDottedDivider(),
                        const SizedBox(height: 14),

                        // 2. Order Number & Transaction ID
                        Text(
                          'ORDER NUMBER',
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mutedText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.orderNumber,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.coral,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 12),

                        // 3. Transaction Details
                        _buildReceiptRow(
                          'Jenis Pesanan',
                          order.orderType == 'PICKUP' ? 'Pick Up' : 'Delivery',
                        ),
                        if (order.deliveryAddress != null &&
                            order.deliveryAddress!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildReceiptRow(
                            'Alamat Antar',
                            order.deliveryAddress!,
                          ),
                        ],
                        const SizedBox(height: 6),
                        _buildReceiptRow(
                          'Waktu Transaksi',
                          order.formattedTransactionTime(),
                        ),
                        const SizedBox(height: 6),
                        _buildReceiptRow(
                          'Metode Pembayaran',
                          '${order.paymentMethod} (${order.paymentStatus})',
                        ),
                        const SizedBox(height: 6),
                        _buildReceiptRow(
                          'Status Pesanan',
                          order.status,
                          highlightColor: isConfirmed
                              ? AppColors.forestGreen
                              : Colors.orange.shade800,
                        ),

                        const SizedBox(height: 14),
                        _buildDottedDivider(),
                        const SizedBox(height: 12),

                        // 4. Items Ordered List
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DAFTAR PESANAN',
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._buildItemsList(order.itemsSummary),

                        const SizedBox(height: 12),
                        _buildDottedDivider(),
                        const SizedBox(height: 12),

                        // 5. Financial Breakdown
                        _buildReceiptRow(
                          'Subtotal',
                          order.formattedSubtotal,
                        ),
                        if (order.hasVoucher) ...[
                          const SizedBox(height: 6),
                          _buildReceiptRow(
                            'Diskon Voucher (${order.voucherCode ?? ''})',
                            '-${order.formattedVoucherDiscount}',
                            highlightColor: const Color(0xFF137333),
                          ),
                        ],
                        if (order.tax > 0) ...[
                          const SizedBox(height: 6),
                          _buildReceiptRow(
                            'Pajak PB1 (10%)',
                            order.formattedTax,
                          ),
                        ],
                        if (order.deliveryFee > 0) ...[
                          const SizedBox(height: 6),
                          _buildReceiptRow(
                            'Ongkos Kirim',
                            order.formattedDeliveryFee,
                          ),
                        ],
                        const SizedBox(height: 10),
                        const Divider(
                          height: 1,
                          thickness: 1.4,
                          color: AppColors.espresso,
                        ),
                        const SizedBox(height: 10),
                        _buildReceiptRow(
                          'TOTAL PEMBAYARAN',
                          order.formattedTotal,
                          isBold: true,
                          highlightColor: AppColors.forestGreen,
                          fontSize: 16,
                        ),
                        if (order.isForeignCurrency) ...[
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Setara Nilai Asal (IDR)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.mutedText,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                order.formattedIdrTotal,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Regional Currency Details on Receipt
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.sandBeige),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(order.currencyFlag,
                                        style: const TextStyle(fontSize: 14)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'KONVERSI MATA UANG: ${order.effectiveCurrencyCode}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                          color: AppColors.forestGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Disesuaikan otomatis sesuai wilayah ${order.branchName ?? ''}',
                                  style: const TextStyle(
                                      fontSize: 9.5, color: AppColors.mutedText),
                                ),
                                if (order.branchExchangeRateInfo != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    'Kurs acuan: ${order.branchExchangeRateInfo}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.forestGreen,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),
                        _buildDottedDivider(),
                        const SizedBox(height: 10),

                        // 6. Footer Note
                        Text(
                          'Bukti transaksi resmi telah diamankan dalam Bun Atelier Blockchain Ledger',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.mutedText.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── 3. Download E-Receipt Button ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConfirmed
                          ? AppColors.forestGreen
                          : AppColors.borderLight,
                      foregroundColor:
                          isConfirmed ? AppColors.white : AppColors.mutedText,
                      elevation: isConfirmed ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (isConfirmed && !_isDownloading)
                        ? _downloadReceipt
                        : null,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.white,
                            ),
                          )
                        : Icon(
                            isConfirmed
                                ? Icons.download_rounded
                                : Icons.lock_outline_rounded,
                            size: 22,
                          ),
                    label: Text(
                      _isDownloading
                          ? 'MENYIMPAN KE GALERI...'
                          : (isConfirmed
                              ? 'DOWNLOAD E-RECEIPT (SIMPAN KE GALERI)'
                              : 'E-RECEIPT BELUM TERSEDIA'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                if (!isConfirmed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'E-Receipt hanya dapat diunduh setelah pesanan dikonfirmasi.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Secondary Navigation Buttons
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.espresso,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go('/orders'),
                    child: const Text(
                      'LIHAT SEMUA PESANAN',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => context.go('/main'),
                    child: const Text(
                      'KEMBALI KE BERANDA',
                      style: TextStyle(
                        color: AppColors.coral,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItemsList(String summary) {
    if (summary.isEmpty) {
      return [
        const Text(
          '-',
          style: TextStyle(fontSize: 12.5, color: AppColors.espresso),
        )
      ];
    }

    final items = summary.split(',').map((s) => s.trim()).toList();
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 5, right: 8),
              child: Icon(Icons.circle, size: 5, color: AppColors.coral),
            ),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.espresso,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? highlightColor,
    double fontSize = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.mutedText,
            fontSize: fontSize - 0.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontSize: fontSize,
              color: highlightColor ??
                  (isBold ? AppColors.forestGreen : AppColors.espresso),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDottedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.2,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.borderLight),
              ),
            );
          }),
        );
      },
    );
  }
}
