import 'package:flutter/foundation.dart';
import '../app_database.dart';
import 'package:sqflite/sqflite.dart';

class LocalCartItem {
  final String id;
  final String productId;
  final String productName;
  final int unitPrice;
  final int quantity;
  final String addonsJson;
  final String? notes;
  final String createdAt;

  LocalCartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.addonsJson = '[]',
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'unit_price': unitPrice,
      'quantity': quantity,
      'addons_json': addonsJson,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory LocalCartItem.fromMap(Map<String, dynamic> map) {
    return LocalCartItem(
      id: map['id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      unitPrice: map['unit_price'] as int,
      quantity: map['quantity'] as int,
      addonsJson: map['addons_json'] as String? ?? '[]',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}

class CartDao {
  final AppDatabase _appDatabase;
  final List<LocalCartItem> _inMemoryItems = [];

  CartDao({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<List<LocalCartItem>> getAllItems() async {
    if (kIsWeb) {
      return List.unmodifiable(_inMemoryItems);
    }
    try {
      final db = await _appDatabase.database;
      final results = await db.query('local_cart', orderBy: 'created_at ASC');
      return results.map((map) => LocalCartItem.fromMap(map)).toList();
    } catch (_) {
      return List.unmodifiable(_inMemoryItems);
    }
  }

  Future<void> insertOrUpdate(LocalCartItem item) async {
    if (kIsWeb) {
      final index = _inMemoryItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        _inMemoryItems[index] = item;
      } else {
        _inMemoryItems.add(item);
      }
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.insert('local_cart', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {
      final index = _inMemoryItems.indexWhere((i) => i.id == item.id);
      if (index >= 0) {
        _inMemoryItems[index] = item;
      } else {
        _inMemoryItems.add(item);
      }
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    if (kIsWeb) {
      if (quantity <= 0) {
        _inMemoryItems.removeWhere((i) => i.id == id);
      } else {
        final index = _inMemoryItems.indexWhere((i) => i.id == id);
        if (index >= 0) {
          final item = _inMemoryItems[index];
          _inMemoryItems[index] = LocalCartItem(
            id: item.id,
            productId: item.productId,
            productName: item.productName,
            unitPrice: item.unitPrice,
            quantity: quantity,
            addonsJson: item.addonsJson,
            notes: item.notes,
            createdAt: item.createdAt,
          );
        }
      }
      return;
    }
    try {
      final db = await _appDatabase.database;
      if (quantity <= 0) {
        await db.delete('local_cart', where: 'id = ?', whereArgs: [id]);
      } else {
        await db.update('local_cart', {'quantity': quantity}, where: 'id = ?', whereArgs: [id]);
      }
    } catch (_) {}
  }

  Future<void> removeItem(String id) async {
    if (kIsWeb) {
      _inMemoryItems.removeWhere((i) => i.id == id);
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.delete('local_cart', where: 'id = ?', whereArgs: [id]);
    } catch (_) {
      _inMemoryItems.removeWhere((i) => i.id == id);
    }
  }

  Future<void> clearCart() async {
    if (kIsWeb) {
      _inMemoryItems.clear();
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.delete('local_cart');
    } catch (_) {
      _inMemoryItems.clear();
    }
  }
}
