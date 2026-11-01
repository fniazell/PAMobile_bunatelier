import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item_model.dart';
import '../../../data/local/dao/cart_dao.dart';

class CartState {
  final List<CartItem> items;
  final bool isLoading;

  const CartState({
    this.items = const [],
    this.isLoading = false,
  });

  int get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get tax => (subtotal * 0.1).round(); // 10% PB1 tax
  int get deliveryFee => items.isEmpty ? 0 : 12000;
  int get totalWithDelivery => subtotal + tax + deliveryFee;
  int get totalForPickup => subtotal + tax;
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final CartDao _cartDao = CartDao();

  CartNotifier() : super(const CartState()) {
    _loadFromDatabase();
  }

  Future<void> _loadFromDatabase() async {
    state = state.copyWith(isLoading: true);
    // Future sync with SQLite
    state = state.copyWith(isLoading: false);
  }

  void addItem(CartItem newItem) {
    // Check if item with same product and exact same addons/sauce already exists
    final index = state.items.indexWhere(
      (item) =>
          item.product.id == newItem.product.id &&
          item.selectedSauce?.id == newItem.selectedSauce?.id &&
          _areAddonsEqual(item.selectedAddons, newItem.selectedAddons),
    );

    if (index >= 0) {
      final existing = state.items[index];
      final updated = existing.copyWith(quantity: existing.quantity + newItem.quantity);
      final updatedList = [...state.items];
      updatedList[index] = updated;
      state = state.copyWith(items: updatedList);
      _cartDao.insertOrUpdate(updated.toLocalCartItem());
    } else {
      state = state.copyWith(items: [...state.items, newItem]);
      _cartDao.insertOrUpdate(newItem.toLocalCartItem());
    }
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }

    final updatedList = state.items.map((item) {
      if (item.id == id) {
        final updated = item.copyWith(quantity: quantity);
        _cartDao.updateQuantity(id, quantity);
        return updated;
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedList);
  }

  void removeItem(String id) {
    state = state.copyWith(items: state.items.where((i) => i.id != id).toList());
    _cartDao.removeItem(id);
  }

  void clearCart() {
    state = state.copyWith(items: const []);
    _cartDao.clearCart();
  }

  bool _areAddonsEqual(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    final idsA = a.map((e) => e.id).toSet();
    final idsB = b.map((e) => e.id).toSet();
    return idsA.containsAll(idsB);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
