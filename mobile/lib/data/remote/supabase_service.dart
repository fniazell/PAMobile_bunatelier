import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../features/orders/models/order_model.dart';
import '../../features/branch/models/branch_model.dart';
import '../../features/cart/models/cart_item_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  factory SupabaseService() => instance;
  SupabaseService._internal();

  // Supabase Configuration
  // Project: wpfizausricpcartojns
  static const String _defaultUrl = 'https://wpfizausricpcartojns.supabase.co';
  static const String _defaultKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndwZml6YXVzcmljcGNhcnRvam5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI5OTIzMDYsImV4cCI6MjEwODU2ODMwNn0.LVVluMF-X6ZZ4fM7RtRMSLUfsrzoOviOds-Hd2WQ3YQ';

  String projectUrl = const String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );
  String anonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: _defaultKey,
  );

  Dio get _dio => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Prefer': 'resolution=merge-duplicates,return=representation',
      },
    ),
  );

  /// Cek status koneksi ke Supabase Online
  Future<bool> isOnline() async {
    try {
      final response = await _dio.get('$projectUrl/rest/v1/orders?limit=1');
      return response.statusCode == 200 || response.statusCode == 206;
    } catch (_) {
      return false;
    }
  }

  /// Sinkronisasi pesanan ke tabel 'orders' di Supabase Cloud
  Future<bool> syncOrderToCloud(OrderItemModel order) async {
    try {
      final payload = {
        'id': order.id,
        if (order.userId != null && order.userId!.isNotEmpty)
          'user_id': order.userId,
        'order_number': order.orderNumber,
        'created_at': order.createdAt.toIso8601String(),
        'order_type': order.orderType,
        'payment_method': order.paymentMethod,
        'payment_status': order.paymentStatus,
        'status': order.status,
        'customer_name': order.customerName,
        if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
          'customer_phone': order.customerPhone,
        'subtotal': order.subtotal,
        'tax': order.tax,
        'delivery_fee': order.deliveryFee,
        'total': order.total,
        'items_summary': order.itemsSummary,
        'delivery_address': order.deliveryAddress,
        'notes': order.notes,
        if (order.branchId != null) 'branch_id': order.branchId,
        if (order.branchName != null) 'branch_name': order.branchName,
        if (order.branchTimezone != null)
          'branch_timezone': order.branchTimezone,
        if (order.branchCurrency != null)
          'branch_currency': order.branchCurrency,
        if (order.receiptHash != null) 'receipt_hash': order.receiptHash,
        if (order.receiptBlockchainTxHash != null)
          'receipt_tx_hash': order.receiptBlockchainTxHash,
      };

      final response = await _dio.post(
        '$projectUrl/rest/v1/orders',
        data: payload,
        options: Options(headers: {'Prefer': 'return=representation'}),
      );

      debugPrint('Supabase syncOrder response: ${response.statusCode}');
      final success = response.statusCode == 201 || response.statusCode == 200;
      if (!success) {
        debugPrint(
          'Supabase order INSERT failed with HTTP ${response.statusCode}: '
          '${response.data}',
        );
      }
      return success;
    } on DioException catch (e) {
      debugPrint(
        'Supabase order INSERT failed: HTTP ${e.response?.statusCode ?? 'no response'}; '
        '${e.response?.data ?? e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('Supabase order INSERT failed: $e');
      return false;
    }
  }

  /// Sinkronisasi item detail pesanan ke tabel 'order_items' di Supabase Cloud
  Future<bool> syncOrderItemsToCloud(String orderId, List<CartItem> items) async {
    try {
      if (items.isEmpty) return true;
      final payload = items.map((item) {
        return {
          'id': '${orderId}_${item.product.id}',
          'order_id': orderId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'total_price': item.totalPrice,
          'customization': item.notes ?? '',
          'created_at': DateTime.now().toIso8601String(),
        };
      }).toList();

      final response = await _dio.post(
        '$projectUrl/rest/v1/order_items',
        data: payload,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Supabase syncOrderItems offline: $e');
      return false;
    }
  }

  /// Ambil daftar pesanan berdasarkan user_id dari Supabase Cloud
  Future<List<OrderItemModel>> fetchOrdersForUser(String userId) async {
    try {
      final response = await _dio.get(
        '$projectUrl/rest/v1/orders?user_id=eq.$userId&select=*&order=created_at.desc',
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return OrderItemModel.fromMap(m);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase fetchOrdersForUser offline: $e');
      return [];
    }
  }

  /// Ambil seluruh pesanan dari Supabase Cloud (untuk sinkronisasi Admin)
  Future<List<OrderItemModel>> fetchAllCloudOrders() async {
    try {
      final response = await _dio.get(
        '$projectUrl/rest/v1/orders?select=*&order=created_at.desc',
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return OrderItemModel.fromMap(m);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase fetchAllCloudOrders offline: $e');
      return [];
    }
  }

  /// Update receipt hash & transaction hash pada order di Supabase Cloud
  Future<bool> updateCloudOrderReceipt({
    required String orderId,
    required String receiptHash,
    required String txHash,
  }) async {
    try {
      final response = await _dio.patch(
        '$projectUrl/rest/v1/orders?id=eq.$orderId',
        data: {
          'receipt_hash': receiptHash,
          'receipt_tx_hash': txHash,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Supabase updateCloudOrderReceipt offline: $e');
      return false;
    }
  }

  /// Update status pesanan di Supabase Cloud
  Future<bool> updateCloudOrderStatus(String orderId, String newStatus) async {
    try {
      final response = await _dio.patch(
        '$projectUrl/rest/v1/orders?id=eq.$orderId',
        data: {'status': newStatus},
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Supabase updateStatus offline: $e');
      return false;
    }
  }

  /// Sinkronisasi profil pengguna ke tabel 'users' di Supabase Cloud
  Future<bool> syncUserToCloud({
    required String id,
    required String fullName,
    required String email,
    required String role,
    required String username,
    String? phone,
  }) async {
    try {
      final payload = {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'username': username,
        'phone': phone ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _dio.post(
        '$projectUrl/rest/v1/users',
        data: payload,
      );

      debugPrint('Supabase syncUser response: ${response.statusCode}');
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Supabase syncUser offline fallback: $e');
      return false;
    }
  }

  /// Ambil daftar cabang dari Supabase Cloud (tabel 'branches')
  Future<List<BranchModel>> fetchBranches() async {
    try {
      final response = await _dio.get(
        '$projectUrl/rest/v1/branches?select=*&order=id.asc',
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list
            .map(
              (item) =>
                  BranchModel.fromMap(Map<String, dynamic>.from(item as Map)),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase fetchBranches offline/fallback: $e');
      return [];
    }
  }

  /// Update data cabang di Supabase Cloud (tabel 'branches')
  Future<bool> updateBranchOnCloud(BranchModel branch) async {
    try {
      final payload = {
        'name': branch.name,
        'city': branch.city,
        'country': branch.country,
        'address': branch.address,
        'latitude': branch.latitude,
        'longitude': branch.longitude,
        'maps_query': branch.mapsQuery,
        'maps_url': branch.mapsUrl,
        'operating_hours': branch.operatingHours,
        'phone': branch.phone,
        'timezone': branch.timezone,
        'currency_code': branch.currencyCode,
        'is_active': branch.isActive,
        'is_verified': branch.isVerified,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _dio.patch(
        '$projectUrl/rest/v1/branches?id=eq.${branch.id}',
        data: payload,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Supabase updateBranch offline: $e');
      return false;
    }
  }

  /// Update kredensial Supabase secara dinamis jika diperlukan
  void configure({required String url, required String key}) {
    projectUrl = url.trim();
    anonKey = key.trim();
    _dio.options.headers['apikey'] = anonKey;
    _dio.options.headers['Authorization'] = 'Bearer $anonKey';
  }
}
