import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/feedback_model.dart';
import '../services/feedback_service.dart';

final feedbackFeedProvider =
    StateNotifierProvider<FeedbackFeedNotifier, AsyncValue<List<FeedbackModel>>>(
  (ref) => FeedbackFeedNotifier(ref.watch(feedbackServiceProvider)),
);

/// Map of orderId / orderNumber to FeedbackModel for O(1) status lookup in Order History
final orderFeedbacksMapProvider = Provider<Map<String, FeedbackModel>>((ref) {
  final asyncFeedbacks = ref.watch(feedbackFeedProvider);
  return asyncFeedbacks.maybeWhen(
    data: (feedbacks) {
      final map = <String, FeedbackModel>{};
      for (final f in feedbacks) {
        if (f.orderId.isNotEmpty) {
          map[f.orderId] = f;
        }
      }
      return map;
    },
    orElse: () => <String, FeedbackModel>{},
  );
});

class FeedbackFeedNotifier
    extends StateNotifier<AsyncValue<List<FeedbackModel>>> {
  final FeedbackService _service;

  FeedbackFeedNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchFeedbacks();
  }

  /// Mengambil data feedback dari Supabase
  Future<void> fetchFeedbacks() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.fetchFeedbacks();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Menambahkan feedback baru ke urutan paling atas secara instan
  void prependFeedback(FeedbackModel newFeedback) {
    state.when(
      data: (list) {
        final filtered = list.where((f) {
          if (newFeedback.id != null && f.id != null) {
            return f.id != newFeedback.id;
          }
          if (newFeedback.orderId.isNotEmpty && f.orderId.isNotEmpty) {
            return f.orderId != newFeedback.orderId;
          }
          return true;
        }).toList();
        state = AsyncValue.data([newFeedback, ...filtered]);
      },
      loading: () {
        state = AsyncValue.data([newFeedback]);
      },
      error: (_, st) {
        state = AsyncValue.data([newFeedback]);
      },
    );
  }
}
