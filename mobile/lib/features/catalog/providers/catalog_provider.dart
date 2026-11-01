import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/catalog_data.dart';
import '../../cart/models/cart_item_model.dart';

class StockHistoryLog {
  final String id;
  final String productId;
  final String productName;
  final int previousStock;
  final int newStock;
  final int delta;
  final String reason;
  final DateTime timestamp;

  const StockHistoryLog({
    required this.id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    required this.delta,
    required this.reason,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'previousStock': previousStock,
    'newStock': newStock,
    'delta': delta,
    'reason': reason,
    'timestamp': timestamp.toIso8601String(),
  };

  factory StockHistoryLog.fromJson(Map<String, dynamic> json) => StockHistoryLog(
    id: json['id'] as String? ?? '',
    productId: json['productId'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    previousStock: (json['previousStock'] as int?) ?? 0,
    newStock: (json['newStock'] as int?) ?? 0,
    delta: (json['delta'] as int?) ?? 0,
    reason: json['reason'] as String? ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
  );
}

class CatalogProductsState {
  final List<ProductItem> products;
  final List<StockHistoryLog> stockLogs;
  final bool isLoading;
  final String? error;

  const CatalogProductsState({
    this.products = const [],
    this.stockLogs = const [],
    this.isLoading = false,
    this.error,
  });

  CatalogProductsState copyWith({
    List<ProductItem>? products,
    List<StockHistoryLog>? stockLogs,
    bool? isLoading,
    String? error,
  }) {
    return CatalogProductsState(
      products: products ?? this.products,
      stockLogs: stockLogs ?? this.stockLogs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CatalogProductsNotifier extends StateNotifier<CatalogProductsState> {
  static const String _storageKeyProducts = 'bun_catalog_products';
  static const String _storageKeyLogs = 'bun_inventory_logs';

  CatalogProductsNotifier() : super(const CatalogProductsState()) {
    _initCatalog();
  }

  Future<void> _initCatalog() async {
    state = state.copyWith(isLoading: true);
    try {
      List<ProductItem> loadedProducts = [];

      // Check SQLite or memory fallback
      final customJson = await _loadStoredJson(_storageKeyProducts);
      if (customJson != null && customJson.isNotEmpty) {
        try {
          final list = jsonDecode(customJson) as List<dynamic>;
          loadedProducts = list.map((item) => ProductItem.fromMap(item as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      // If nothing saved yet, seed from CatalogData.allProducts
      if (loadedProducts.isEmpty) {
        loadedProducts = List<ProductItem>.from(CatalogData.allProducts);
      } else {
        // Ensure any newly introduced products in CatalogData are merged
        final existingIds = loadedProducts.map((p) => p.id).toSet();
        for (final p in CatalogData.allProducts) {
          if (!existingIds.contains(p.id)) {
            loadedProducts.add(p);
          }
        }
      }

      // Load stock logs
      List<StockHistoryLog> loadedLogs = [];
      final logsJson = await _loadStoredJson(_storageKeyLogs);
      if (logsJson != null && logsJson.isNotEmpty) {
        try {
          final list = jsonDecode(logsJson) as List<dynamic>;
          loadedLogs = list.map((l) => StockHistoryLog.fromJson(l as Map<String, dynamic>)).toList();
        } catch (_) {}
      }

      state = state.copyWith(
        products: loadedProducts,
        stockLogs: loadedLogs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        products: List<ProductItem>.from(CatalogData.allProducts),
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  static final Map<String, String> _localJsonCache = {};

  Future<void> _saveStoredJson(String key, String value) async {
    _localJsonCache[key] = value;
  }

  Future<String?> _loadStoredJson(String key) async {
    return _localJsonCache[key];
  }

  Future<void> _persist() async {
    final payload = jsonEncode(state.products.map((p) => p.toMap()).toList());
    await _saveStoredJson(_storageKeyProducts, payload);

    final logsPayload = jsonEncode(state.stockLogs.map((l) => l.toJson()).toList());
    await _saveStoredJson(_storageKeyLogs, logsPayload);
  }

  ProductItem? getProductById(String id) {
    try {
      return state.products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Menu Management Actions ──────────────────────────────────────────────

  Future<void> addProduct(ProductItem newProduct) async {
    state = state.copyWith(
      products: [newProduct, ...state.products],
    );

    _logStockChange(
      productId: newProduct.id,
      productName: newProduct.name,
      previousStock: 0,
      newStock: newProduct.stock,
      reason: 'Produk Baru Ditambahkan',
    );

    await _persist();
  }

  Future<void> updateProduct(ProductItem updatedProduct) async {
    final oldIndex = state.products.indexWhere((p) => p.id == updatedProduct.id);
    if (oldIndex < 0) return;

    final oldProduct = state.products[oldIndex];
    final updatedList = List<ProductItem>.from(state.products);
    updatedList[oldIndex] = updatedProduct;

    state = state.copyWith(products: updatedList);

    if (oldProduct.stock != updatedProduct.stock) {
      _logStockChange(
        productId: updatedProduct.id,
        productName: updatedProduct.name,
        previousStock: oldProduct.stock,
        newStock: updatedProduct.stock,
        reason: 'Pembaruan Detail Produk',
      );
    }

    await _persist();
  }

  Future<void> updatePrice(String productId, int newPrice) async {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(price: newPrice);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  Future<void> toggleAvailability(String productId, bool isAvailable) async {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(isAvailable: isAvailable);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  Future<void> toggleBestSeller(String productId, bool isBestSeller) async {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(isBestSeller: isBestSeller);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  Future<void> toggleChefsPick(String productId, bool isChefsPick) async {
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(isChefsPick: isChefsPick);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  Future<void> deleteProduct(String productId) async {
    // Soft-deactivate by setting isAvailable = false and stock = 0 to preserve past orders
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(isAvailable: false, stock: 0);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  // ─── Inventory Management Actions ─────────────────────────────────────────

  Future<void> setStock(String productId, int newStock, {String reason = 'Penyesuaian Manual'}) async {
    final safeStock = newStock < 0 ? 0 : newStock;
    ProductItem? target;

    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          target = p;
          return p.copyWith(
            stock: safeStock,
            isAvailable: safeStock > 0 ? p.isAvailable : false,
          );
        }
        return p;
      }).toList(),
    );

    if (target != null) {
      _logStockChange(
        productId: productId,
        productName: target!.name,
        previousStock: target!.stock,
        newStock: safeStock,
        reason: reason,
      );
    }

    await _persist();
  }

  Future<void> adjustStock(String productId, int delta, {required String reason}) async {
    ProductItem? target;
    int calculated = 0;

    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          target = p;
          calculated = p.stock + delta;
          if (calculated < 0) calculated = 0;
          return p.copyWith(
            stock: calculated,
            isAvailable: calculated > 0 ? (p.stock == 0 ? true : p.isAvailable) : false,
          );
        }
        return p;
      }).toList(),
    );

    if (target != null) {
      _logStockChange(
        productId: productId,
        productName: target!.name,
        previousStock: target!.stock,
        newStock: calculated,
        reason: reason,
      );
    }

    await _persist();
  }

  Future<void> setMinStockThreshold(String productId, int minStock) async {
    final safeMin = minStock < 0 ? 0 : minStock;
    state = state.copyWith(
      products: state.products.map((p) {
        if (p.id == productId) {
          return p.copyWith(minStock: safeMin);
        }
        return p;
      }).toList(),
    );
    await _persist();
  }

  // Deduct stock when an order is created
  bool deductStockForOrder(List<CartItem> cartItems) {
    // 1. Verify availability and stock for all items first
    for (final item in cartItems) {
      final product = getProductById(item.product.id);
      if (product == null || product.isOutOfStock || product.stock < item.quantity) {
        return false;
      }
    }

    // 2. Perform atomic deduction
    final updatedList = List<ProductItem>.from(state.products);
    for (final item in cartItems) {
      final index = updatedList.indexWhere((p) => p.id == item.product.id);
      if (index >= 0) {
        final current = updatedList[index];
        final nextStock = current.stock - item.quantity;
        updatedList[index] = current.copyWith(
          stock: nextStock < 0 ? 0 : nextStock,
          isAvailable: nextStock > 0 ? current.isAvailable : false,
        );

        _logStockChange(
          productId: current.id,
          productName: current.name,
          previousStock: current.stock,
          newStock: nextStock < 0 ? 0 : nextStock,
          reason: 'Transaksi Pesanan (${item.quantity}x)',
        );
      }
    }

    state = state.copyWith(products: updatedList);
    _persist();
    return true;
  }

  // Restore stock when an order is cancelled
  void restoreStockForOrderSummary(String itemsSummary) {
    // itemsSummary format: "2x OG Main Character, 1x Truffle Mac n Cheese"
    final entries = itemsSummary.split(',');
    for (final entry in entries) {
      final trimmed = entry.trim();
      final match = RegExp(r'^(\d+)x\s+(.+)$').firstMatch(trimmed);
      if (match != null) {
        final qty = int.tryParse(match.group(1) ?? '1') ?? 1;
        final name = match.group(2)?.trim() ?? '';

        final index = state.products.indexWhere((p) => p.name.toLowerCase() == name.toLowerCase());
        if (index >= 0) {
          final current = state.products[index];
          final nextStock = current.stock + qty;
          final updatedList = List<ProductItem>.from(state.products);
          updatedList[index] = current.copyWith(
            stock: nextStock,
            isAvailable: true,
          );
          state = state.copyWith(products: updatedList);

          _logStockChange(
            productId: current.id,
            productName: current.name,
            previousStock: current.stock,
            newStock: nextStock,
            reason: 'Pengembalian Stok (Pesanan Dibatalkan)',
          );
        }
      }
    }
    _persist();
  }

  void _logStockChange({
    required String productId,
    required String productName,
    required int previousStock,
    required int newStock,
    required String reason,
  }) {
    final log = StockHistoryLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}-${productId.substring(0, 3)}',
      productId: productId,
      productName: productName,
      previousStock: previousStock,
      newStock: newStock,
      delta: newStock - previousStock,
      reason: reason,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      stockLogs: [log, ...state.stockLogs.take(99)],
    );
  }
}

final catalogProductsProvider = StateNotifierProvider<CatalogProductsNotifier, CatalogProductsState>((ref) {
  return CatalogProductsNotifier();
});
