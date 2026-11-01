import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../profile/providers/settings_provider.dart';
import '../../buddy_ai/services/ai_currency_advisor.dart';
import '../services/support_chat_service.dart';

// ── FAQ Knowledge Base (Local Fallback) ────────────────────────────────────────

class _FaqEngine {
  static const Map<String, List<String>> _keywords = {
    'order': ['order', 'track', 'delivery', 'status', 'pesanan', 'lacak', 'kirim'],
    'outlet': ['outlet', 'location', 'address', 'branch', 'lokasi', 'cabang'],
    'payment': ['payment', 'pay', 'bayar', 'transfer', 'cash', 'card', 'wallet', 'ovo', 'gopay', 'dana'],
    'complaint': ['complaint', 'problem', 'issue', 'wrong', 'bad', 'keluhan', 'salah', 'rusak', 'buruk'],
    'menu': ['menu', 'food', 'burger', 'price', 'harga', 'makanan'],
    'hours': ['hours', 'open', 'close', 'time', 'buka', 'tutup', 'jam', 'waktu'],
  };

  static const Map<String, String> _responsesEn = {
    'order': '📦 **Order Status**\n\nYou can track your order in the **My Orders** section. For orders placed today, delivery typically takes 30–60 minutes. If your order is delayed beyond 90 minutes, please let me know and I will escalate it right away!',
    'outlet': '📍 **Our Outlets**\n\nBun Atelier currently has 7 locations:\n• **Senopati Flagship** (Jakarta Selatan, Indonesia) — 📞 +62 21 555-BURGER\n• **PIK 2 Waterfront** (Jakarta Utara, Indonesia) — 📞 +62 21 555-PIKBUN\n• **Bun Atelier — Maluku** (Kota Ambon, Maluku, Indonesia)\n• **Bali** (Indonesia)\n• **London** (United Kingdom)\n• **Kuala Lumpur** (Malaysia)\n• **Singapore**\n\nYou can view full details and open Google Maps for all 7 branches in the Outlets & Choose Branch section.',
    'payment': '💳 **Payment Methods**\n\nBun Atelier accepts:\n• Cash on Delivery (COD)\n• Credit / Debit Card (Visa, Mastercard)\n• Digital Wallets: GoPay, OVO, DANA, ShopeePay\n• Bank Transfer (BCA, Mandiri, BRI)\n\nAll online payments are processed securely.',
    'complaint': '🙏 **We\'re Sorry to Hear That**\n\nYour experience matters to us. Please describe the issue and we will make it right. Alternatively, email us at **customer@bunatelier.com** and our team will respond within 2 hours during business hours.',
    'menu': '🍔 **Our Menu**\n\nExplore our full menu in the **Menu** tab! Highlights:\n• OG Main Character (Rp 72.000)\n• Hot Mess Express — extra spicy (Rp 72.000)\n• Touch Grass — plant-based (Rp 58.000)\n\nUse **Bun Buddy AI** for personalized recommendations!',
    'hours': '🕐 **Opening Hours**\n\n• **Senopati Flagship**: 10:00–23:00 WIB (Mon–Sun)\n• **PIK 2 Waterfront**: 11:00–00:00 WIB (Mon–Sun)\n• **Bun Atelier — Maluku**: 10:00–22:00 WIT\n• **Bali**: 10:00–23:00 WITA\n• **London**: 11:00–22:00 GMT\n• **Kuala Lumpur**: 10:00–22:00 MYT\n• **Singapore**: 11:00–22:00 SGT\n\nAll ateliers are open every day including public holidays.',
    'default': '🤖 I\'m not quite sure I understand. Could you rephrase, or choose one of the quick options below? You can also email us at **customer@bunatelier.com** for more complex inquiries.',
  };

  static const Map<String, String> _responsesId = {
    'order': '📦 **Status Pesanan**\n\nKamu bisa melacak pesanan di bagian **My Orders**. Untuk pesanan hari ini, pengiriman biasanya memakan waktu 30–60 menit. Jika pesananmu terlambat lebih dari 90 menit, beritahu aku dan kami akan segera menindaklanjutinya!',
    'outlet': '📍 **Outlet Kami**\n\nBun Atelier kini hadir di 7 lokasi:\n• **Senopati Flagship** (Jakarta Selatan, Indonesia) — 📞 +62 21 555-BURGER\n• **PIK 2 Waterfront** (Jakarta Utara, Indonesia) — 📞 +62 21 555-PIKBUN\n• **Bun Atelier — Maluku** (Kota Ambon, Maluku, Indonesia)\n• **Bali** (Indonesia)\n• **London** (United Kingdom)\n• **Kuala Lumpur** (Malaysia)\n• **Singapore**\n\nDetail lengkap dan tombol Google Maps untuk semua cabang tersedia di bagian Outlets dan Pilih Cabang.',
    'payment': '💳 **Metode Pembayaran**\n\nBun Atelier menerima:\n• Bayar di tempat (COD)\n• Kartu Kredit / Debit (Visa, Mastercard)\n• Dompet Digital: GoPay, OVO, DANA, ShopeePay\n• Transfer Bank (BCA, Mandiri, BRI)\n\nSemua transaksi online diproses melalui gateway terenkripsi kami.',
    'complaint': '🙏 **Kami Mohon Maaf**\n\nPengalamanmu sangat penting bagi kami. Ceritakan masalahnya dan kami akan memperbaikinya. Kamu juga bisa email ke **customer@bunatelier.com** dan tim kami akan merespons dalam 2 jam di jam kerja.',
    'menu': '🍔 **Menu Kami**\n\nJelajahi menu lengkap di tab **Menu**! Highlight:\n• OG Main Character (Rp 72.000)\n• Hot Mess Express — ekstra pedas (Rp 72.000)\n• Touch Grass — berbasis tanaman (Rp 58.000)\n\nGunakan **Bun Buddy AI** untuk rekomendasi personal!',
    'hours': '🕐 **Jam Operasional**\n\n• **Senopati Flagship**: 10:00–23:00 WIB (Sen–Min)\n• **PIK 2 Waterfront**: 11:00–00:00 WIB (Sen–Min)\n• **Bun Atelier — Maluku**: 10:00–22:00 WIT\n• **Bali**: 10:00–23:00 WITA\n• **London**: 11:00–22:00 GMT\n• **Kuala Lumpur**: 10:00–22:00 MYT\n• **Singapore**: 11:00–22:00 SGT\n\nSeluruh outlet buka setiap hari termasuk hari libur nasional.',
    'default': '🤖 Aku kurang mengerti maksudmu. Bisakah diungkapkan dengan cara lain, atau pilih salah satu opsi cepat di bawah? Kamu juga bisa email ke **customer@bunatelier.com** untuk pertanyaan yang lebih kompleks.',
  };

  static String getReply(String input, String languageCode) {
    final lower = input.toLowerCase();
    for (final entry in _keywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) {
          final responses = languageCode == 'id' ? _responsesId : _responsesEn;
          return responses[entry.key] ?? responses['default']!;
        }
      }
    }
    final responses = languageCode == 'id' ? _responsesId : _responsesEn;
    return responses['default']!;
  }
}

// ── Quick Action Chips ────────────────────────────────────────────────────────

const _quickChipsEn = [
  ('📦 Order Status', 'I want to track my order status'),
  ('📍 Outlet Location', 'Where are your outlet locations?'),
  ('💳 Payment', 'What payment methods do you accept?'),
  ('😞 Complaint', 'I have a complaint about my order'),
];

const _quickChipsId = [
  ('📦 Status Pesanan', 'Saya ingin melacak status pesanan saya'),
  ('📍 Lokasi Outlet', 'Di mana lokasi outlet kalian?'),
  ('💳 Pembayaran', 'Metode pembayaran apa yang tersedia?'),
  ('😞 Keluhan', 'Saya punya keluhan tentang pesanan saya'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<SupportChatMessage> _messages = [];
  final SupportChatService _chatService = SupportChatService();

  bool _isTyping = false;
  String _lastSentUserText = '';

  late final AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcome());
  }

  void _addWelcome() {
    final lang = ref.read(settingsProvider).languageCode;
    final welcome = lang == 'id'
        ? 'Halo! 👋 Selamat datang di Bun Atelier Support (Gemini AI Concierge).\nAda yang bisa kami bantu hari ini?'
        : 'Hi there! 👋 Welcome to Bun Atelier Support (Gemini AI Concierge).\nHow can we help you today?';
    setState(() {
      _messages.add(SupportChatMessage(
        text: welcome,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _typingAnimController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _lastSentUserText = trimmed;

    setState(() {
      _messages.add(SupportChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
        isSending: true,
      ));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Resolve currency/price query if detected
    AiCurrencyResolution? currencyResolution;
    if (AiCurrencyAdvisor.isCurrencyOrPriceQuery(trimmed)) {
      final cartState = ref.read(cartProvider);
      final catalogState = ref.read(catalogProductsProvider);
      currencyResolution = await AiCurrencyAdvisor.resolve(
        userMessage: trimmed,
        cartState: cartState,
        catalogProducts: catalogState.products.isNotEmpty ? catalogState.products : null,
      );
    }

    // Call backend with user message, conversation history, and currency context
    final result = await _chatService.sendMessage(
      message: trimmed,
      history: _messages,
      currencyContext: currencyResolution?.toMap(),
    );

    if (!mounted) return;

    setState(() {
      _isTyping = false;

      // Mark the last user message as finished sending
      final userMsgIndex =
          _messages.lastIndexWhere((m) => m.isUser && m.isSending);
      if (userMsgIndex != -1) {
        _messages[userMsgIndex] =
            _messages[userMsgIndex].copyWith(isSending: false);
      }

      if (result.success) {
        _messages.add(SupportChatMessage(
          text: result.reply,
          isUser: false,
          timestamp: DateTime.now(),
          hasError: false,
        ));
      } else {
        _messages.add(SupportChatMessage(
          text: result.reply,
          isUser: false,
          timestamp: DateTime.now(),
          hasError: true,
        ));

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ?? 'Gagal menghubungi server support.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'COBA LAGI',
              textColor: AppColors.coral,
              onPressed: () => _sendMessage(_lastSentUserText),
            ),
          ),
        );
      }
    });

    _scrollToBottom();
  }

  void _useOfflineFaqFallback(String userText) {
    final lang = ref.read(settingsProvider).languageCode;
    final fallbackReply = _FaqEngine.getReply(userText, lang);

    setState(() {
      _messages.add(SupportChatMessage(
        text: '📌 *(Jawaban Lokal FAQ)*\n\n$fallbackReply',
        isUser: false,
        timestamp: DateTime.now(),
        hasError: false,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.languageCode;
    final isDark = AppColors.isDark(context);
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.cream;
    final chips = lang == 'id' ? _quickChipsId : _quickChipsEn;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(context, lang, isDark),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const SizedBox()
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (_isTyping && i == _messages.length) {
                        return _TypingBubble(controller: _typingAnimController);
                      }
                      final msg = _messages[i];
                      return _MessageBubble(
                        message: msg,
                        onRetry: () => _sendMessage(_lastSentUserText),
                        onUseFaq: () =>
                            _useOfflineFaqFallback(_lastSentUserText),
                      );
                    },
                  ),
          ),
          _buildQuickChips(chips),
          _buildInputBar(context, lang, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, String lang, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.forestGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Support',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                lang == 'id'
                    ? '🟢 Gemini AI Concierge — Online'
                    : '🟢 Gemini AI Concierge — Online',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(List<(String, String)> chips) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final (label, prompt) = chips[i];
          return ActionChip(
            label: Text(label, style: const TextStyle(fontSize: 12)),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            backgroundColor: AppColors.coral.withValues(alpha: 0.12),
            side: BorderSide(
              color: AppColors.coral.withValues(alpha: 0.40),
              width: 1,
            ),
            labelStyle: const TextStyle(
              color: AppColors.coral,
              fontWeight: FontWeight.w600,
            ),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, String lang, bool isDark) {
    final inputBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = AppColors.border(context);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        decoration: BoxDecoration(
          color: inputBg,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppColors.text(context), fontSize: 14),
                decoration: InputDecoration(
                  hintText: lang == 'id'
                      ? 'Ketik pesanmu ke Gemini Support...'
                      : 'Type your message...',
                  hintStyle:
                      TextStyle(color: AppColors.subtext(context), fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                        color: AppColors.forestGreen, width: 1.5),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkScaffold.withValues(alpha: 0.5)
                      : AppColors.cream.withValues(alpha: 0.6),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  isDense: true,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (ctx, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasText
                        ? AppColors.forestGreen
                        : AppColors.border(context),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                    onPressed:
                        hasText ? () => _sendMessage(_controller.text) : null,
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble Widget ─────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final SupportChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onUseFaq;

  const _MessageBubble({
    required this.message,
    this.onRetry,
    this.onUseFaq,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = AppColors.isDark(context);

    final bubbleColor = isUser
        ? AppColors.forestGreen
        : (isDark ? AppColors.darkCard : Colors.white);
    final textColor = isUser ? Colors.white : AppColors.text(context);

    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: 6,
              bottom: 2,
              left: isUser ? 56 : 0,
              right: isUser ? 0 : 56,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: message.hasError
                  ? Border.all(color: AppColors.coral.withValues(alpha: 0.6))
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                _buildRichText(message.text, textColor),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.hasError) ...[
                      const Icon(Icons.error_outline_rounded,
                          size: 11, color: AppColors.coral),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser
                            ? Colors.white.withValues(alpha: 0.65)
                            : AppColors.subtext(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (message.hasError && onRetry != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2, bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded,
                        size: 14, color: AppColors.coral),
                    label: const Text(
                      'Coba Lagi',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.coral,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onUseFaq != null) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: onUseFaq,
                      icon: const Icon(Icons.help_outline_rounded,
                          size: 14, color: AppColors.forestGreen),
                      label: const Text(
                        'Jawaban Cepat FAQ',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.forestGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRichText(String text, Color color) {
    final cleaned = SupportChatService.cleanAsterisks(text);
    return RichText(
      text: TextSpan(
        text: cleaned,
        style: TextStyle(fontSize: 13.5, color: color, height: 1.45),
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  final AnimationController controller;

  const _TypingBubble({required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final bubbleColor = isDark ? AppColors.darkCard : Colors.white;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 6, bottom: 2, right: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _DotsIndicator(controller: controller),
      ),
    );
  }
}

class _DotsIndicator extends AnimatedWidget {
  const _DotsIndicator({required AnimationController controller})
      : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value;
    final dotColor = AppColors.subtext(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (t + i * 0.33) % 1.0;
        final scale = 0.6 + 0.4 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      }),
    );
  }
}
