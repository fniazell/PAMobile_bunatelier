import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../data/mock/catalog_data.dart';
import '../../cart/providers/cart_provider.dart';
import '../../catalog/providers/catalog_provider.dart';
import '../../support/services/support_chat_service.dart';
import '../services/ai_currency_advisor.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? recommendedProductId;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.recommendedProductId,
    required this.timestamp,
  });
}

class BuddyAiScreen extends ConsumerStatefulWidget {
  const BuddyAiScreen({super.key});

  @override
  ConsumerState<BuddyAiScreen> createState() => _BuddyAiScreenState();
}

class _BuddyAiScreenState extends ConsumerState<BuddyAiScreen> {
  final _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final SupportChatService _chatService = SupportChatService();
  bool _isTyping = false;

  final List<String> _suggestedPrompts = [
    'How much is The Main Character in USD?',
    'Berapa perkiraan total pesananku dalam euro?',
    'Rekomendasikan burger pedas di bawah 70 ribu',
    'What is the price of Crunch Culture in SGD?',
    'Ceritakan tentang burger croissant',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Halo! Aku Bun Buddy 🍔, customer service & konsultan burger Bun Atelier. Tanya apa saja—soal menu, harga dalam mata uang asing (USD, EUR, SGD), perkiraan total pesanan, atau rekomendasi burger favoritmu!',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(
        ChatMessage(text: trimmed, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _messageController.clear();

    // 1. Process Global Converter Currency Query if detected
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

    final history = _messages
        .map(
          (m) => SupportChatMessage(
            text: m.text,
            isUser: m.isUser,
            timestamp: m.timestamp,
          ),
        )
        .toList();

    final result = await _chatService.sendMessage(
      message: trimmed,
      history: history,
      currencyContext: currencyResolution?.toMap(),
    );

    if (!mounted) return;
    final cleanReply = SupportChatService.cleanAsterisks(result.reply);

    // Detect recommended product to show interactive card
    String? productId;
    if (currencyResolution?.productName != null) {
      final p = CatalogData.allProducts.firstWhere(
        (prod) => prod.name.toLowerCase() == currencyResolution!.productName!.toLowerCase(),
        orElse: () => CatalogData.allProducts.first,
      );
      productId = p.id;
    } else {
      productId = result.success ? _detectRecommendedProduct(cleanReply) : null;
    }

    setState(() {
      _isTyping = false;
      _messages.add(
        ChatMessage(
          text: cleanReply,
          isUser: false,
          recommendedProductId: productId,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  String? _detectRecommendedProduct(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('truffle butter') ||
        lower.contains('paling mahal') ||
        lower.contains('termahal')) {
      return 'b-06';
    } else if (lower.contains('lowkey spicy')) {
      return 'b-08';
    } else if (lower.contains('dr pepper')) {
      return 'dr-08';
    } else if (lower.contains('root beer') || lower.contains('float')) {
      return 'dr-07';
    } else if (lower.contains('hash brown')) {
      return 'sd-07';
    } else if (lower.contains('mac') || lower.contains('mac n cheese')) {
      return 'sd-06';
    } else if (lower.contains('hot mess') ||
        lower.contains('pedas') ||
        lower.contains('pedes') ||
        lower.contains('spicy')) {
      return 'b-02';
    } else if (lower.contains('og main') ||
        lower.contains('og burger') ||
        lower.contains('flagship')) {
      return 'b-01';
    } else if (lower.contains('touch grass') ||
        lower.contains('paling murah') ||
        lower.contains('termurah') ||
        lower.contains('plant') ||
        lower.contains('nabati')) {
      return 'b-04';
    } else if (lower.contains('crunch culture') ||
        lower.contains('ayam') ||
        lower.contains('chicken')) {
      return 'b-03';
    } else if (lower.contains('no cap') ||
        lower.contains('cheddar') ||
        lower.contains('keju')) {
      return 'b-05';
    } else if (lower.contains('croissant') ||
        lower.contains('pastrami') ||
        lower.contains('flaky')) {
      return 'c-01';
    } else if (lower.contains('fries') || lower.contains('kentang')) {
      return 'sd-01';
    } else if (lower.contains('waffle') ||
        lower.contains('dessert') ||
        lower.contains('manis') ||
        lower.contains('penutup')) {
      return 'ds-01';
    } else if (lower.contains('gelato') ||
        lower.contains('es krim') ||
        lower.contains('ice cream')) {
      return 'ds-02';
    } else if (lower.contains('muffin') || lower.contains('choc melt')) {
      return 'ds-03';
    } else if (lower.contains('pancake') || lower.contains('souffle')) {
      return 'ds-04';
    } else if (lower.contains('panna cotta')) {
      return 'ds-05';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.coral,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUN BUDDY AI',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Powered by Gemini Context Engine',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.forestGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Suggested Prompts
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      backgroundColor: AppColors.white,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.forestGreen,
                        ),
                      ),
                      onPressed: _isTyping ? null : () => _sendMessage(prompt),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 12),

            // Messages List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),

            if (_isTyping) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.coral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Bun Buddy is thinking...',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mutedText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Input Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.espresso.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: _isTyping ? null : _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Ask about tastes, pairings, budget...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppColors.coral,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: _isTyping
                          ? null
                          : () => _sendMessage(_messageController.text),
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

  Widget _buildChatBubble(ChatMessage msg) {
    ProductItem? recProduct;
    if (msg.recommendedProductId != null) {
      recProduct = CatalogData.allProducts.firstWhere(
        (p) => p.id == msg.recommendedProductId,
        orElse: () => CatalogData.allProducts.first,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.forestGreen,
              child: Icon(
                Icons.lunch_dining_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: msg.isUser ? AppColors.coral : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: msg.isUser
                        ? null
                        : Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.espresso.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? AppColors.white : AppColors.espresso,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
                if (recProduct != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/product/${recProduct!.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.butterYellow.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.coral.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: recProduct.imageUrl.startsWith('assets/')
                                ? Image.asset(
                                    recProduct.imageUrl,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  )
                                : Image.network(
                                    recProduct.imageUrl,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recProduct.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Rp ${recProduct.price} • View Menu →',
                                style: const TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.coral,
              child: Icon(Icons.person, size: 18, color: AppColors.white),
            ),
          ],
        ],
      ),
    );
  }
}
