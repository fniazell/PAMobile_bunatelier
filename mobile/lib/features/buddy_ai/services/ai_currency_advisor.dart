import 'package:intl/intl.dart';
import '../../../data/mock/catalog_data.dart';
import '../../cart/providers/cart_provider.dart';
import '../../converter/services/currency_service.dart';

class AiCurrencyResolution {
  final String queryType; // 'product', 'product_not_found', 'cart', 'cart_empty'
  final String? productName;
  final int? originalPriceIdr;
  final String? searchedTerm;
  final int? cartItemCount;
  final int? cartGrandTotalIdr;
  final String targetCurrency;
  final double? convertedAmount;
  final String? formattedConverted;
  final String? rateInfoText;
  final RateSource rateSource;
  final bool isEnglishQuery;
  final String naturalLanguageReply;

  const AiCurrencyResolution({
    required this.queryType,
    this.productName,
    this.originalPriceIdr,
    this.searchedTerm,
    this.cartItemCount,
    this.cartGrandTotalIdr,
    required this.targetCurrency,
    this.convertedAmount,
    this.formattedConverted,
    this.rateInfoText,
    required this.rateSource,
    required this.isEnglishQuery,
    required this.naturalLanguageReply,
  });

  Map<String, dynamic> toMap() {
    return {
      'queryType': queryType,
      'productName': productName,
      'originalPriceIdr': originalPriceIdr,
      'searchedTerm': searchedTerm,
      'cartItemCount': cartItemCount,
      'cartGrandTotalIdr': cartGrandTotalIdr,
      'targetCurrency': targetCurrency,
      'convertedAmount': convertedAmount,
      'formattedConverted': formattedConverted,
      'rateInfoText': rateInfoText,
      'rateSource': rateSource.name,
      'isEnglishQuery': isEnglishQuery,
    };
  }
}

class AiCurrencyAdvisor {
  static bool isCurrencyOrPriceQuery(String text) {
    final lower = text.toLowerCase();

    final hasCurrencyWord = lower.contains('usd') ||
        lower.contains('eur') ||
        lower.contains('sgd') ||
        lower.contains('myr') ||
        lower.contains('jpy') ||
        lower.contains('gbp') ||
        lower.contains('aud') ||
        lower.contains('sar') ||
        lower.contains('thb') ||
        lower.contains('krw') ||
        lower.contains('cny') ||
        lower.contains('dollar') ||
        lower.contains('dolar') ||
        lower.contains('euro') ||
        lower.contains('yen') ||
        lower.contains('ringgit') ||
        lower.contains('won') ||
        lower.contains('pound') ||
        lower.contains('riyal') ||
        lower.contains('baht') ||
        lower.contains('yuan') ||
        lower.contains('mata uang') ||
        lower.contains('currency') ||
        lower.contains(r'$') ||
        lower.contains('€') ||
        lower.contains('¥') ||
        lower.contains('£');

    final hasPriceOrConversionWord = lower.contains('how much') ||
        lower.contains('what is the price') ||
        lower.contains("what's the price") ||
        lower.contains('price') ||
        lower.contains('cost') ||
        lower.contains('harga') ||
        lower.contains('berapa') ||
        lower.contains('kurs') ||
        lower.contains('konversi') ||
        lower.contains('convert') ||
        lower.contains('total') ||
        lower.contains('worth');

    return hasCurrencyWord && hasPriceOrConversionWord;
  }

  static bool isEnglish(String text) {
    final lower = text.toLowerCase();
    final englishWords = [
      'how much',
      'what is',
      "what's",
      'price',
      'cost',
      'in usd',
      'in eur',
      'in dollar',
      'current cart',
      'my cart',
      'my order',
      'would my',
    ];
    for (final w in englishWords) {
      if (lower.contains(w)) return true;
    }
    return false;
  }

  /// Evaluates query against actual catalog, live cart, and Global Converter CurrencyService
  static Future<AiCurrencyResolution?> resolve({
    required String userMessage,
    required CartState cartState,
    List<ProductItem>? catalogProducts,
    ProductItem? contextProduct,
  }) async {
    if (!isCurrencyOrPriceQuery(userMessage)) {
      return null;
    }

    final lower = userMessage.toLowerCase();
    final isEn = isEnglish(userMessage);
    final targetCode = CurrencyService.instance.detectCurrencyCode(userMessage) ?? 'USD';
    final targetCurrencyInfo = CurrencyService.instance.getCurrency(targetCode);

    // 1. Fetch latest exchange rates from Global Converter service
    await CurrencyService.instance.fetchRatesVsUsd();
    final rateSource = CurrencyService.instance.lastSource;

    // 2. Check if asking about Cart / Checkout / Order
    final isCartQuery = lower.contains('cart') ||
        lower.contains('keranjang') ||
        lower.contains('pesananku') ||
        lower.contains('pesanan saya') ||
        lower.contains('my order') ||
        lower.contains('current cart') ||
        lower.contains('total pesanan') ||
        lower.contains('checkout');

    if (isCartQuery) {
      if (cartState.items.isEmpty) {
        final reply = isEn
            ? 'Your cart is currently empty! Add some delicious burgers or sides first, and I will gladly calculate the total in $targetCode for you.'
            : 'Keranjang belanjamu saat ini masih kosong nih. Yuk pilih burger atau cemilan lezat dulu di menu, nanti kubantu hitungkan perkiraan totalnya dalam $targetCode!';

        return AiCurrencyResolution(
          queryType: 'cart_empty',
          targetCurrency: targetCode,
          rateSource: rateSource,
          isEnglishQuery: isEn,
          naturalLanguageReply: reply,
        );
      }

      final grandTotal = cartState.totalWithDelivery;
      final itemCount = cartState.totalItemCount;

      final conversion = CurrencyService.instance.convert(
        amount: grandTotal.toDouble(),
        fromCurrency: 'IDR',
        toCurrency: targetCode,
      );

      final formattedIdr = NumberFormat('#,##0', 'id_ID').format(grandTotal);
      final symbol = targetCurrencyInfo.symbol;

      final reply = isEn
          ? 'Your current cart total is Rp $formattedIdr ($itemCount items, including tax and delivery). Based on the latest available exchange rate, that is approximately $symbol${conversion.formattedTarget} $targetCode. The final payment at checkout remains in IDR.'
          : 'Perkiraan total belanja keranjangmu saat ini adalah Rp $formattedIdr ($itemCount item, termasuk pajak & ongkir). Berdasarkan kurs terbaru, nilainya sekitar $symbol${conversion.formattedTarget} $targetCode. Pembayaran akhir saat checkout tetap menggunakan IDR (Rupiah).';

      return AiCurrencyResolution(
        queryType: 'cart',
        cartItemCount: itemCount,
        cartGrandTotalIdr: grandTotal,
        targetCurrency: targetCode,
        convertedAmount: conversion.targetAmount,
        formattedConverted: '$symbol${conversion.formattedTarget} $targetCode',
        rateInfoText: conversion.rateInfoText,
        rateSource: conversion.rateSource,
        isEnglishQuery: isEn,
        naturalLanguageReply: reply,
      );
    }

    // 3. Check if asking about a Product
    final products = catalogProducts ?? CatalogData.allProducts;

    ProductItem? matchedProduct;

    // A. Check context product first (if viewing product detail)
    if (contextProduct != null &&
        (lower.contains('this') ||
            lower.contains('ini') ||
            lower.contains(contextProduct.name.toLowerCase()))) {
      matchedProduct = contextProduct;
    }

    // B. Check catalog products & aliases
    if (matchedProduct == null) {
      // Priority check for aliases mentioned in user prompt
      if (lower.contains('the main character') ||
          lower.contains('main character') ||
          lower.contains('og main')) {
        matchedProduct = products.firstWhere(
          (p) => p.name.toLowerCase().contains('main character'),
          orElse: () => products.first,
        );
      } else {
        for (final p in products) {
          final pName = p.name.toLowerCase();
          if (lower.contains(pName)) {
            matchedProduct = p;
            break;
          }
        }
      }

      // Check secondary aliases
      if (matchedProduct == null) {
        if (lower.contains('hot mess')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-02', orElse: () => products.first);
        } else if (lower.contains('smash hit')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-03', orElse: () => products.first);
        } else if (lower.contains('crunch culture')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-04', orElse: () => products.first);
        } else if (lower.contains('no cap')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-05', orElse: () => products.first);
        } else if (lower.contains('slay bacon') || lower.contains('bacon burger')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-06', orElse: () => products.first);
        } else if (lower.contains('big rizz')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-07', orElse: () => products.first);
        } else if (lower.contains('lowkey spicy')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-08', orElse: () => products.first);
        } else if (lower.contains('touch grass')) {
          matchedProduct = products.firstWhere((p) => p.id == 'b-12', orElse: () => products.first);
        } else if (lower.contains('truffle butter')) {
          matchedProduct = products.firstWhere((p) => p.name.toLowerCase().contains('truffle butter'), orElse: () => products.first);
        }
      }
    }

    // 4. If Product Found
    if (matchedProduct != null) {
      final conversion = CurrencyService.instance.convert(
        amount: matchedProduct.price.toDouble(),
        fromCurrency: 'IDR',
        toCurrency: targetCode,
      );

      final formattedIdr = NumberFormat('#,##0', 'id_ID').format(matchedProduct.price);
      final symbol = targetCurrencyInfo.symbol;

      final reply = isEn
          ? '${matchedProduct.name} costs Rp $formattedIdr. Based on the latest available exchange rate, that is approximately $symbol${conversion.formattedTarget} $targetCode. The final checkout amount remains in IDR.'
          : 'Harga ${matchedProduct.name} adalah Rp $formattedIdr. Berdasarkan kurs terbaru, perkiraannya adalah sekitar $symbol${conversion.formattedTarget} $targetCode. Pembayaran akhir pesanan tetap dalam IDR (Rupiah).';

      return AiCurrencyResolution(
        queryType: 'product',
        productName: matchedProduct.name,
        originalPriceIdr: matchedProduct.price,
        targetCurrency: targetCode,
        convertedAmount: conversion.targetAmount,
        formattedConverted: '$symbol${conversion.formattedTarget} $targetCode',
        rateInfoText: conversion.rateInfoText,
        rateSource: conversion.rateSource,
        isEnglishQuery: isEn,
        naturalLanguageReply: reply,
      );
    }

    // 5. Product Not Found (e.g. "Seoul Mate", "Truffle Era")
    final extractedName = _extractSearchedProductName(userMessage);

    final reply = isEn
        ? "The product '$extractedName' was not found in Bun Atelier's current menu. We offer handcrafted burgers like OG Main Character, Smash Hit, Hot Mess Express, and Truffle Butter Truce. Which one would you like to check?"
        : "Menu '$extractedName' belum ditemukan di katalog Bun Atelier saat ini. Kami memiliki pilihan burger favorit seperti OG Main Character, Smash Hit, Hot Mess Express, dan Truffle Butter Truce. Mau cek harga salah satunya?";

    return AiCurrencyResolution(
      queryType: 'product_not_found',
      searchedTerm: extractedName,
      targetCurrency: targetCode,
      rateSource: rateSource,
      isEnglishQuery: isEn,
      naturalLanguageReply: reply,
    );
  }

  static String _extractSearchedProductName(String text) {
    var cleaned = text;

    final prefixes = [
      'how much is the',
      'how much is',
      'how much would',
      'how much for',
      "what is the price of",
      "what's the price of",
      'what is',
      'price of',
      'cost of',
      'berapa harga',
      'berapa perkiraan harga',
      'berapa',
      'harga',
    ];

    final lower = cleaned.toLowerCase();
    for (final p in prefixes) {
      if (lower.startsWith(p)) {
        cleaned = cleaned.substring(p.length).trim();
        break;
      }
    }

    // Remove suffix like "in USD", "in Singapore dollars", "dalam dolar", "dalam euro"
    final suffixes = [
      RegExp(r'\s+in\s+.*$', caseSensitive: false),
      RegExp(r'\s+dalam\s+.*$', caseSensitive: false),
      RegExp(r'\s+ke\s+.*$', caseSensitive: false),
      RegExp(r'[?!.,]+$'),
    ];

    for (final reg in suffixes) {
      cleaned = cleaned.replaceAll(reg, '').trim();
    }

    if (cleaned.isEmpty || cleaned.length < 2) {
      return 'yang kamu maksud';
    }

    return cleaned;
  }
}
