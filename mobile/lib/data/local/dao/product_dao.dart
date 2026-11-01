import 'package:flutter/foundation.dart';
import '../app_database.dart';
import 'package:sqflite/sqflite.dart';

class CachedProduct {
  final String id;
  final String categorySlug;
  final String name;
  final String slug;
  final String description;
  final String ingredients;
  final int priceIdr;
  final String imageUrl;
  final bool isAvailable;
  final bool isSpicy;
  final bool isBestSeller;
  final String cachedAt;

  CachedProduct({
    required this.id,
    required this.categorySlug,
    required this.name,
    required this.slug,
    required this.description,
    required this.ingredients,
    required this.priceIdr,
    required this.imageUrl,
    required this.isAvailable,
    required this.isSpicy,
    required this.isBestSeller,
    required this.cachedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_slug': categorySlug,
      'name': name,
      'slug': slug,
      'description': description,
      'ingredients': ingredients,
      'price_idr': priceIdr,
      'image_url': imageUrl,
      'is_available': isAvailable ? 1 : 0,
      'is_spicy': isSpicy ? 1 : 0,
      'is_best_seller': isBestSeller ? 1 : 0,
      'cached_at': cachedAt,
    };
  }

  factory CachedProduct.fromMap(Map<String, dynamic> map) {
    return CachedProduct(
      id: map['id'] as String,
      categorySlug: map['category_slug'] as String,
      name: map['name'] as String,
      slug: map['slug'] as String,
      description: map['description'] as String,
      ingredients: map['ingredients'] as String,
      priceIdr: map['price_idr'] as int,
      imageUrl: map['image_url'] as String,
      isAvailable: (map['is_available'] as int) == 1,
      isSpicy: (map['is_spicy'] as int) == 1,
      isBestSeller: (map['is_best_seller'] as int) == 1,
      cachedAt: map['cached_at'] as String,
    );
  }
}

class ProductDao {
  final AppDatabase _appDatabase;
  final List<CachedProduct> _inMemoryProducts = [];

  ProductDao({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase.instance;

  Future<List<CachedProduct>> getAllCachedProducts() async {
    if (kIsWeb) return List.unmodifiable(_inMemoryProducts);
    try {
      final db = await _appDatabase.database;
      final results = await db.query('cached_products', orderBy: 'name ASC');
      return results.map((map) => CachedProduct.fromMap(map)).toList();
    } catch (_) {
      return List.unmodifiable(_inMemoryProducts);
    }
  }

  Future<void> cacheProducts(List<CachedProduct> products) async {
    if (kIsWeb) {
      _inMemoryProducts.clear();
      _inMemoryProducts.addAll(products);
      return;
    }
    try {
      final db = await _appDatabase.database;
      final batch = db.batch();
      for (final p in products) {
        batch.insert('cached_products', p.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (_) {
      _inMemoryProducts.clear();
      _inMemoryProducts.addAll(products);
    }
  }

  Future<void> clearCache() async {
    if (kIsWeb) {
      _inMemoryProducts.clear();
      return;
    }
    try {
      final db = await _appDatabase.database;
      await db.delete('cached_products');
    } catch (_) {
      _inMemoryProducts.clear();
    }
  }
}
