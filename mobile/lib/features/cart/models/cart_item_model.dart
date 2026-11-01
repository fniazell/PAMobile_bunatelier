import 'dart:convert';
import '../../../data/mock/catalog_data.dart';
import '../../../data/local/dao/cart_dao.dart';

class CartItem {
  final String id;
  final ProductItem product;
  final int quantity;
  final List<ProductAddonItem> selectedAddons;
  final ProductAddonItem? selectedSauce;
  final String? notes;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.selectedAddons = const [],
    this.selectedSauce,
    this.notes,
  });

  int get unitPrice {
    int price = product.price;
    for (final addon in selectedAddons) {
      price += addon.price;
    }
    if (selectedSauce != null) {
      price += selectedSauce!.price;
    }
    return price;
  }

  int get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    List<ProductAddonItem>? selectedAddons,
    ProductAddonItem? selectedSauce,
    String? notes,
  }) {
    return CartItem(
      id: id,
      product: product,
      quantity: quantity ?? this.quantity,
      selectedAddons: selectedAddons ?? this.selectedAddons,
      selectedSauce: selectedSauce ?? this.selectedSauce,
      notes: notes ?? this.notes,
    );
  }

  LocalCartItem toLocalCartItem() {
    final addonsPayload = {
      'addons': selectedAddons.map((a) => {'id': a.id, 'name': a.name, 'price': a.price}).toList(),
      'sauce': selectedSauce != null
          ? {'id': selectedSauce!.id, 'name': selectedSauce!.name, 'price': selectedSauce!.price}
          : null,
    };

    return LocalCartItem(
      id: id,
      productId: product.id,
      productName: product.name,
      unitPrice: unitPrice,
      quantity: quantity,
      addonsJson: jsonEncode(addonsPayload),
      notes: notes,
      createdAt: DateTime.now().toIso8601String(),
    );
  }
}
