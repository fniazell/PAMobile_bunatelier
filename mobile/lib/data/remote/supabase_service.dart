import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/secure_storage_service.dart';
import '../../features/saran_pesan/models/saran_pesan_model.dart';
import '../../features/feedback/models/feedback_model.dart';
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

  bool _initialized = false;

  bool get isInitialized => _initialized;

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Supabase has not been initialized.');
    }
    return Supabase.instance.client;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(url: projectUrl, publishableKey: anonKey);
    _initialized = true;
  }

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
  Future<bool> syncOrderItemsToCloud(
    String orderId,
    List<CartItem> items,
  ) async {
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
        data: {'receipt_hash': receiptHash, 'receipt_tx_hash': txHash},
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
    required String accessToken,
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
      };

      final response = await _dio.post(
        '$projectUrl/rest/v1/users?on_conflict=id',
        data: payload,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Prefer': 'resolution=merge-duplicates,return=representation',
          },
        ),
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

  /// Kirim feedback pelanggan ke Supabase Cloud (tabel 'feedbacks')
  Future<({bool success, String? error, FeedbackModel? feedback})> submitFeedback({
    required String orderId,
    required String userId,
    required int rating,
    String? customerName,
    String? comment,
    DateTime? createdAt,
  }) async {
    final timestamp = (createdAt ?? DateTime.now().toUtc()).toIso8601String();
    final payload = {
      'order_id': orderId,
      'user_id': userId,
      if (customerName != null && customerName.trim().isNotEmpty)
        'customer_name': customerName.trim(),
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty)
        'comment': comment.trim(),
      'created_at': timestamp,
    };

    // 1. Coba gunakan SupabaseClient jika sudah diinisialisasi
    if (_initialized) {
      try {
        final inserted = await client
            .from('feedbacks')
            .insert(payload)
            .select()
            .single();
        debugPrint('Supabase client feedback inserted to feedbacks table: $inserted');
        final created = FeedbackModel.fromMap(
          Map<String, dynamic>.from(inserted as Map),
        );
        return (success: true, error: null, feedback: created);
      } catch (e) {
        debugPrint('Supabase client insert to feedbacks table failed: $e');
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('pgrst205') || errStr.contains('schema cache')) {
          return (
            success: false,
            error:
                'Tabel feedbacks belum dibuat di Supabase. Silakan jalankan file supabase_feedback_migration.sql di Supabase SQL Editor.',
            feedback: null,
          );
        }
        if (errStr.contains('23505') ||
            errStr.contains('unique') ||
            errStr.contains('feedbacks_order_id')) {
          return (
            success: false,
            error: 'Pesanan ini sudah pernah diberikan penilaian/feedback.',
            feedback: null,
          );
        }
      }
    }

    // 2. Coba menggunakan REST API via Dio
    try {
      final token = await SecureStorageService().getAccessToken();
      final headers = <String, dynamic>{
        'apikey': anonKey,
        'Authorization': 'Bearer ${token ?? anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

      final response = await _dio.post(
        '$projectUrl/rest/v1/feedbacks',
        data: payload,
        options: Options(headers: headers),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        Map<String, dynamic>? itemMap;
        if (response.data is List && (response.data as List).isNotEmpty) {
          itemMap = Map<String, dynamic>.from((response.data as List).first as Map);
        } else if (response.data is Map) {
          itemMap = Map<String, dynamic>.from(response.data as Map);
        }
        final created = itemMap != null
            ? FeedbackModel.fromMap(itemMap)
            : FeedbackModel(
                orderId: orderId,
                userId: userId,
                customerName: customerName,
                rating: rating,
                comment: comment,
                createdAt: DateTime.tryParse(timestamp) ?? DateTime.now(),
              );
        return (success: true, error: null, feedback: created);
      }

      return (
        success: false,
        error: 'Gagal menyimpan feedback (${response.statusCode})',
        feedback: null,
      );
    } on DioException catch (e) {
      debugPrint('Supabase feedback insert DioException: ${e.response?.data ?? e.message}');
      String? errorMessage;
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final code = data['code']?.toString();
        final rawMsg = data['message']?.toString();
        if (code == 'PGRST205' || (rawMsg != null && rawMsg.contains('schema cache'))) {
          errorMessage =
              'Tabel feedbacks belum dibuat di Supabase. Silakan jalankan file supabase_feedback_migration.sql di Supabase SQL Editor.';
        } else if (code == '23505' || (rawMsg != null && rawMsg.contains('feedbacks_order_id'))) {
          errorMessage = 'Pesanan ini sudah pernah diberikan penilaian/feedback.';
        } else {
          errorMessage = rawMsg ?? data['error']?.toString();
        }
      }
      return (
        success: false,
        error: errorMessage ?? e.message ?? 'Terjadi kesalahan koneksi server.',
        feedback: null,
      );
    } catch (e) {
      debugPrint('Supabase feedback insert general exception: $e');
      return (success: false, error: e.toString(), feedback: null);
    }
  }

  /// Ambil seluruh feedback dari tabel 'feedbacks' di Supabase Cloud (diurutkan created_at desc)
  Future<List<FeedbackModel>> fetchFeedbacks() async {
    // 1. Coba lewat SupabaseClient jika tersedia
    if (_initialized) {
      try {
        final res = await client
            .from('feedbacks')
            .select('*')
            .order('created_at', ascending: false);
        return (res as List).map((item) {
          return FeedbackModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      } catch (e) {
        debugPrint('Supabase client fetchFeedbacks failed: $e');
      }
    }

    // 2. Coba lewat REST API via Dio
    try {
      final token = await SecureStorageService().getAccessToken();
      final headers = <String, dynamic>{
        'apikey': anonKey,
        'Authorization': 'Bearer ${token ?? anonKey}',
        'Content-Type': 'application/json',
      };

      final response = await _dio.get(
        '$projectUrl/rest/v1/feedbacks?select=*&order=created_at.desc',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          return FeedbackModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          );
        }).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Supabase fetchFeedbacks DioException: ${e.response?.data ?? e.message}');
      final is404 = e.response?.statusCode == 404;
      if (is404) {
        throw Exception(
          'Tabel feedbacks belum dibuat di Supabase. Silakan jalankan file supabase_feedback_migration.sql di Supabase SQL Editor.',
        );
      }
      rethrow;
    } catch (e) {
      debugPrint('Supabase fetchFeedbacks exception: $e');
      rethrow;
    }
  }

  /// Kirim Saran & Pesan (Mata Kuliah Pemrograman Aplikasi Mobile) ke Supabase Cloud (tabel 'course_saran_pesan')
  Future<({bool success, String? error, SaranPesanModel? data})> submitSaranPesan(
    SaranPesanModel item,
  ) async {
    final payload = item.toSupabaseMap();

    // 1. Coba gunakan SupabaseClient jika sudah diinisialisasi
    if (_initialized) {
      try {
        final inserted = await client
            .from('course_saran_pesan')
            .insert(payload)
            .select()
            .single();
        debugPrint('Supabase client saran_pesan inserted: $inserted');
        final created = SaranPesanModel.fromMap(
          Map<String, dynamic>.from(inserted as Map),
        ).copyWith(isSynced: true);
        return (success: true, error: null, data: created);
      } catch (e) {
        debugPrint('Supabase client insert to course_saran_pesan failed: $e');
      }
    }

    // 2. Coba menggunakan REST API via Dio
    try {
      final token = await SecureStorageService().getAccessToken();
      final headers = <String, dynamic>{
        'apikey': anonKey,
        'Authorization': 'Bearer ${token ?? anonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

      final response = await _dio.post(
        '$projectUrl/rest/v1/course_saran_pesan',
        data: payload,
        options: Options(headers: headers),
      );

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        Map<String, dynamic>? itemMap;
        if (response.data is List && (response.data as List).isNotEmpty) {
          itemMap = Map<String, dynamic>.from((response.data as List).first as Map);
        } else if (response.data is Map) {
          itemMap = Map<String, dynamic>.from(response.data as Map);
        }
        final created = itemMap != null
            ? SaranPesanModel.fromMap(itemMap).copyWith(isSynced: true)
            : item.copyWith(isSynced: true);
        return (success: true, error: null, data: created);
      }

      return (
        success: false,
        error: 'Gagal mengirim saran & pesan ke server (${response.statusCode})',
        data: null,
      );
    } on DioException catch (e) {
      debugPrint('Supabase saran_pesan DioException: ${e.response?.data ?? e.message}');
      String? errorMessage;
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final rawMsg = data['message']?.toString();
        errorMessage = rawMsg ?? data['error']?.toString();
      }
      return (
        success: false,
        error: errorMessage ?? e.message ?? 'Koneksi ke server terputus.',
        data: null,
      );
    } catch (e) {
      debugPrint('Supabase saran_pesan general exception: $e');
      return (success: false, error: e.toString(), data: null);
    }
  }

  /// Ambil riwayat Saran & Pesan dari Supabase untuk user tertentu
  Future<List<SaranPesanModel>> fetchUserSaranPesan(String userId) async {
    // 1. Coba via SupabaseClient
    if (_initialized) {
      try {
        final res = await client
            .from('course_saran_pesan')
            .select('*')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        return (res as List).map((item) {
          return SaranPesanModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ).copyWith(isSynced: true);
        }).toList();
      } catch (e) {
        debugPrint('Supabase client fetchUserSaranPesan failed: $e');
      }
    }

    // 2. Coba REST API via Dio
    try {
      final token = await SecureStorageService().getAccessToken();
      final headers = <String, dynamic>{
        'apikey': anonKey,
        'Authorization': 'Bearer ${token ?? anonKey}',
        'Content-Type': 'application/json',
      };

      final response = await _dio.get(
        '$projectUrl/rest/v1/course_saran_pesan?user_id=eq.$userId&select=*&order=created_at.desc',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          return SaranPesanModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ).copyWith(isSynced: true);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase fetchUserSaranPesan exception: $e');
      return [];
    }
  }

  /// Ambil seluruh data Saran & Pesan dari Supabase (untuk dosen / rekap pengampu)
  Future<List<SaranPesanModel>> fetchAllSaranPesan() async {
    if (_initialized) {
      try {
        final res = await client
            .from('course_saran_pesan')
            .select('*')
            .order('created_at', ascending: false);
        return (res as List).map((item) {
          return SaranPesanModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ).copyWith(isSynced: true);
        }).toList();
      } catch (e) {
        debugPrint('Supabase client fetchAllSaranPesan failed: $e');
      }
    }

    try {
      final token = await SecureStorageService().getAccessToken();
      final headers = <String, dynamic>{
        'apikey': anonKey,
        'Authorization': 'Bearer ${token ?? anonKey}',
        'Content-Type': 'application/json',
      };

      final response = await _dio.get(
        '$projectUrl/rest/v1/course_saran_pesan?select=*&order=created_at.desc',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        return list.map((item) {
          return SaranPesanModel.fromMap(
            Map<String, dynamic>.from(item as Map),
          ).copyWith(isSynced: true);
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Supabase fetchAllSaranPesan exception: $e');
      return [];
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
