import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../branch/models/branch_model.dart';
import '../../../converter/services/currency_service.dart';

class CheckoutCurrencyCard extends StatefulWidget {
  final int totalInIdr;
  final BranchModel? branch;

  const CheckoutCurrencyCard({
    super.key,
    required this.totalInIdr,
    this.branch,
  });

  @override
  State<CheckoutCurrencyCard> createState() => _CheckoutCurrencyCardState();
}

class _CheckoutCurrencyCardState extends State<CheckoutCurrencyCard> {
  bool _isLoading = false;
  Map<String, double> _rates = {};

  String get _branchCurrency => (widget.branch?.currencyCode ?? 'IDR').toUpperCase();
  bool get _isForeign => _branchCurrency != 'IDR';

  @override
  void initState() {
    super.initState();
    if (_isForeign) {
      _loadRates();
    }
  }

  @override
  void didUpdateWidget(covariant CheckoutCurrencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch?.currencyCode != widget.branch?.currencyCode && _isForeign) {
      _loadRates();
    }
  }

  Future<void> _loadRates({bool force = false}) async {
    setState(() => _isLoading = true);
    try {
      final rates = await CurrencyService.instance.fetchRatesVsUsd(forceRefresh: force);
      if (mounted) {
        setState(() {
          _rates = rates;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rates = CurrencyService.instance.cachedRates;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final formattedIdr = NumberFormat('#,##0', 'id_ID').format(widget.totalInIdr);
    final targetInfo = CurrencyService.instance.getCurrency(_branchCurrency);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.warmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.sandBeige,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with automatic branch badge (No manual dropdowns or chips)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (_isForeign ? AppColors.burgundy : AppColors.forestGreen).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isForeign ? Icons.currency_exchange_rounded : Icons.payments_rounded,
                  color: _isForeign ? AppColors.burgundy : AppColors.forestGreen,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isForeign
                          ? 'KONVERSI MATA UANG OTOMATIS: ${(widget.branch?.city ?? _branchCurrency).toUpperCase()}'
                          : 'MATA UANG CABANG: INDONESIA',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        color: _isForeign ? AppColors.burgundy : AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isForeign
                          ? 'Disesuaikan otomatis dengan lokasi cabang ${widget.branch?.name ?? ''}'
                          : 'Transaksi resmi diproses langsung dalam Rupiah (IDR)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              // Branch Country Badge (Pure indicator, no manual picker)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTile : AppColors.sandBeige.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sandBeige),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(targetInfo.flag, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      targetInfo.code,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: isDark ? Colors.white : AppColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Main Display: Foreign Auto-Conversion vs Indonesia IDR
          if (_isForeign) ...[
            _buildForeignConversionBox(context, isDark, formattedIdr, targetInfo),
          ] else ...[
            _buildDomesticIdrBox(context, isDark, formattedIdr),
          ],

          const SizedBox(height: 12),

          // Receipt Integration Note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isForeign
                        ? 'Nilai konversi ${targetInfo.code} (${targetInfo.symbol}) akan dicantumkan otomatis pada E-Receipt resmi.'
                        : 'E-Receipt resmi pesanan akan diterbitkan langsung dalam mata uang Rupiah (IDR).',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 18),

          // Disclaimer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.mutedText),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _isForeign
                      ? 'Perkiraan konversi otomatis wilayah. Pembayaran akhir pesanan tetap diproses dalam IDR.'
                      : 'Cabang wilayah Indonesia menggunakan mata uang Rupiah (IDR) secara penuh.',
                  style: GoogleFonts.dmSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildForeignConversionBox(
    BuildContext context,
    bool isDark,
    String formattedIdr,
    CurrencyInfo targetInfo,
  ) {
    final conversion = CurrencyService.instance.convert(
      amount: widget.totalInIdr.toDouble(),
      fromCurrency: 'IDR',
      toCurrency: _branchCurrency,
      ratesVsUsd: _rates.isNotEmpty ? _rates : null,
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkTile : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.sandBeige.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              // Source IDR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IDR — Rupiah',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rp $formattedIdr',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.darkBrown,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.sandBeige.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.burgundy),
              ),

              const SizedBox(width: 12),

              // Target Converted
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${targetInfo.code} — ${targetInfo.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.burgundy),
                          )
                        : Text(
                            '${targetInfo.symbol} ${conversion.formattedTarget}',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.burgundy,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Rate Source note
        Row(
          children: [
            Icon(
              conversion.isLive
                  ? Icons.sensors_rounded
                  : (conversion.isCached ? Icons.schedule_rounded : Icons.offline_bolt_outlined),
              size: 12,
              color: conversion.isLive ? AppColors.forestGreen : AppColors.mutedText,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                conversion.rateInfoText,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.mutedText,
                ),
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.burgundy),
              ),
          ],
        ),

        if (conversion.isCached) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 11, color: AppColors.coral),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Data kurs dari cache (mungkin tidak real-time).',
                  style: GoogleFonts.dmSans(fontSize: 9.5, color: AppColors.coral),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDomesticIdrBox(
    BuildContext context,
    bool isDark,
    String formattedIdr,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkTile : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.sandBeige.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mata Uang Transaksi',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Text('🇮🇩', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 5),
                  Text(
                    'IDR — Rupiah Indonesia',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.darkBrown,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Pembayaran',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Rp $formattedIdr',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forestGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
