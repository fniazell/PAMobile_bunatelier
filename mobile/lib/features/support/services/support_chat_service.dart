import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';

class SupportChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasError;
  final bool isSending;

  const SupportChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasError = false,
    this.isSending = false,
  });

  SupportChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? hasError,
    bool? isSending,
  }) {
    return SupportChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      hasError: hasError ?? this.hasError,
      isSending: isSending ?? this.isSending,
    );
  }

  Map<String, String> toHistoryMap() {
    return {'role': isUser ? 'user' : 'model', 'text': text};
  }
}

class SupportChatResult {
  final bool success;
  final String reply;
  final String? errorMessage;
  final bool isNetworkError;

  const SupportChatResult({
    required this.success,
    required this.reply,
    this.errorMessage,
    this.isNetworkError = false,
  });
}

class SupportChatService {
  SupportChatService({Dio? dio});

  static final String _geminiApiKey = utf8.decode(
    base64.decode('QVEuQWI4Uk42S0FTRWc3Ml9hT21nTGtjQXQ0aTlxUVpHWFpLeG1xbjdxMktJLVRoTFRzRnc='),
  );

  static const String _systemPrompt = '''
Kamu adalah "Bun Atelier Concierge" & "Bun Buddy AI" — Customer Support dan Konsultan Burger resmi untuk Bun Atelier, gerai burger artisanal premium ("Worth the Mess").

PEDOMAN UTAMA:
1. BAHASA & GAYA:
   - Jawab pertanyaan pengguna SECARA LANGSUNG, SPESIFIK, dan SESUAI dengan apa yang ditanyakan.
   - Jangan menjawab dengan jawaban template yang kaku atau tidak nyambung!
   - Gunakan Bahasa Indonesia yang ramah, santai, sopan, antusias, dan ringkas.
   - DILARANG menggunakan tanda bintang (* atau **). Untuk bullet gunakan tanda titik (•) atau strip (-).

2. DAFTAR MENU RESMI BUN ATELIER:
   BURGER UTAMA:
   • Truffle Butter Truce: Rp 85.000 (BURGER TERMAHAL / PALING MEWAH - Wagyu blend patty, black truffle butter, truffle aioli, melted aged cheddar)
   • The Hangover Cure: Rp 82.000 (Double smashed Australian beef, beef bacon, sunny egg, hash brown crumble, BBQ sauce)
   • No Cap Double Smash: Rp 78.000 (Triple aged cheddar, double smashed beef, caramelized onions, molten cheese dip)
   • OG Main Character: Rp 72.000 (BEST-SELLER JUARA - double smashed Australian beef patty, double cheddar, secret relish sauce)
   • Hot Mess Express: Rp 72.000 (EKSTRA PEDAS - habanero jam, ghost pepper mayo, crispy jalapeno)
   • Lowkey Spicy: Rp 64.000 (PEDAS SEDANG - chipotle lime mayo, pickled jalapeno, pepper jack)
   • Crunch Culture: Rp 59.000 (Crispy buttermilk chicken thigh, garlic herb aioli, fresh slaw)
   • Touch Grass: Rp 58.000 (BURGER PALING MURAH / PLANT-BASED - shiitake mushroom & black bean patty, vegan truffle mayo)

   CROISSANT BURGER:
   • Smoked Bacon & Brie Croissant: Rp 76.000 (Beef bacon, molten brie cheese, balsamic onions)
   • Truffle Wagyu Croissant Smash: Rp 74.000 (Croissant bun, smashed Angus, truffle soft scramble)
   • Morning Pastrami Croissant Burger: Rp 69.000 (Spiral croissant, cured pastrami beef, sunny egg)
   • Crispy Chicken Avocado Croissant Burger: Rp 66.000 (Buttermilk chicken, fresh avocado smash)

   SIDE QUEST:
   • Crispy Hash Brown (Rp 22.000), Crispy French Fries (Rp 25.000), Beer-Battered Onion Rings (Rp 28.000), Truffle Mac n Cheese (Rp 38.000), Smoky Buffalo Chicken Wings (Rp 48.000).

   DRINKS & DESSERTS:
   • Minuman: Aqua Reflections (Rp 15.000), Soft Drinks (Rp 18.000), Dr Pepper (Rp 20.000), Fresh Iced Lemon Tea (Rp 22.000), Atelier Berry Slushie (Rp 32.000), Vintage Root Beer Float (Rp 35.000).
   • Penutup: Triple Choc Melt Muffin (Rp 26.000), Artisan Gelato Cup (Rp 28.000), Vanilla Bean Panna Cotta (Rp 32.000), Belgian Waffle Ice Cream (Rp 38.000), Fluffy Souffle Pancake (Rp 42.000).

3. CABANG & JAM BUKA:
   • Senopati Flagship: Jl. Senopati No. 45, Jaksel (10:00 - 23:00 WIB)
   • PIK 2 Waterfront: Boulevard Raya No. 12, Jakut (11:00 - 00:00 WIB)
   • Cabang Lainnya: Maluku, Bali, London, Kuala Lumpur, Singapore.
   • Buka setiap hari, 100% Halal (No Pork, No Lard, No Alcohol).
''';

  static String cleanAsterisks(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^\*\n]+?)\*'), r'$1')
        .replaceAll(RegExp(r'^[\s]*\*[\s]+', multiLine: true), '• ')
        .replaceAll('*', '')
        .trim();
  }

  static String _getOfflineQuickReply(String message) {
    final lower = message.toLowerCase();

    // 1. BURGER PALING MAHAL / MEWAH
    if (lower.contains('paling mahal') ||
        lower.contains('termahal') ||
        lower.contains('mewah') ||
        lower.contains('pricey') ||
        (lower.contains('mahal') &&
            (lower.contains('burger') || lower.contains('menu')))) {
      return 'Burger paling mewah dan paling mahal di Bun Atelier adalah Truffle Butter Truce seharga Rp 85.000!\n\nBurger ini diracik dengan premium Wagyu blend patty yang sangat juicy, black truffle butter, truffle aioli beraroma mewah, dan keju melted aged cheddar.\n\nUntuk kategori Croissant Burger, yang paling premium adalah Smoked Bacon & Brie Croissant (Rp 76.000) dan Truffle Wagyu Croissant Smash (Rp 74.000).\n\nMau coba kenikmatan mewah Truffle Butter Truce hari ini?';
    }

    // 2. BURGER PALING MURAH / HEMAT / BUDGET
    if (lower.contains('paling murah') ||
        lower.contains('termurah') ||
        lower.contains('hemat') ||
        lower.contains('budget') ||
        lower.contains('terjangkau') ||
        (lower.contains('murah') &&
            (lower.contains('burger') || lower.contains('menu')))) {
      return 'Pilihan burger paling hemat dan bersahabat di Bun Atelier adalah:\n• Touch Grass: Rp 58.000 (Burger plant-based nabati dengan patty jamur shiitake dan vegan truffle mayo)\n• Crunch Culture: Rp 59.000 (Ayam buttermilk goreng renyah maksimal dengan saus garlic herb aioli)\n\nUntuk menu sides cemilan hemat, kami punya Crispy Hash Brown (Rp 22.000) dan Crispy French Fries (Rp 25.000). Tetap lezat dan ramah di kantong!';
    }

    // 3. BURGER PEDAS
    if (lower.contains('pedas') ||
        lower.contains('pedes') ||
        lower.contains('spicy') ||
        lower.contains('hot')) {
      return 'Untuk pencinta pedas, kami sangat merekomendasikan:\n• Hot Mess Express (Rp 72.000) - Level pedas juara dengan habanero jam membakar, ghost pepper mayo, dan crispy jalapeno renyah!\n• Lowkey Spicy (Rp 64.000) - Pedas santai gurih dengan chipotle lime mayo dan pickled jalapeno.\n\nPasti bikin nagih dan mata melek!';
    }

    // 4. CROISSANT BURGER
    if (lower.contains('croissant') ||
        lower.contains('pastrami') ||
        lower.contains('avocado') ||
        lower.contains('brie')) {
      return 'Bun Atelier punya 4 menu Croissant Burger istimewa dengan roti croissant French butter yang flaky dan harum:\n1. Truffle Wagyu Croissant Smash (Rp 74.000) - Smashed Angus patty, truffle soft scramble, dan melted French emmental.\n2. Smoked Bacon & Brie Croissant (Rp 76.000) - Crispy beef bacon, French brie melt, dan caramelized balsamic onions.\n3. Morning Pastrami Croissant Burger (Rp 69.000) - Beef pastrami, sunny egg, dan yellow cheddar.\n4. Crispy Chicken Avocado Croissant Burger (Rp 66.000) - Buttermilk chicken thigh renyah dengan avocado smash segar.\n\nSensasi flaky croissant-nya wajib kamu coba!';
    }

    // 5. DESSERT / MANIS
    if (lower.contains('dessert') ||
        lower.contains('manis') ||
        lower.contains('waffle') ||
        lower.contains('gelato') ||
        lower.contains('ice cream') ||
        lower.contains('es krim') ||
        lower.contains('muffin') ||
        lower.contains('pancake') ||
        lower.contains('panna cotta') ||
        lower.contains('kue') ||
        lower.contains('penutup')) {
      return 'Ada dong! Di Bun Atelier kita punya 5 menu dessert lezat yang manis dan pas banget:\n\n1. Belgian Waffle Ice Cream (Rp 38.000) - Liege waffle hangat dengan salted caramel gelato dan roasted pecans (Best-Seller!)\n2. Artisan Gelato Cup (Rp 28.000) - Double scoop gelato buatan tangan pilihan French Vanilla & Dark Chocolate Fudge\n3. Triple Choc Melt Muffin (Rp 26.000) - Muffin cokelat dengan lelehan molten fudge hangat\n4. Fluffy Souffle Pancake (Rp 42.000) - Souffle pancake lembut ala Jepang\n5. Vanilla Bean Panna Cotta (Rp 32.000) - Panna cotta vanilla asli dengan passionfruit coulis';
    }

    // 6. SIDES / CEMILAN
    if (lower.contains('side') ||
        lower.contains('kentang') ||
        lower.contains('fries') ||
        lower.contains('hash brown') ||
        lower.contains('onion') ||
        lower.contains('mac') ||
        lower.contains('wings') ||
        lower.contains('cemilan')) {
      return 'Berikut pilihan Side Quest (cemilan pendamping) lezat di Bun Atelier:\n• Crispy Hash Brown (Rp 22.000) - Patty kentang parut renyah keemasan\n• Crispy French Fries (Rp 25.000) - Kentang goreng renyah bumbu sea salt\n• Beer-Battered Onion Rings (Rp 28.000) - Bawang bombay goreng tepung renyah dengan garlic aioli\n• Truffle Mac n Cheese (Rp 38.000) - Elbow pasta dengan 5 keju leleh dan white truffle oil\n• Smoky Buffalo Chicken Wings (Rp 48.000) - 6 pcs sayap ayam pedas gurih\n\nFavorit pelanggan kami adalah Truffle Mac n Cheese dan Crispy Hash Brown!';
    }

    // 7. DRINKS / MINUMAN
    if (lower.contains('minum') ||
        lower.contains('drink') ||
        lower.contains('air') ||
        lower.contains('aqua') ||
        lower.contains('soda') ||
        lower.contains('slushie') ||
        lower.contains('tea') ||
        lower.contains('teh') ||
        lower.contains('haus') ||
        lower.contains('float')) {
      return 'Untuk pelepas dahaga, Bun Atelier menyediakan:\n• Aqua Reflections Mineral Water: Rp 15.000 (Air mineral alami botol kaca premium)\n• Coca-Cola Classic / Sprite / Fanta Orange: Rp 18.000\n• Dr Pepper: Rp 20.000\n• Fresh Iced Lemon Tea: Rp 22.000 (Teh Ceylon segar dengan lemon asli dan madu)\n• Atelier Berry Slushie: Rp 32.000 (Blended strawberry, blueberry & raspberry segar)\n• Vintage Root Beer Float: Rp 35.000 (Root beer klasik dengan 1 scoop vanilla gelato)';
    }

    // 8. KEHALALAN
    if (lower.contains('halal') ||
        lower.contains('babi') ||
        lower.contains('pork') ||
        lower.contains('lard') ||
        lower.contains('alkohol')) {
      return 'Semua menu di Bun Atelier 100% No Pork No Lard! Daging sapi kami bersertifikat Australian Halal Beef & Wagyu Blend, ayam segar pilihan, serta seluruh proses pengolahan diawasi ketat tanpa bahan non-halal. Kamu bisa bersantap dengan aman dan nyaman!';
    }

    // 9. REKOMENDASI / MENU FAVORIT
    if (lower.contains('rekomendasi') ||
        lower.contains('laris') ||
        lower.contains('best seller') ||
        lower.contains('favorit') ||
        lower.contains('enak') ||
        lower.contains('spesial')) {
      return 'Menu best-seller nomor satu kami adalah OG Main Character (Rp 72.000) dengan double smashed Australian beef dan cheddar lumer! Untuk ayam renyah, coba Crunch Culture (Rp 59.000). Untuk burger mewah, Truffle Butter Truce (Rp 85.000) adalah juaranya!';
    }

    // 10. OUTLET / CABANG / JAM BUKA
    if (lower.contains('outlet') ||
        lower.contains('cabang') ||
        lower.contains('lokasi') ||
        lower.contains('alamat') ||
        lower.contains('buka') ||
        lower.contains('toko') ||
        lower.contains('jam')) {
      return 'Bun Atelier hadir di 7 cabang resmi:\n1. Senopati Flagship (Jl. Senopati No. 45, Jaksel • Buka 10:00 - 23:00 WIB)\n2. PIK 2 Waterfront (Boulevard Raya No. 12, Jakut • Buka 11:00 - 00:00 WIB)\n3. Bun Atelier — Maluku (Jl. Jenderal Sudirman No. 88, Kota Ambon • Buka 10:00 - 22:00 WIT)\n4. Bali (Jl. Kayu Aya No. 18, Seminyak • Buka 10:00 - 23:00 WITA)\n5. London (16 Old Compton St, Soho • Buka 11:00 - 22:00 GMT)\n6. Kuala Lumpur (Lot 10, Bukit Bintang • Buka 10:00 - 22:00 MYT)\n7. Singapore (7 Keong Saik Rd, Chinatown • Buka 11:00 - 22:00 SGT)\nBuka setiap hari dan dapat diakses langsung via Google Maps pada menu Pilih Cabang!';
    }

    // 11. HARGA MENU / BERAPAAN
    if (lower.contains('harga') ||
        lower.contains('berapa') ||
        lower.contains('pricelist') ||
        lower.contains('daftar harga')) {
      return 'Daftar harga menu di Bun Atelier:\n• Burger Utama: Rp 58.000 - Rp 85.000 (Paling murah: Touch Grass Rp 58.000 | Paling mahal: Truffle Butter Truce Rp 85.000)\n• Croissant Burger: Rp 66.000 - Rp 76.000\n• Side Quest: Rp 22.000 - Rp 48.000\n• Drinks: Rp 15.000 - Rp 35.000\n• Desserts: Rp 26.000 - Rp 42.000\nSemua harga transparan dan nett tanpa biaya tersembunyi!';
    }

    // 12. CARA PESAN / PENGIRIMAN
    if (lower.contains('pesan') ||
        lower.contains('order') ||
        lower.contains('antar') ||
        lower.contains('kirim') ||
        lower.contains('delivery') ||
        lower.contains('bayar')) {
      return 'Kamu bisa langsung memilih menu favorit di aplikasi Bun Atelier ini dan melakukan checkout. Metode pembayaran yang didukung meliputi E-Wallet (GoPay, OVO, DANA), Transfer Bank, Kartu Kredit/Debit, dan Bayar di Tempat (COD). Estimasi pengiriman 30-60 menit.';
    }

    // 13. DYNAMIC CONVERSATIONAL FALLBACK
    if (lower.contains('siapa') || lower.contains('kamu')) {
      return 'Halo! Aku Bun Buddy, asisten virtual dan konsultan burger resmi Bun Atelier. Aku siap bantu kamu dengan rekomendasi burger lezat, info harga, konversi mata uang, atau info outlet.';
    }

    if (lower.contains('halo') || lower.contains('hai') || lower.contains('hello') || lower.contains('pagi') || lower.contains('siang') || lower.contains('malam')) {
      return 'Halo! Selamat datang di Bun Atelier. Mau cari burger daging sapi juicy, ayam renyah buttermilk, croissant burger, atau cemilan lezat hari ini? Kasih tahu seleramu ya!';
    }

    if (lower.contains('terima kasih') || lower.contains('makasih') || lower.contains('thanks')) {
      return 'Sama-sama! Selamat menikmati hidangan artisanal kami. Jika ada hal lain yang ingin kamu tanyakan seputar burger Bun Atelier, jangan ragu tanyakan padaku ya!';
    }

    return 'Halo! Untuk pertanyaanmu seputar burger Bun Atelier, kami menyajikan aneka pilihan artisanal premium:\n• Best-seller Juara: OG Main Character (Rp 72.000)\n• Ekstra Pedas: Hot Mess Express (Rp 72.000)\n• Paling Mewah: Truffle Butter Truce (Rp 85.000)\n• Ayam Renyah: Crunch Culture (Rp 59.000)\n• Croissant Burger: Smoked Bacon & Brie (Rp 76.000)\n\nAda kategori atau rekomendasi menu tertentu yang ingin kamu tanyakan?';
  }

  Future<String?> _callGeminiDirect({
    required String message,
    required List<SupportChatMessage> history,
    Map<String, dynamic>? currencyContext,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final contents = <Map<String, dynamic>>[];
      final recentHistory = history.length > 6
          ? history.sublist(history.length - 6)
          : history;
      for (final h in recentHistory) {
        contents.add({
          'role': h.isUser ? 'user' : 'model',
          'parts': [{'text': h.text}],
        });
      }

      String currentText = message;
      if (currencyContext != null && currencyContext['formattedConverted'] != null) {
        currentText += '\n[Info Konversi: ${currencyContext['productName'] ?? 'Pesanan'} seharga ${currencyContext['formattedConverted']}]';
      }
      contents.add({
        'role': 'user',
        'parts': [{'text': currentText}],
      });

      final body = {
        'systemInstruction': {
          'parts': [{'text': _systemPrompt}],
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        },
      };

      final response = await dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=$_geminiApiKey',
        data: body,
      );

      if (response.statusCode == 200 && response.data is Map) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]?['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]?['text']?.toString();
            if (text != null && text.trim().isNotEmpty) {
              return cleanAsterisks(text.trim());
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Direct Gemini API fallback error: $e');
    }
    return null;
  }

  Future<SupportChatResult> sendMessage({
    required String message,
    List<SupportChatMessage> history = const [],
    Map<String, dynamic>? currencyContext,
  }) async {
    final conversationHistory = history
        .where((m) => !m.hasError && !m.isSending)
        .toList();
    if (conversationHistory.isNotEmpty &&
        conversationHistory.last.isUser &&
        conversationHistory.last.text.trim() == message.trim()) {
      conversationHistory.removeLast();
    }
    final startIndex = conversationHistory.length > 10
        ? conversationHistory.length - 10
        : 0;
    final historyPayload = conversationHistory
        .skip(startIndex)
        .map((m) => m.toHistoryMap())
        .toList();

    final candidateBases = <String>{
      if (ApiConstants.customBaseUrl != null &&
          ApiConstants.customBaseUrl!.isNotEmpty)
        ApiConstants.customBaseUrl!,
      if (!kIsWeb && Platform.isAndroid) ...[
        'http://192.168.22.236:3000/api', // Live PC Wi-Fi IP
        'http://127.0.0.1:3000/api', // ADB Reverse port forwarding (instant via USB)
        'http://localhost:3000/api',
        'http://10.200.63.191:3000/api', // Alternate Wi-Fi IP
        'http://10.0.2.2:3000/api', // Android Emulator
      ],
      ApiConstants.baseUrl,
    }.toList();

    DioException? lastDioException;

    for (final base in candidateBases) {
      try {
        final client = Dio(
          BaseOptions(
            baseUrl: base,
            connectTimeout: const Duration(milliseconds: 2000),
            receiveTimeout: const Duration(seconds: 25),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

        final postData = <String, dynamic>{
          'message': message.trim(),
          'history': historyPayload,
        };
        if (currencyContext != null) {
          postData['currencyContext'] = currencyContext;
        }

        final response = await client.post(
          ApiConstants.supportChat,
          data: postData,
        );

        if (response.statusCode == 200 && response.data is Map) {
          ApiConstants.customBaseUrl = base;
          final data = response.data as Map<String, dynamic>;
          final rawReply =
              data['reply']?.toString() ??
              'Terima kasih telah menghubungi Bun Atelier Support.';
          return SupportChatResult(
            success: true,
            reply: cleanAsterisks(rawReply),
          );
        }
      } on DioException catch (e) {
        lastDioException = e;
        debugPrint(
            'SupportChatService DioException on $base: ${e.type} - ${e.message}');
        continue;
      } catch (e) {
        debugPrint('SupportChatService Unexpected Error: $e');
        break;
      }
    }

    // 2. Jika koneksi backend server PC tidak dapat dijangkau, panggil langsung Gemini REST API
    final directGeminiReply = await _callGeminiDirect(
      message: message,
      history: conversationHistory,
      currencyContext: currencyContext,
    );
    if (directGeminiReply != null && directGeminiReply.isNotEmpty) {
      return SupportChatResult(
        success: true,
        reply: directGeminiReply,
      );
    }

    // 3. Fallback jika offline total tanpa koneksi internet sama sekali
    final offlineReply = currencyContext?['naturalLanguageReply']?.toString() ??
        _getOfflineQuickReply(message);

    return SupportChatResult(
      success: true,
      reply: cleanAsterisks(offlineReply),
      errorMessage: lastDioException != null
          ? 'Menggunakan mode tanggap cerdas offline Bun Buddy.'
          : null,
      isNetworkError: false,
    );
  }
}
