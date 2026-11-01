import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../models/currency_info.dart';

export '../models/currency_info.dart';

class CurrencyService {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

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

  Map<String, double> _cachedRatesVsUsd = {};
  DateTime? _lastFetchTime;
  RateSource _lastSource = RateSource.benchmark;
  static const Duration _cacheDuration = Duration(minutes: 15);

  Map<String, double> get cachedRates => Map.unmodifiable(_cachedRatesVsUsd);
  RateSource get lastSource => _lastSource;
  DateTime? get lastFetchTime => _lastFetchTime;

  bool get isCacheValid {
    if (_cachedRatesVsUsd.isEmpty || _lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  @visibleForTesting
  void setCachedRatesForTesting(Map<String, double> rates) {
    _cachedRatesVsUsd = Map.from(rates);
    _lastFetchTime = DateTime.now();
  }

  CurrencyInfo getCurrency(String code) {
    return currencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => currencies.first,
    );
  }

  /// Fetches latest exchange rates with Frankfurter API as base=USD
  /// Caches the results for 15 minutes to prevent duplicate network hits.
  Future<Map<String, double>> fetchRatesVsUsd({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid) {
      _lastSource = RateSource.cache;
      return _cachedRatesVsUsd;
    }

    try {
      final dio = Dio();
      final url = '${ApiConstants.frankfurterBaseUrl}/latest?base=USD';
      final res = await dio.get(
        url,
        options: Options(
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

      if (res.statusCode == 200 && res.data is Map && res.data['rates'] is Map) {
        final rawRates = res.data['rates'] as Map<String, dynamic>;
        final Map<String, double> rates = {'USD': 1.0};
        rawRates.forEach((k, v) {
          if (v is num) rates[k] = v.toDouble();
        });

        // Benchmark fallback for SAR if not provided by Frankfurter
        if (!rates.containsKey('SAR') && rates.containsKey('USD')) {
          rates['SAR'] = 3.75;
        }

        _cachedRatesVsUsd = rates;
        _lastFetchTime = DateTime.now();
        _lastSource = RateSource.live;
        return _cachedRatesVsUsd;
      }
    } catch (e) {
      debugPrint('CurrencyService live fetch failed: $e');
    }

    // Fallback: If we had a prior cache (even expired), use it as cache
    if (_cachedRatesVsUsd.isNotEmpty) {
      _lastSource = RateSource.cache;
      return _cachedRatesVsUsd;
    }

    // Secondary fallback: build from benchmarks
    _lastSource = RateSource.benchmark;
    final Map<String, double> benchmarkRates = {'USD': 1.0};
    final usdToIdr = getCurrency('USD').benchmarkToIdr;
    for (final c in currencies) {
      if (c.code == 'USD') continue;
      // 1 USD = (usdToIdr / c.benchmarkToIdr) of currency c
      benchmarkRates[c.code] = usdToIdr / c.benchmarkToIdr;
    }
    _cachedRatesVsUsd = benchmarkRates;
    return _cachedRatesVsUsd;
  }

  /// Converts an amount between any two supported currencies
  ConversionResult convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    Map<String, double>? ratesVsUsd,
  }) {
    final from = fromCurrency.toUpperCase();
    final to = toCurrency.toUpperCase();
    final fromInfo = getCurrency(from);
    final toInfo = getCurrency(to);

    final rates = ratesVsUsd ?? _cachedRatesVsUsd;
    final hasLiveOrCached = rates.containsKey(from) && rates.containsKey(to);

    double result = 0.0;
    double crossRate = 1.0;
    String info = '';
    RateSource source = _lastSource;

    if (hasLiveOrCached) {
      final fromRateUsd = rates[from]!;
      final toRateUsd = rates[to]!;
      result = (amount / fromRateUsd) * toRateUsd;
      crossRate = toRateUsd / fromRateUsd;

      final formattedRate = crossRate < 0.01
          ? crossRate.toStringAsFixed(6)
          : crossRate.toStringAsFixed(4);

      if (_lastSource == RateSource.live) {
        info = '1 $from ≈ $formattedRate $to (Frankfurter Live)';
        source = RateSource.live;
      } else {
        info = '1 $from ≈ $formattedRate $to (Data Kurs Tersimpan / Cache)';
        source = RateSource.cache;
      }
    } else {
      // Benchmark fallback
      final amountInIdr = amount * fromInfo.benchmarkToIdr;
      result = amountInIdr / toInfo.benchmarkToIdr;
      crossRate = fromInfo.benchmarkToIdr / toInfo.benchmarkToIdr;

      final formattedRate = crossRate < 0.01
          ? crossRate.toStringAsFixed(6)
          : crossRate.toStringAsFixed(4);
      info = '1 $from ≈ $formattedRate $to (Benchmark Offline)';
      source = RateSource.benchmark;
    }

    final formattedTarget = ConversionResult.formatAmount(result, to);

    return ConversionResult(
      sourceAmount: amount,
      fromCurrency: from,
      targetAmount: result,
      toCurrency: to,
      formattedTarget: formattedTarget,
      crossRate: crossRate,
      rateSource: source,
      rateInfoText: info,
      timestamp: _lastFetchTime ?? DateTime.now(),
    );
  }

  /// Natural language parser for currency codes (supports EN & ID)
  String? detectCurrencyCode(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('usd') ||
        lower.contains('us dollar') ||
        lower.contains('dolar as') ||
        lower.contains('dollar') ||
        lower.contains('dolar')) {
      return 'USD';
    }
    if (lower.contains('eur') || lower.contains('euro') || lower.contains('€')) {
      return 'EUR';
    }
    if (lower.contains('sgd') ||
        lower.contains('singapore dollar') ||
        lower.contains('dolar singapura') ||
        lower.contains('sing dollar')) {
      return 'SGD';
    }
    if (lower.contains('myr') ||
        lower.contains('ringgit') ||
        lower.contains('malaysian ringgit')) {
      return 'MYR';
    }
    if (lower.contains('jpy') || lower.contains('yen') || lower.contains('jepang')) {
      return 'JPY';
    }
    if (lower.contains('gbp') ||
        lower.contains('pound') ||
        lower.contains('sterling') ||
        lower.contains('british')) {
      return 'GBP';
    }
    if (lower.contains('aud') ||
        lower.contains('australian dollar') ||
        lower.contains('dolar australia')) {
      return 'AUD';
    }
    if (lower.contains('sar') ||
        lower.contains('riyal') ||
        lower.contains('saudi')) {
      return 'SAR';
    }
    if (lower.contains('thb') ||
        lower.contains('baht') ||
        lower.contains('thai')) {
      return 'THB';
    }
    if (lower.contains('krw') ||
        lower.contains('won') ||
        lower.contains('korea')) {
      return 'KRW';
    }
    if (lower.contains('cny') ||
        lower.contains('yuan') ||
        lower.contains('renminbi') ||
        lower.contains('china')) {
      return 'CNY';
    }
    if (lower.contains('idr') || lower.contains('rupiah')) {
      return 'IDR';
    }
    return null;
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService.instance;
});

final currencyRatesProvider = FutureProvider<Map<String, double>>((ref) async {
  final service = ref.watch(currencyServiceProvider);
  return service.fetchRatesVsUsd();
});
