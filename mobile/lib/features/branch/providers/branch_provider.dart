import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../data/local/app_database.dart';
import '../../../data/remote/supabase_service.dart';
import '../models/branch_model.dart';

class BranchState {
  final List<BranchModel> branches;
  final BranchModel selectedBranch;
  final bool isLoading;
  final String? errorMessage;

  const BranchState({
    required this.branches,
    required this.selectedBranch,
    this.isLoading = false,
    this.errorMessage,
  });

  BranchState copyWith({
    List<BranchModel>? branches,
    BranchModel? selectedBranch,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BranchState(
      branches: branches ?? this.branches,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class BranchNotifier extends StateNotifier<BranchState> {
  static const String _prefSelectedBranchKey = 'selected_branch_id';

  BranchNotifier()
      : super(
          BranchState(
            branches: BranchModel.defaultBranches,
            selectedBranch: BranchModel.defaultBranches.first, // Senopati default
            isLoading: false,
          ),
        ) {
    _initializeBranches();
  }

  Future<void> _initializeBranches() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Muat dari SQLite lokal dan pastikan default branches terbaru (Maluku & alamat lengkap) tersimpan
      for (final branch in BranchModel.defaultBranches) {
        await AppDatabase.instance.insertCachedBranch(branch.toMap());
      }
      final cachedRows = await AppDatabase.instance.getCachedBranches();
      List<BranchModel> activeBranches = cachedRows.map((r) => BranchModel.fromMap(r)).toList();

      // Pastikan ada cabang
      if (activeBranches.isEmpty) {
        activeBranches = List.from(BranchModel.defaultBranches);
      }

      // Pastikan urutan cabang sesuai spesifikasi resmi:
      // 1. Senopati, 2. PIK, 3. Maluku, 4. Bali, 5. London, 6. Malaysia, 7. Singapore
      activeBranches = sortBranches(activeBranches);

      // 2. Baca preferensi cabang terpilih sebelumnya
      final savedId = await AppDatabase.instance.getUserPreference(_prefSelectedBranchKey);
      BranchModel selected = activeBranches.first;
      if (savedId != null) {
        final found = activeBranches.where((b) => b.id == savedId);
        if (found.isNotEmpty) {
          selected = found.first;
        }
      }

      state = state.copyWith(
        branches: activeBranches,
        selectedBranch: selected,
        isLoading: false,
      );

      // 3. Sinkronisasi dengan Supabase Cloud jika online (skip dalam testing environment)
      final bool isTest = Zone.current[#flutter.test] != null ||
          (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'));
      if (!isTest) {
        _syncFromCloud();
      }
    } catch (e) {
      debugPrint('Branch initialization fallback to defaults: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  static const List<String> canonicalBranchOrder = [
    'out-1', // Senopati
    'out-2', // PIK
    'out-7', // Maluku (mandated right below PIK)
    'out-4', // Bali
    'out-3', // London
    'out-5', // Kuala Lumpur / Malaysia
    'out-6', // Singapore
  ];

  static List<BranchModel> sortBranches(List<BranchModel> list) {
    final sorted = List<BranchModel>.from(list);
    sorted.sort((a, b) {
      int indexA = canonicalBranchOrder.indexOf(a.id);
      int indexB = canonicalBranchOrder.indexOf(b.id);
      if (indexA == -1) indexA = 999;
      if (indexB == -1) indexB = 999;
      return indexA.compareTo(indexB);
    });
    return sorted;
  }

  Future<void> _syncFromCloud() async {
    try {
      final cloudBranches = await SupabaseService.instance.fetchBranches();
      if (cloudBranches.isNotEmpty) {
        // Update SQLite cache
        for (final b in cloudBranches) {
          await AppDatabase.instance.insertCachedBranch(b.toMap());
        }

        final sortedCloud = sortBranches(cloudBranches);

        // Cari cabang terpilih di list baru
        final currentId = state.selectedBranch.id;
        final updatedSelected = sortedCloud.firstWhere(
          (b) => b.id == currentId,
          orElse: () => sortedCloud.first,
        );

        state = state.copyWith(
          branches: sortedCloud,
          selectedBranch: updatedSelected,
        );
      }
    } catch (e) {
      debugPrint('Branch cloud sync silent fail: $e');
    }
  }

  /// Memilih cabang untuk customer (disimpan ke SQLite & state)
  Future<void> selectBranch(BranchModel branch) async {
    state = state.copyWith(selectedBranch: branch);
    await AppDatabase.instance.setUserPreference(_prefSelectedBranchKey, branch.id);
  }

  /// Memperbarui informasi cabang (admin action)
  Future<bool> updateBranch(BranchModel updatedBranch) async {
    final updatedList = state.branches.map((b) {
      return b.id == updatedBranch.id ? updatedBranch : b;
    }).toList();

    final newSelected = state.selectedBranch.id == updatedBranch.id
        ? updatedBranch
        : state.selectedBranch;

    state = state.copyWith(
      branches: updatedList,
      selectedBranch: newSelected,
    );

    // Update di SQFLITE
    await AppDatabase.instance.updateCachedBranch(
      updatedBranch.id,
      updatedBranch.toMap(),
    );

    // Update di Supabase Cloud jika terhubung
    final cloudSuccess = await SupabaseService.instance.updateBranchOnCloud(updatedBranch);
    return cloudSuccess;
  }

  /// Toggle status aktif cabang (admin action)
  Future<void> toggleBranchActive(String branchId, bool isActive) async {
    final branch = state.branches.firstWhere((b) => b.id == branchId);
    final updated = branch.copyWith(isActive: isActive);
    await updateBranch(updated);
  }

  /// Buka lokasi cabang di Google Maps
  Future<bool> openBranchInMaps(BranchModel branch) async {
    return await GoogleMapsService.openBranch(
      query: branch.effectiveMapsQuery,
      latitude: branch.latitude,
      longitude: branch.longitude,
      isVerified: branch.isVerified,
      label: branch.name,
    );
  }
}

final branchProvider = StateNotifierProvider<BranchNotifier, BranchState>((ref) {
  return BranchNotifier();
});
