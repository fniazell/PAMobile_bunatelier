import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import '../../../data/remote/supabase_service.dart';
import '../models/app_feedback_model.dart';

final appFeedbackServiceProvider = Provider<AppFeedbackService>((ref) {
  return AppFeedbackService();
});

class AppFeedbackService {
  final AppDatabase _db;
  final SupabaseService _supabase;

  AppFeedbackService({
    AppDatabase? db,
    SupabaseService? supabase,
  })  : _db = db ?? AppDatabase.instance,
        _supabase = supabase ?? SupabaseService.instance;

  /// Simpan feedback aplikasi ke database lokal SQLite dan sinkronkan ke Supabase Cloud
  Future<({bool success, String? errorMessage, AppFeedbackModel? feedback})>
      submitAppFeedback(AppFeedbackModel feedback) async {
    try {
      // 1. Validasi Customer Login
      if (feedback.userId.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Silakan login terlebih dahulu untuk memberikan feedback.',
          feedback: null,
        );
      }

      // 2. Validasi 6 Aspek Penilaian Pengalaman Pengguna
      if (feedback.ratingUi < 1 || feedback.ratingUi > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Tampilan aplikasi (UI).',
          feedback: null,
        );
      }
      if (feedback.ratingUx < 1 || feedback.ratingUx > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Kemudahan penggunaan (UX).',
          feedback: null,
        );
      }
      if (feedback.ratingNavigation < 1 || feedback.ratingNavigation > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Navigasi aplikasi.',
          feedback: null,
        );
      }
      if (feedback.ratingPerformance < 1 || feedback.ratingPerformance > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Performa aplikasi.',
          feedback: null,
        );
      }
      if (feedback.ratingFunctionality < 1 || feedback.ratingFunctionality > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Fungsionalitas aplikasi.',
          feedback: null,
        );
      }
      if (feedback.ratingComfort < 1 || feedback.ratingComfort > 5) {
        return (
          success: false,
          errorMessage: 'Mohon berikan rating 1-5 untuk Kenyamanan penggunaan.',
          feedback: null,
        );
      }

      // 3. Validasi Pertanyaan Tambahan
      if (feedback.overallExperience.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Pilih pengalaman Anda secara keseluruhan.',
          feedback: null,
        );
      }
      if (feedback.favoriteFeature.trim().isEmpty) {
        return (
          success: false,
          errorMessage: 'Pilih fitur yang paling Anda sukai.',
          feedback: null,
        );
      }
      if (feedback.hadIssues &&
          (feedback.issueDescription == null ||
              feedback.issueDescription!.trim().isEmpty)) {
        return (
          success: false,
          errorMessage: 'Jelaskan kendala yang Anda alami saat menggunakan aplikasi.',
          feedback: null,
        );
      }

      // 4. Hitung Nilai Rata-rata Rating Keseluruhan
      final overallRating = feedback.ratingOverall > 0
          ? feedback.ratingOverall
          : AppFeedbackModel.calculateAverage(
              ui: feedback.ratingUi,
              ux: feedback.ratingUx,
              navigation: feedback.ratingNavigation,
              performance: feedback.ratingPerformance,
              functionality: feedback.ratingFunctionality,
              comfort: feedback.ratingComfort,
            );

      final preparedFeedback = feedback.copyWith(ratingOverall: overallRating);

      // 5. Simpan ke SQLite Lokal (Offline-first jaminan data tersimpan)
      await _db.insertAppFeedback(preparedFeedback.toSqliteMap());
      debugPrint('AppFeedback saved to local SQLite: ${preparedFeedback.id}');

      // 6. Sinkronisasi ke Supabase Cloud
      AppFeedbackModel finalFeedback = preparedFeedback;
      try {
        final cloudRes = await _supabase.submitAppFeedback(preparedFeedback);
        if (cloudRes.success) {
          finalFeedback = preparedFeedback.copyWith(isSynced: true);
          await _db.insertAppFeedback(finalFeedback.toSqliteMap());
          debugPrint('AppFeedback synced to Supabase Cloud: ${finalFeedback.id}');
        } else {
          debugPrint('Supabase cloud app feedback warning: ${cloudRes.error}');
        }
      } catch (cloudErr) {
        debugPrint('Supabase sync background notice: $cloudErr');
      }

      return (
        success: true,
        errorMessage: null,
        feedback: finalFeedback,
      );
    } catch (e) {
      debugPrint('Error submitAppFeedback: $e');
      return (
        success: false,
        errorMessage: 'Terjadi kesalahan saat menyimpan feedback: $e',
        feedback: null,
      );
    }
  }

  /// Ambil riwayat feedback customer tertentu (lokal SQLite + Supabase)
  Future<List<AppFeedbackModel>> getUserFeedbacks(String userId) async {
    try {
      // 1. Ambil dari SQLite terlebih dahulu
      final localRows = await _db.getAppFeedbacksByUser(userId);
      final List<AppFeedbackModel> localList =
          localRows.map((r) => AppFeedbackModel.fromMap(r)).toList();

      // 2. Ambil dari Supabase di background dan gabungkan
      try {
        final cloudList = await _supabase.fetchUserAppFeedbacks(userId);
        if (cloudList.isNotEmpty) {
          final existingIds = localList.map((e) => e.id).toSet();
          for (final cloudItem in cloudList) {
            if (!existingIds.contains(cloudItem.id)) {
              await _db.insertAppFeedback(cloudItem.toSqliteMap());
              localList.add(cloudItem);
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to sync cloud feedbacks to local DB: $e');
      }

      localList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localList;
    } catch (e) {
      debugPrint('Error getUserFeedbacks: $e');
      return [];
    }
  }

  /// Ambil semua feedback dari semua customer
  Future<List<AppFeedbackModel>> getAllFeedbacks() async {
    try {
      final rows = await _db.getAllAppFeedbacks();
      return rows.map((r) => AppFeedbackModel.fromMap(r)).toList();
    } catch (e) {
      debugPrint('Error getAllFeedbacks: $e');
      return [];
    }
  }
}

