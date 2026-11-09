import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/saran_pesan_model.dart';
import '../services/saran_pesan_service.dart';

class SaranPesanFormState {
  final String saran;
  final String pesan;
  final bool isSubmitting;
  final String? errorMessage;
  final SaranPesanModel? lastSubmitted;

  const SaranPesanFormState({
    this.saran = '',
    this.pesan = '',
    this.isSubmitting = false,
    this.errorMessage,
    this.lastSubmitted,
  });

  SaranPesanFormState copyWith({
    String? saran,
    String? pesan,
    bool? isSubmitting,
    String? errorMessage,
    SaranPesanModel? lastSubmitted,
  }) {
    return SaranPesanFormState(
      saran: saran ?? this.saran,
      pesan: pesan ?? this.pesan,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      lastSubmitted: lastSubmitted ?? this.lastSubmitted,
    );
  }
}

class SaranPesanFormNotifier extends StateNotifier<SaranPesanFormState> {
  final SaranPesanService _service;
  final Ref _ref;

  SaranPesanFormNotifier(this._service, this._ref)
      : super(const SaranPesanFormState());

  void setSaran(String val) => state = state.copyWith(saran: val);
  void setPesan(String val) => state = state.copyWith(pesan: val);

  void reset() {
    state = const SaranPesanFormState();
  }

  Future<bool> submit({
    required String userId,
    String? userName,
    String? userEmail,
  }) async {
    if (state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final id = 'SP-${DateTime.now().millisecondsSinceEpoch}';
    final model = SaranPesanModel(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      saran: state.saran.trim(),
      pesan: state.pesan.trim(),
      createdAt: DateTime.now(),
      isSynced: false,
    );

    final result = await _service.submitSaranPesan(model);

    if (result.success && result.data != null) {
      _ref
          .read(userSaranPesanHistoryProvider(userId).notifier)
          .prepend(result.data!);

      state = state.copyWith(
        isSubmitting: false,
        lastSubmitted: result.data,
        errorMessage: null,
      );
      return true;
    } else {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: result.errorMessage ?? 'Gagal mengirim saran & pesan.',
      );
      return false;
    }
  }
}

final saranPesanFormProvider =
    StateNotifierProvider<SaranPesanFormNotifier, SaranPesanFormState>((ref) {
  final service = ref.watch(saranPesanServiceProvider);
  return SaranPesanFormNotifier(service, ref);
});

// ── User History Notifier ───────────────────────────────────────────────────

class UserSaranPesanHistoryNotifier
    extends StateNotifier<AsyncValue<List<SaranPesanModel>>> {
  final SaranPesanService _service;
  final String _userId;

  UserSaranPesanHistoryNotifier(this._service, this._userId)
      : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.getUserSaranPesan(_userId);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void prepend(SaranPesanModel item) {
    state.whenData((list) {
      final filtered = list.where((x) => x.id != item.id).toList();
      state = AsyncValue.data([item, ...filtered]);
    });
  }
}

final userSaranPesanHistoryProvider = StateNotifierProvider.family<
    UserSaranPesanHistoryNotifier,
    AsyncValue<List<SaranPesanModel>>,
    String>((ref, userId) {
  final service = ref.watch(saranPesanServiceProvider);
  return UserSaranPesanHistoryNotifier(service, userId);
});

