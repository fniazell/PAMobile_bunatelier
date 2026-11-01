import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/reward_repository.dart';

final currentRewardUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});

class RewardState {
  const RewardState({
    this.totalPoints = 0,
    this.entries = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final int totalPoints;
  final List<RewardEntry> entries;
  final bool isLoading;
  final String? errorMessage;

  RewardState copyWith({
    int? totalPoints,
    List<RewardEntry>? entries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RewardState(
      totalPoints: totalPoints ?? this.totalPoints,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  return SqliteRewardRepository();
});

final rewardsProvider =
    StateNotifierProvider.family<RewardNotifier, RewardState, String>((
      ref,
      userId,
    ) {
      return RewardNotifier(userId, ref.watch(rewardRepositoryProvider));
    });

class RewardNotifier extends StateNotifier<RewardState> {
  RewardNotifier(this.userId, this._repository) : super(const RewardState()) {
    unawaited(load());
  }

  final String userId;
  final RewardRepository _repository;
  bool _hasLoaded = false;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repository.loadForUser(userId);
      _hasLoaded = true;
      state = RewardState(
        totalPoints: snapshot.totalPoints,
        entries: snapshot.entries,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tidak dapat memuat poin: $error',
      );
    }
  }

  Future<RewardRecordResult> recordGameResult(RewardGameResult result) async {
    try {
      final record = await _repository.recordGameResult(userId, result);
      final snapshot = await _repository.loadForUser(userId);
      _hasLoaded = true;
      state = RewardState(
        totalPoints: snapshot.totalPoints,
        entries: snapshot.entries,
        isLoading: false,
      );
      return record;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Hasil game belum tersimpan: $error',
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    if (!_hasLoaded || !state.isLoading) {
      await load();
    }
  }
}
