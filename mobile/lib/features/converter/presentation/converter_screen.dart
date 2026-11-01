import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../services/currency_service.dart';

class ZoneInfo {
  final String id;
  final String city;
  final String country;
  final String flag;
  final int utcOffsetHours;
  final String code;
  final bool hasDst;

  const ZoneInfo({
    required this.id,
    required this.city,
    required this.country,
    required this.flag,
    required this.utcOffsetHours,
    required this.code,
    this.hasDst = false,
  });
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _liveClockTimer;

  // Currencies list
  static const List<CurrencyInfo> currencies = [
    CurrencyInfo(code: 'IDR', name: 'Rupiah Indonesia', symbol: 'Rp', flag: '🇮🇩', benchmarkToIdr: 1.0),
    CurrencyInfo(code: 'USD', name: 'US Dollar', symbol: '\$', flag: '🇺🇸', benchmarkToIdr: 16100.0),
    CurrencyInfo(code: 'EUR', name: 'Euro', symbol: '€', flag: '🇪🇺', benchmarkToIdr: 17250.0),
    CurrencyInfo(code: 'SGD', name: 'Singapore Dollar', symbol: 'S\$', flag: '🇸🇬', benchmarkToIdr: 12200.0),
    CurrencyInfo(code: 'MYR', name: 'Malaysian Ringgit', symbol: 'RM', flag: '🇲🇾', benchmarkToIdr: 3750.0),
    CurrencyInfo(code: 'JPY', name: 'Japanese Yen', symbol: '¥', flag: '🇯🇵', benchmarkToIdr: 106.0),
    CurrencyInfo(code: 'GBP', name: 'British Pound', symbol: '£', flag: '🇬🇧', benchmarkToIdr: 20800.0),
    CurrencyInfo(code: 'AUD', name: 'Australian Dollar', symbol: 'A\$', flag: '🇦🇺', benchmarkToIdr: 10700.0),
    CurrencyInfo(code: 'SAR', name: 'Saudi Riyal', symbol: 'SR', flag: '🇸🇦', benchmarkToIdr: 4290.0),
    CurrencyInfo(code: 'THB', name: 'Thai Baht', symbol: '฿', flag: '🇹🇭', benchmarkToIdr: 470.0),
    CurrencyInfo(code: 'KRW', name: 'South Korean Won', symbol: '₩', flag: '🇰🇷', benchmarkToIdr: 11.8),
    CurrencyInfo(code: 'CNY', name: 'Chinese Yuan', symbol: '¥', flag: '🇨🇳', benchmarkToIdr: 2260.0),
  ];

  // Global Timezones list
  static const List<ZoneInfo> timezones = [
    ZoneInfo(id: 'jkt', city: 'Jakarta (WIB)', country: 'Indonesia', flag: '🇮🇩', utcOffsetHours: 7, code: 'WIB'),
    ZoneInfo(id: 'dps', city: 'Bali / Makassar (WITA)', country: 'Indonesia', flag: '🇮🇩', utcOffsetHours: 8, code: 'WITA'),
    ZoneInfo(id: 'djj', city: 'Jayapura (WIT)', country: 'Indonesia', flag: '🇮🇩', utcOffsetHours: 9, code: 'WIT'),
    ZoneInfo(id: 'sin', city: 'Singapore', country: 'Singapore', flag: '🇸🇬', utcOffsetHours: 8, code: 'SGT'),
    ZoneInfo(id: 'kul', city: 'Kuala Lumpur', country: 'Malaysia', flag: '🇲🇾', utcOffsetHours: 8, code: 'MYT'),
    ZoneInfo(id: 'tyo', city: 'Tokyo', country: 'Jepang', flag: '🇯🇵', utcOffsetHours: 9, code: 'JST'),
    ZoneInfo(id: 'sel', city: 'Seoul', country: 'Korea Selatan', flag: '🇰🇷', utcOffsetHours: 9, code: 'KST'),
    ZoneInfo(id: 'syd', city: 'Sydney', country: 'Australia', flag: '🇦🇺', utcOffsetHours: 11, code: 'AEDT', hasDst: true),
    ZoneInfo(id: 'lon', city: 'London', country: 'Inggris', flag: '🇬🇧', utcOffsetHours: 1, code: 'BST', hasDst: true),
    ZoneInfo(id: 'par', city: 'Paris / Berlin', country: 'Eropa Barat', flag: '🇫🇷', utcOffsetHours: 2, code: 'CEST', hasDst: true),
    ZoneInfo(id: 'dxb', city: 'Dubai', country: 'Uni Emirat Arab', flag: '🇦🇪', utcOffsetHours: 4, code: 'GST'),
    ZoneInfo(id: 'ruh', city: 'Riyadh / Mekkah', country: 'Arab Saudi', flag: '🇸🇦', utcOffsetHours: 3, code: 'AST'),
    ZoneInfo(id: 'nyc', city: 'New York', country: 'Amerika Serikat (Timur)', flag: '🇺🇸', utcOffsetHours: -4, code: 'EDT', hasDst: true),
    ZoneInfo(id: 'lax', city: 'Los Angeles', country: 'Amerika Serikat (Barat)', flag: '🇺🇸', utcOffsetHours: -7, code: 'PDT', hasDst: true),
    ZoneInfo(id: 'bkk', city: 'Bangkok', country: 'Thailand', flag: '🇹🇭', utcOffsetHours: 7, code: 'ICT'),
  ];

  // Currency State
  final _amountController = TextEditingController(text: '75000');
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double _convertedResult = 0.0;
  String _rateInfo = 'Mengambil data kurs terbaru...';
  bool _isLoadingRate = false;
  Map<String, double> _liveRatesVsUsd = {};

  // Timezone State
  TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  DateTime _selectedDate = DateTime.now();
  String _fromZoneId = 'jkt';
  String _toZoneId = 'lon';
  DateTime _currentUtc = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initial calculation
    _fetchLiveRatesAndCalculate();

    // Start live clock ticker
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentUtc = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _liveClockTimer?.cancel();
    super.dispose();
  }

  CurrencyInfo _getCurrency(String code) {
    return currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => currencies.first,
    );
  }

  ZoneInfo _getZone(String id) {
    return timezones.firstWhere(
      (z) => z.id == id,
      orElse: () => timezones.first,
    );
  }

  Future<void> _fetchLiveRatesAndCalculate() async {
    final input = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '').trim()) ?? 0.0;
    if (input <= 0) {
      setState(() => _convertedResult = 0.0);
      return;
    }

    setState(() => _isLoadingRate = true);

    try {
      final rates = await CurrencyService.instance.fetchRatesVsUsd();
      _liveRatesVsUsd = rates;
      _computeConversion(input, isLive: CurrencyService.instance.lastSource == RateSource.live);
    } catch (_) {
      // Fallback using benchmark constants
      _computeConversion(input, isLive: false);
    }
  }

  void _computeConversion(double input, {required bool isLive}) {
    final fromInfo = _getCurrency(_fromCurrency);
    final toInfo = _getCurrency(_toCurrency);

    double result = 0.0;
    String info = '';

    if ((isLive || CurrencyService.instance.lastSource == RateSource.cache) &&
        _liveRatesVsUsd.containsKey(_fromCurrency) &&
        _liveRatesVsUsd.containsKey(_toCurrency)) {
      // Formula: from -> USD -> to
      final fromRateUsd = _liveRatesVsUsd[_fromCurrency]!;
      final toRateUsd = _liveRatesVsUsd[_toCurrency]!;
      // 1 USD = fromRateUsd (e.g. 16000 IDR)
      // amountInUsd = input / fromRateUsd
      // result = amountInUsd * toRateUsd
      result = (input / fromRateUsd) * toRateUsd;
      final cross = toRateUsd / fromRateUsd;
      final tag = CurrencyService.instance.lastSource == RateSource.cache
          ? '(Data Kurs Tersimpan / Cache)'
          : '(Frankfurter Live)';
      info = '1 $_fromCurrency ≈ ${cross < 0.01 ? cross.toStringAsFixed(6) : cross.toStringAsFixed(4)} $_toCurrency $tag';
    } else {
      // Benchmark fallback
      // Convert to IDR first, then to target
      final amountInIdr = input * fromInfo.benchmarkToIdr;
      result = amountInIdr / toInfo.benchmarkToIdr;
      final cross = fromInfo.benchmarkToIdr / toInfo.benchmarkToIdr;
      info = '1 $_fromCurrency ≈ ${cross < 0.01 ? cross.toStringAsFixed(6) : cross.toStringAsFixed(4)} $_toCurrency (Benchmark Offline)';
    }

    setState(() {
      _convertedResult = result;
      _rateInfo = info;
      _isLoadingRate = false;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _fetchLiveRatesAndCalculate();
  }

  void _swapZones() {
    setState(() {
      final temp = _fromZoneId;
      _fromZoneId = _toZoneId;
      _toZoneId = temp;
    });
  }

  String _formatAmount(double value, String currencyCode) {
    if (currencyCode == 'IDR' || currencyCode == 'KRW' || currencyCode == 'JPY') {
      return NumberFormat('#,##0', 'id_ID').format(value.round());
    }
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }

  DateTime _getTargetDateTime() {
    final fromZone = _getZone(_fromZoneId);
    final toZone = _getZone(_toZoneId);

    // Source DateTime constructed from input
    final sourceDt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    // Convert source to UTC
    final utcDt = sourceDt.subtract(Duration(hours: fromZone.utcOffsetHours));

    // Convert UTC to target
    final targetDt = utcDt.add(Duration(hours: toZone.utcOffsetHours));
    return targetDt;
  }

  String _getDayDifferenceDescription(DateTime target) {
    final sourceDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final targetDate = DateTime(target.year, target.month, target.day);
    final diffDays = targetDate.difference(sourceDate).inDays;

    if (diffDays == 0) return 'Hari yang sama';
    if (diffDays == 1) return '+1 Hari (Besok)';
    if (diffDays == -1) return '-1 Hari (Kemarin)';
    if (diffDays > 1) return '+$diffDays Hari ke depan';
    return '$diffDays Hari sebelumnya';
  }

  String _getFoodEquivalency(double idrAmount) {
    if (idrAmount < 30000) {
      return 'Setara dengan 1 porsi French Fries / Minuman Dingin 🍟';
    } else if (idrAmount < 70000) {
      return 'Cukup untuk 1 porsi OG Main Character Burger! 🍔';
    } else if (idrAmount < 150000) {
      return 'Bisa untuk Combo Burger + Sides + Drink lengkap! 🍔🍟🥤';
    } else {
      final burgerCount = (idrAmount / 65000).floor();
      return 'Bisa traktir $burgerCount porsi Burger Bun Atelier bareng teman! 🎉';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: Text(
          'GLOBAL CONVERTER',
          style: GoogleFonts.dmSans(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: AppColors.cream,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.butterYellow,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.butterYellow,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.currency_exchange_rounded),
              text: 'KURS MATA UANG',
            ),
            Tab(
              icon: Icon(Icons.public_rounded),
              text: 'JAM & ZONA DUNIA',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCurrencyTab(),
            _buildTimezoneTab(),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: CURRENCY CONVERTER
  // -------------------------------------------------------------
  Widget _buildCurrencyTab() {
    final fromCurrencyInfo = _getCurrency(_fromCurrency);
    final toCurrencyInfo = _getCurrency(_toCurrency);

    // Calculate equivalent IDR for food tip
    final rawInput = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '').trim()) ?? 0.0;
    final currentIdrValue = _fromCurrency == 'IDR'
        ? rawInput
        : rawInput * fromCurrencyInfo.benchmarkToIdr;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange_rounded, color: AppColors.butterYellow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konversi Mata Uang Global',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kurs live real-time via Frankfurter API untuk 12 mata uang dunia.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Main Conversion Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBCE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JUMLAH NOMINAL',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.espresso.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      fromCurrencyInfo.symbol,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Amount Input
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _fetchLiveRatesAndCalculate(),
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.forestGreen,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Text(
                        fromCurrencyInfo.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    filled: true,
                    fillColor: const Color(0xFFF9F6F0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFEADBCE)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.coral, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Quick Amount Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: (_fromCurrency == 'IDR'
                            ? [25000, 50000, 75000, 100000, 250000, 500000]
                            : [5, 10, 25, 50, 100, 250])
                        .map((amount) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(
                            _fromCurrency == 'IDR'
                                ? 'Rp ${(amount / 1000).toInt()}K'
                                : '${fromCurrencyInfo.symbol}$amount',
                            style: GoogleFonts.dmSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forestGreen,
                            ),
                          ),
                          backgroundColor: const Color(0xFFF4EDE2),
                          side: BorderSide.none,
                          onPressed: () {
                            setState(() {
                              _amountController.text = amount.toString();
                            });
                            _fetchLiveRatesAndCalculate();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Currency Selectors & Swap Button
                Row(
                  children: [
                    // FROM
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DARI',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _fromCurrency,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.coral),
                                items: currencies.map((c) {
                                  return DropdownMenuItem(
                                    value: c.code,
                                    child: Row(
                                      children: [
                                        Text(c.flag, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.code,
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.forestGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _fromCurrency = val);
                                    _fetchLiveRatesAndCalculate();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SWAP BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: InkWell(
                        onTap: _swapCurrencies,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),

                    // TO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KE',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _toCurrency,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.coral),
                                items: currencies.map((c) {
                                  return DropdownMenuItem(
                                    value: c.code,
                                    child: Row(
                                      children: [
                                        Text(c.flag, style: const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.code,
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: AppColors.forestGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _toCurrency = val);
                                    _fetchLiveRatesAndCalculate();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Color(0xFFEADBCE)),
                const SizedBox(height: 14),

                // Converted Result Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'HASIL KONVERSI',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      toCurrencyInfo.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                _isLoadingRate
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.coral)),
                            SizedBox(width: 10),
                            Text('Menghitung kurs live...'),
                          ],
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            toCurrencyInfo.symbol,
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.coral,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _formatAmount(_convertedResult, _toCurrency),
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 34,
                                color: AppColors.forestGreen,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 10),

                // Rate details badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EADC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.forestGreen),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _rateInfo,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Restaurant Food Equivalency Tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7D58C).withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5B962)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ekuivalensi Kuliner Bun Atelier:',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.espresso,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFoodEquivalency(currentIdrValue),
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Multi-Currency Quick Board
          Text(
            'KURS POPULER LAINNYA',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppColors.espresso.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildMultiCurrencyBoard(rawInput),
        ],
      ),
    );
  }

  Widget _buildMultiCurrencyBoard(double input) {
    if (input <= 0) return const SizedBox.shrink();

    final targetCodes = ['USD', 'EUR', 'SGD', 'JPY', 'MYR', 'GBP'];
    final fromInfo = _getCurrency(_fromCurrency);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: targetCodes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (ctx, idx) {
        final code = targetCodes[idx];
        final curr = _getCurrency(code);
        double converted = 0.0;

        if (_liveRatesVsUsd.containsKey(_fromCurrency) && _liveRatesVsUsd.containsKey(code)) {
          final fromRateUsd = _liveRatesVsUsd[_fromCurrency]!;
          final toRateUsd = _liveRatesVsUsd[code]!;
          converted = (input / fromRateUsd) * toRateUsd;
        } else {
          final inIdr = input * fromInfo.benchmarkToIdr;
          converted = inIdr / curr.benchmarkToIdr;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEADBCE)),
          ),
          child: Row(
            children: [
              Text(curr.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      code,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.espresso.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      '${curr.symbol} ${_formatAmount(converted, code)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forestGreen,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // -------------------------------------------------------------
  // TAB 2: TIMEZONE & WORLD CLOCK
  // -------------------------------------------------------------
  Widget _buildTimezoneTab() {
    final fromZone = _getZone(_fromZoneId);
    final toZone = _getZone(_toZoneId);
    final targetDateTime = _getTargetDateTime();

    final targetTimeString = DateFormat('HH:mm').format(targetDateTime);
    final targetTime12String = DateFormat('hh:mm a').format(targetDateTime);
    final targetDateString = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(targetDateTime);

    final hourDiff = toZone.utcOffsetHours - fromZone.utcOffsetHours;
    final diffText = hourDiff == 0
        ? 'Zona waktu sama'
        : hourDiff > 0
            ? '${toZone.city} lebih cepat $hourDiff jam dari ${fromZone.city}'
            : '${toZone.city} lebih lambat ${hourDiff.abs()} jam dari ${fromZone.city}';

    // Restaurant open check (10:00 - 22:00)
    final isOpen = targetDateTime.hour >= 10 && targetDateTime.hour < 22;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, color: AppColors.butterYellow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jam Dunia & Konversi Zona',
                        style: GoogleFonts.dmSerifDisplay(
                          fontSize: 18,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menghitung perbedaan jam kota-kota kuliner dunia secara akurat.',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Interactive Converter Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEADBCE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Time Picker Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JAM & TANGGAL INPUT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.espresso.withValues(alpha: 0.7),
                        letterSpacing: 1.0,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          final now = DateTime.now();
                          _selectedDate = now;
                          _selectedTime = TimeOfDay.fromDateTime(now);
                        });
                      },
                      icon: const Icon(Icons.restart_alt_rounded, size: 14, color: AppColors.coral),
                      label: Text(
                        'Waktu Sekarang',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.coral,
                        ),
                      ),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Selected Time Tile
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEADBCE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: AppColors.coral, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              style: GoogleFonts.dmSerifDisplay(
                                fontSize: 26,
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2EADC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ubah Jam',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Source and Target Zone Selectors
                Row(
                  children: [
                    // FROM ZONE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ZONA ASAL',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _fromZoneId,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.coral),
                                items: timezones.map((z) {
                                  return DropdownMenuItem(
                                    value: z.id,
                                    child: Row(
                                      children: [
                                        Text(z.flag, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            z.city,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forestGreen,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _fromZoneId = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SWAP BUTTON
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: InkWell(
                        onTap: _swapZones,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ),

                    // TO ZONE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ZONA TUJUAN',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.mutedText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEADBCE)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _toZoneId,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.coral),
                                items: timezones.map((z) {
                                  return DropdownMenuItem(
                                    value: z.id,
                                    child: Row(
                                      children: [
                                        Text(z.flag, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            z.city,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.forestGreen,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _toZoneId = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(color: Color(0xFFEADBCE)),
                const SizedBox(height: 14),

                // Converted Time Result Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'WAKTU DI ZONA TUJUAN',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.mutedText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getDayDifferenceDescription(targetDateTime).contains('+')
                            ? const Color(0xFFF7D58C)
                            : const Color(0xFFF2EADC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getDayDifferenceDescription(targetDateTime),
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      targetTimeString,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.forestGreen,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($targetTime12String)',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      toZone.code,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.coral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  targetDateString,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.espresso.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),

                // Difference Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEADBCE)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        toZone.utcOffsetHours >= fromZone.utcOffsetHours
                            ? Icons.fast_forward_rounded
                            : Icons.fast_rewind_rounded,
                        size: 16,
                        color: AppColors.coral,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          diffText,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Restaurant status in target zone
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen
                          ? 'Outlet Bun Atelier di ${toZone.city}: BUKA (Pukul 10:00 - 22:00)'
                          : 'Outlet Bun Atelier di ${toZone.city}: TUTUP (Buka kembali pkl 10:00)',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOpen ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // LIVE WORLD CLOCK SECTION
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE WORLD CLOCK (JAM DUNIA)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.espresso.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Real-time',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildLiveWorldClockGrid(),
        ],
      ),
    );
  }

  Widget _buildLiveWorldClockGrid() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timezones.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final zone = timezones[idx];
        final localDateTime = _currentUtc.add(Duration(hours: zone.utcOffsetHours));
        final timeStr = DateFormat('HH:mm:ss').format(localDateTime);
        final dateStr = DateFormat('EEE, d MMM', 'id_ID').format(localDateTime);
        final isDay = localDateTime.hour >= 6 && localDateTime.hour < 18;

        return InkWell(
          onTap: () {
            setState(() {
              _toZoneId = zone.id;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Target zona diatur ke ${zone.city}'),
                duration: const Duration(seconds: 1),
                backgroundColor: AppColors.forestGreen,
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: zone.id == _toZoneId ? AppColors.coral : const Color(0xFFEADBCE),
                width: zone.id == _toZoneId ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Text(zone.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              zone.city,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.forestGreen,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            zone.hasDst ? 'DST ${zone.code}' : zone.code,
                            style: GoogleFonts.dmSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.coral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr • UTC${zone.utcOffsetHours >= 0 ? '+${zone.utcOffsetHours}' : zone.utcOffsetHours}',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          isDay ? '☀️' : '🌙',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.forestGreen,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      zone.id == _toZoneId ? 'Target Aktif' : 'Tap to convert',
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: zone.id == _toZoneId ? AppColors.coral : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
