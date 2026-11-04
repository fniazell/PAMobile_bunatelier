import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/remote/supabase_service.dart';
import '../models/feedback_model.dart';

final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService();
});

class FeedbackService {
  final SupabaseService _supabaseService;

  FeedbackService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Mengirim feedback pelanggan ke Supabase
  Future<({bool success, String? errorMessage, FeedbackModel? feedback})> submitFeedback(
    FeedbackModel feedback,
  ) async {
    // Validasi orderId
    if (feedback.orderId.trim().isEmpty) {
      return (
        success: false,
        errorMessage: 'Nomor pesanan (Order ID) tidak valid.',
        feedback: null,
      );
    }

    // Validasi rating
    if (feedback.rating < 1 || feedback.rating > 5) {
      return (
        success: false,
        errorMessage: 'Rating harus antara 1 sampai 5 bintang.',
        feedback: null,
      );
    }

    if (feedback.userId.trim().isEmpty) {
      return (
        success: false,
        errorMessage: 'Pengguna harus masuk/login terlebih dahulu.',
        feedback: null,
      );
    }

    final result = await _supabaseService.submitFeedback(
      orderId: feedback.orderId,
      userId: feedback.userId,
      customerName: feedback.customerName,
      rating: feedback.rating,
      comment: feedback.comment,
      createdAt: feedback.createdAt,
    );

    if (result.success) {
      return (
        success: true,
        errorMessage: null,
        feedback: result.feedback ?? feedback,
      );
    } else {
      return (
        success: false,
        errorMessage: result.error ?? 'Gagal mengirim feedback ke server.',
        feedback: null,
      );
    }
  }

  /// Mengambil seluruh daftar feedback dari Supabase (diurutkan created_at desc)
  Future<List<FeedbackModel>> fetchFeedbacks() async {
    return await _supabaseService.fetchFeedbacks();
  }
}
