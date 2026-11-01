import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  final double benchmarkToIdr; // Benchmark fallback

  const CurrencyInfo({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.benchmarkToIdr,
  });
}

enum RateSource {
  live,
  cache,
  benchmark,
}

class ConversionResult {
  final double sourceAmount;
  final String fromCurrency;
  final double targetAmount;
  final String toCurrency;
  final String formattedTarget;
  final double crossRate;
  final RateSource rateSource;
  final String rateInfoText;
  final DateTime timestamp;

  const ConversionResult({
    required this.sourceAmount,
    required this.fromCurrency,
    required this.targetAmount,
    required this.toCurrency,
    required this.formattedTarget,
    required this.crossRate,
    required this.rateSource,
    required this.rateInfoText,
    required this.timestamp,
  });

  bool get isLive => rateSource == RateSource.live;
  bool get isCached => rateSource == RateSource.cache;
  bool get isBenchmark => rateSource == RateSource.benchmark;

  static String formatAmount(double value, String currencyCode) {
    if (currencyCode == 'IDR' || currencyCode == 'KRW' || currencyCode == 'JPY') {
      return NumberFormat('#,##0', 'id_ID').format(value.round());
    }
    return NumberFormat('#,##0.00', 'en_US').format(value);
  }
}
