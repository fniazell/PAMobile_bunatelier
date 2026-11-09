import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/supabase_service.dart';
import '../models/saran_pesan_model.dart';

final saranPesanServiceProvider = Provider<SaranPesanService>((ref) {
  return SaranPesanService();
});

class SaranPesanService {
  final AppDatabase _db;
  final SupabaseService _supabase;

  SaranPesanService({
    AppDatabase? db,
    SupabaseService? supabase,
  })  : _db = db ?? AppDatabase.instance,
        _supabase = supabase ?? SupabaseService.instance;

  /// Simpan Saran & Pesan ke SQLite lokal dan sinkronkan ke Supabase Cloud
  Future<({bool success, String? errorMessage, SaranPesanModel? data})>
      submitSaranPesan(SaranPesanModel item) async {
    try {
      // 1. Validasi Login
      if (item.userId.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Silakan login terlebih dahulu untuk mengirim saran dan pesan.',
          data: null,
        );
      }

      // 2. Validasi Kolom Saran
      if (item.saran.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Saran untuk Mata Kuliah Pemrograman Aplikasi Mobile wajib diisi.',
          data: null,
        );
      }

      // 3. Validasi Kolom Pesan
      if (item.pesan.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Pesan untuk Dosen Pengampu wajib diisi.',
          data: null,
        );
      }

      // 4. Simpan ke SQLite Lokal (Offline-first jaminan persistensi data)
      await _db.insertSaranPesan(item.toSqliteMap());
      debugPrint('Saran & Pesan saved to local SQLite: ${item.id}');

      // 5. Sinkronisasi ke Supabase Cloud
      SaranPesanModel finalItem = item;
      try {
        final cloudRes = await _supabase.submitSaranPesan(item);
        if (cloudRes.success) {
          finalItem = item.copyWith(isSynced: true);
          await _db.insertSaranPesan(finalItem.toSqliteMap());
          debugPrint('Saran & Pesan synced to Supabase Cloud: ${finalItem.id}');
        } else {
          debugPrint('Supabase cloud notice: ${cloudRes.error}');
        }
      } catch (cloudErr) {
        debugPrint('Supabase cloud background sync error: $cloudErr');
      }

      return (
        success: true,
        errorMessage: null,
        data: finalItem,
      );
    } catch (e) {
      debugPrint('Error submitSaranPesan: $e');
      return (
        success: false,
        errorMessage: 'Terjadi kesalahan saat menyimpan data: $e',
        data: null,
      );
    }
  }

  /// Ambil riwayat Saran & Pesan untuk user tertentu (lokal SQLite + Cloud)
  Future<List<SaranPesanModel>> getUserSaranPesan(String userId) async {
    try {
      // 1. Ambil dari SQLite terlebih dahulu
      final localRows = await _db.getSaranPesanByUser(userId);
      final List<SaranPesanModel> localList =
          localRows.map((r) => SaranPesanModel.fromMap(r)).toList();

      // 2. Coba sinkronisasi dari Supabase Cloud
      try {
        final cloudList = await _supabase.fetchUserSaranPesan(userId);
        if (cloudList.isNotEmpty) {
          final existingIds = localList.map((e) => e.id).toSet();
          for (final cloudItem in cloudList) {
            if (!existingIds.contains(cloudItem.id)) {
              await _db.insertSaranPesan(cloudItem.toSqliteMap());
              localList.add(cloudItem);
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to sync cloud saran_pesan to local DB: $e');
      }

      localList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localList;
    } catch (e) {
      debugPrint('Error getUserSaranPesan: $e');
      return [];
    }
  }

  /// Ambil semua Saran & Pesan dari semua mahasiswa
  Future<List<SaranPesanModel>> getAllSaranPesan() async {
    try {
      final rows = await _db.getAllSaranPesan();
      return rows.map((r) => SaranPesanModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getAllSaranPesan: $e');
      return [];
    }
  }
}
