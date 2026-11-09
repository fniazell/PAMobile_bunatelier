import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_feedback_model.dart';
import '../services/app_feedback_service.dart';

// ── Form State ────────────────────────────────────────────────────────────────

class AppFeedbackFormState {
  final int ratingUi;
  final int ratingUx;
  final int ratingNavigation;
  final int ratingPerformance;
  final int ratingFunctionality;
  final int ratingComfort;

  final String overallExperience;
  final String favoriteFeature;
  final bool hadIssues;
  final String issueDescription;
  final String suggestions;

  final bool isSubmitting;
  final String? errorMessage;
  final AppFeedbackModel? lastSubmitted;

  const AppFeedbackFormState({
    this.ratingUi = 5,
    this.ratingUx = 5,
    this.ratingNavigation = 5,
    this.ratingPerformance = 5,
    this.ratingFunctionality = 5,
    this.ratingComfort = 5,
    this.overallExperience = 'Sangat Baik',
    this.favoriteFeature = 'Menu dan Pemesanan',
    this.hadIssues = false,
    this.issueDescription = '',
    this.suggestions = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSubmitted,
  });

  double get averageScore => AppFeedbackModel.calculateAverage(
        ui: ratingUi,
        ux: ratingUx,
        navigation: ratingNavigation,
        performance: ratingPerformance,
        functionality: ratingFunctionality,
        comfort: ratingComfort,
      );

  AppFeedbackFormState copyWith({
    int? ratingUi,
    int? ratingUx,
    int? ratingNavigation,
    int? ratingPerformance,
    int? ratingFunctionality,
    int? ratingComfort,
    String? overallExperience,
    String? favoriteFeature,
    bool? hadIssues,
    String? issueDescription,
    String? suggestions,
    bool? isSubmitting,
    String? errorMessage,
    AppFeedbackModel? lastSubmitted,
  }) {
    return AppFeedbackFormState(
      ratingUi: ratingUi ?? this.ratingUi,
      ratingUx: ratingUx ?? this.ratingUx,
      ratingNavigation: ratingNavigation ?? this.ratingNavigation,
      ratingPerformance: ratingPerformance ?? this.ratingPerformance,
      ratingFunctionality: ratingFunctionality ?? this.ratingFunctionality,
      ratingComfort: ratingComfort ?? this.ratingComfort,
      overallExperience: overallExperience ?? this.overallExperience,
      favoriteFeature: favoriteFeature ?? this.favoriteFeature,
      hadIssues: hadIssues ?? this.hadIssues,
      issueDescription: issueDescription ?? this.issueDescription,
      suggestions: suggestions ?? this.suggestions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      lastSubmitted: lastSubmitted ?? this.lastSubmitted,
    );
  }
}

class AppFeedbackFormNotifier extends StateNotifier<AppFeedbackFormState> {
  final AppFeedbackService _service;
  final Ref _ref;

  AppFeedbackFormNotifier(this._service, this._ref)
      : super(const AppFeedbackFormState());

  void setRatingUi(int val) => state = state.copyWith(ratingUi: val);
  void setRatingUx(int val) => state = state.copyWith(ratingUx: val);
  void setRatingNavigation(int val) =>
      state = state.copyWith(ratingNavigation: val);
  void setRatingPerformance(int val) =>
      state = state.copyWith(ratingPerformance: val);
  void setRatingFunctionality(int val) =>
      state = state.copyWith(ratingFunctionality: val);
  void setRatingComfort(int val) =>
      state = state.copyWith(ratingComfort: val);

  void setOverallExperience(String val) =>
      state = state.copyWith(overallExperience: val);
  void setFavoriteFeature(String val) =>
      state = state.copyWith(favoriteFeature: val);
  void setHadIssues(bool val) => state = state.copyWith(hadIssues: val);
  void setIssueDescription(String val) =>
      state = state.copyWith(issueDescription: val);
  void setSuggestions(String val) =>
      state = state.copyWith(suggestions: val);

  void reset() {
    state = const AppFeedbackFormState();
  }

  Future<bool> submitFeedback({
    required String userId,
    String? userName,
    String? userEmail,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final id = 'AF-${DateTime.now().millisecondsSinceEpoch}';
    final feedback = AppFeedbackModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      ratingUi: state.ratingUi,
      ratingUx: state.ratingUx,
      ratingNavigation: state.ratingNavigation,
      ratingPerformance: state.ratingPerformance,
      ratingFunctionality: state.ratingFunctionality,
      ratingComfort: state.ratingComfort,
      ratingOverall: state.averageScore,
      overallExperience: state.overallExperience,
      favoriteFeature: state.favoriteFeature,
      hadIssues: state.hadIssues,
      issueDescription: state.hadIssues ? state.issueDescription.trim() : null,
      suggestions: state.suggestions.trim().isNotEmpty ? state.suggestions.trim() : null,
      status: 'TERKIRIM',
      createdAt: DateTime.now(),
      isSynced: false,
    );

    final result = await _service.submitAppFeedback(feedback);

    if (result.success && result.feedback != null) {
      // Perbarui riwayat di provider
      _ref
          .read(userAppFeedbackHistoryProvider(userId).notifier)
          .prepend(result.feedback!);

      state = state.copyWith(
        isSubmitting: false,
        lastSubmitted: result.feedback,
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: result.errorMessage ?? 'Gagal mengirim feedback.',
      );
      return false;
    }
  }
}

final appFeedbackFormProvider =
    StateNotifierProvider<AppFeedbackFormNotifier, AppFeedbackFormState>((ref) {
  final service = ref.watch(appFeedbackServiceProvider);
  return AppFeedbackFormNotifier(service, ref);
});

// ── User Feedback History Notifier ───────────────────────────────────────────

class UserAppFeedbackHistoryNotifier
    extends StateNotifier<AsyncValue<List<AppFeedbackModel>>> {
  final AppFeedbackService _service;
  final String _userId;

  UserAppFeedbackHistoryNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getUserFeedbacks(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void prepend(AppFeedbackModel feedback) {
    state.whenData((list) {
      final filtered = list.where((item) => item.id != feedback.id).toList();
      state = AsyncValue.data([feedback, ...filtered]);
    });
  }
}

final userAppFeedbackHistoryProvider = StateNotifierProvider.family<
    UserAppFeedbackHistoryNotifier,
    AsyncValue<List<AppFeedbackModel>>,
    String>((ref, userId) {
  final service = ref.watch(appFeedbackServiceProvider);
  return UserAppFeedbackHistoryNotifier(service, userId);
});

