import 'package:flutter_riverpod/flutter_riverpod.dart';

class PromotionItem {
  final String id;
  final String code;
  final String description;
  final String discountType; // 'PERCENT' | 'FIXED'
  final int discountValue;
  final int minPurchase;
  final DateTime startDate;
  final DateTime endDate;
  final String? targetCategory; // null = all categories
  final bool isActive;

  const PromotionItem({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minPurchase = 0,
    required this.startDate,
    required this.endDate,
    this.targetCategory,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isCurrentlyValid => isActive && !isExpired && !isUpcoming;

  PromotionItem copyWith({
    String? code,
    String? description,
    String? discountType,
    int? discountValue,
    int? minPurchase,
    DateTime? startDate,
    DateTime? endDate,
    String? targetCategory,
    bool? isActive,
  }) {
    return PromotionItem(
      id: id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minPurchase: minPurchase ?? this.minPurchase,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      targetCategory: targetCategory ?? this.targetCategory,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'discountType': discountType,
    'discountValue': discountValue,
    'minPurchase': minPurchase,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'targetCategory': targetCategory,
    'isActive': isActive,
  };

  factory PromotionItem.fromJson(Map<String, dynamic> json) => PromotionItem(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    description: json['description'] as String? ?? '',
    discountType: json['discountType'] as String? ?? 'PERCENT',
    discountValue: (json['discountValue'] as int?) ?? 0,
    minPurchase: (json['minPurchase'] as int?) ?? 0,
    startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    targetCategory: json['targetCategory'] as String?,
    isActive: json['isActive'] == true || json['isActive'] == 1,
  );
}

class PromotionsState {
  final List<PromotionItem> promotions;
  final bool isLoading;

  const PromotionsState({
    this.promotions = const [],
    this.isLoading = false,
  });

  PromotionsState copyWith({
    List<PromotionItem>? promotions,
    bool? isLoading,
  }) {
    return PromotionsState(
      promotions: promotions ?? this.promotions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class PromotionsNotifier extends StateNotifier<PromotionsState> {
  PromotionsNotifier() : super(const PromotionsState()) {
    _initDefaultPromotions();
  }

  void _initDefaultPromotions() {
    state = state.copyWith(
      promotions: [
        PromotionItem(
          id: 'prm-01',
          code: 'BUNCHEESE10',
          description: 'Diskon 10% untuk semua menu burger & bakes pilihan',
          discountType: 'PERCENT',
          discountValue: 10,
          minPurchase: 50000,
          startDate: DateTime.now().subtract(const Duration(days: 5)),
          endDate: DateTime.now().add(const Duration(days: 25)),
          isActive: true,
        ),
        PromotionItem(
          id: 'prm-02',
          code: 'CRAVE20',
          description: 'Potongan langsung Rp 20.000 untuk pembelian minimal Rp 100.000',
          discountType: 'FIXED',
          discountValue: 20000,
          minPurchase: 100000,
          startDate: DateTime.now().subtract(const Duration(days: 2)),
          endDate: DateTime.now().add(const Duration(days: 14)),
          isActive: true,
        ),
        PromotionItem(
          id: 'prm-03',
          code: 'WEEKENDSTACK',
          description: 'Diskon akhir pekan 15% untuk Croissant Burgers & Desserts',
          discountType: 'PERCENT',
          discountValue: 15,
          minPurchase: 75000,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 7)),
          targetCategory: 'croissant',
          isActive: true,
        ),
      ],
    );
  }

  void addPromotion(PromotionItem promo) {
    state = state.copyWith(
      promotions: [promo, ...state.promotions],
    );
  }

  void updatePromotion(PromotionItem updated) {
    state = state.copyWith(
      promotions: state.promotions.map((p) => p.id == updated.id ? updated : p).toList(),
    );
  }

  void toggleActive(String id) {
    state = state.copyWith(
      promotions: state.promotions.map((p) {
        if (p.id == id) {
          return p.copyWith(isActive: !p.isActive);
        }
        return p;
      }).toList(),
    );
  }

  void deletePromotion(String id) {
    state = state.copyWith(
      promotions: state.promotions.where((p) => p.id != id).toList(),
    );
  }

  int calculateDiscount({required String code, required int subtotal}) {
    final promo = state.promotions.firstWhere(
      (p) => p.code.toUpperCase() == code.trim().toUpperCase() && p.isCurrentlyValid,
      orElse: () => throw Exception('Promo tidak valid'),
    );

    if (subtotal < promo.minPurchase) {
      return 0;
    }

    if (promo.discountType == 'PERCENT') {
      return (subtotal * (promo.discountValue / 100)).round();
    } else {
      return promo.discountValue > subtotal ? subtotal : promo.discountValue;
    }
  }
}

final promotionsProvider = StateNotifierProvider<PromotionsNotifier, PromotionsState>((ref) {
  return PromotionsNotifier();
});
