import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/game/presentation/game_screen.dart';
import 'package:mobile/features/rewards/data/reward_repository.dart';
import 'package:mobile/features/rewards/models/voucher_model.dart';
import 'package:mobile/features/rewards/providers/rewards_provider.dart';

void main() {
  Future<_MemoryRewardRepository> startGame(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _MemoryRewardRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentRewardUserIdProvider.overrideWith((ref) => 'test-user'),
          rewardRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: GameScreen()),
      ),
    );
    // Switch off motion sensors to enable touch buttons for testing
    await tester.tap(find.byType(Switch));
    await tester.pump();

    final playBtn = find.textContaining("LET'S PLAY");
    if (playBtn.evaluate().isNotEmpty) {
      await tester.tap(playBtn.first);
    } else {
      await tester.tap(find.text('MULAI MAIN'));
    }
    await tester.pump();
    return repository;
  }

  Future<void> dropAndWait(
    WidgetTester tester, {
    bool alignWithStack = true,
  }) async {
    if (alignWithStack) {
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.text('Geser Kiri'));
      }
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Geser Kanan'));
      }
    }
    await tester.tap(find.textContaining('DROP INGREDIENT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
  }

  testWidgets('stacks 15 ingredients, wins, and resets for another round', (
    tester,
  ) async {
    final repository = await startGame(tester);
    expect(find.text('Angus Patty'), findsOneWidget);
    expect((await repository.loadForUser('test-user')).totalPoints, 0);

    for (var i = 0; i < 15; i++) {
      await dropAndWait(tester);
    }

    expect(find.textContaining('VICTORY!'), findsOneWidget);
    expect(find.textContaining('15 lapis burger'), findsOneWidget);
    expect((await repository.loadForUser('test-user')).entries, hasLength(1));
    expect(
      (await repository.loadForUser('test-user')).totalPoints,
      greaterThan(0),
    );

    await tester.tap(find.textContaining('MAIN LAGI'));
    await tester.pump();
    expect(find.text('0/15'), findsOneWidget);
    expect(find.text('0 PTS'), findsOneWidget);
  });

  testWidgets('a completely missed ingredient ends the round', (tester) async {
    final repository = await startGame(tester);

    // Nudge layer 1 to the right so it lands partially on the right edge of base bun
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Geser Kanan'));
    }
    await tester.tap(find.textContaining('DROP INGREDIENT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('1/15'), findsOneWidget);

    // Nudge layer 2 far to the left so it completely misses the right-aligned stack
    for (var i = 0; i < 8; i++) {
      await tester.tap(find.text('Geser Kiri'));
    }
    await tester.tap(find.textContaining('DROP INGREDIENT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));

    expect(find.textContaining('GAME OVER'), findsOneWidget);
    expect((await repository.loadForUser('test-user')).entries, hasLength(1));
    expect(
      (await repository.loadForUser('test-user')).totalPoints,
      greaterThan(0),
    );
  });
}

class _MemoryRewardRepository implements RewardRepository {
  final Map<String, ({String userId, RewardEntry entry})> _sessions = {};

  @override
  Future<RewardSnapshot> loadForUser(String userId) async {
    final entries = _sessions.values
        .where((session) => session.userId == userId)
        .map((session) => session.entry)
        .toList();
    return RewardSnapshot(
      totalPoints: entries.fold(
        0,
        (total, entry) => total + entry.pointsAwarded,
      ),
      entries: entries,
    );
  }

  @override
  Future<RewardRecordResult> recordGameResult(
    String userId,
    RewardGameResult result,
  ) async {
    final existing = _sessions[result.sessionId];
    if (existing != null) {
      if (existing.userId != userId) {
        throw StateError('Session belongs to a different user.');
      }
      return RewardRecordResult(
        pointsAwarded: existing.entry.pointsAwarded,
        wasAlreadyProcessed: true,
      );
    }
    final entry = RewardEntry(
      sessionId: result.sessionId,
      score: result.score,
      stackedIngredients: result.stackedIngredients,
      precisionHits: result.precisionHits,
      victory: result.victory,
      pointsAwarded: RewardCalculator.pointsFor(result),
      playedAt: result.playedAt,
    );
    _sessions[result.sessionId] = (userId: userId, entry: entry);
    return RewardRecordResult(
      pointsAwarded: entry.pointsAwarded,
      wasAlreadyProcessed: false,
    );
  }

  final List<VoucherModel> _vouchers = [];

  @override
  Future<VoucherModel> redeemVoucher(
    String userId,
    VoucherType type, {
    String? idempotencyKey,
  }) async {
    final now = DateTime.now();
    final voucher = VoucherModel(
      id: 'vch_${now.millisecondsSinceEpoch}',
      userId: userId,
      code: 'BUN${type.discountPercent}-TEST',
      type: type,
      discountPercent: type.discountPercent,
      pointsCost: type.pointsCost,
      status: VoucherStatus.available,
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      redemptionReferenceId: idempotencyKey ?? 'ref_test',
    );
    _vouchers.add(voucher);
    return voucher;
  }

  @override
  Future<List<VoucherModel>> loadVouchersForUser(String userId) async {
    return _vouchers.where((v) => v.userId == userId).toList();
  }

  @override
  Future<VoucherModel?> findVoucherByCode(String userId, String code) async {
    try {
      return _vouchers.firstWhere(
        (v) => v.userId == userId && v.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> markVoucherUsed(
    String voucherId,
    String orderId, {
    String? usageTxHash,
    String? usageReferenceId,
  }) async {
    final index = _vouchers.indexWhere((v) => v.id == voucherId);
    if (index != -1) {
      _vouchers[index] = _vouchers[index].copyWith(
        status: VoucherStatus.used,
        usedAt: DateTime.now(),
        usedOrderId: orderId,
        usageTxHash: usageTxHash,
        usageReferenceId: usageReferenceId,
      );
    }
  }

  @override
  Future<void> updateVoucherBlockchainStatus(
    String voucherId, {
    required BlockchainStatus status,
    String? txHash,
    String? explorerUrl,
  }) async {
    final index = _vouchers.indexWhere((v) => v.id == voucherId);
    if (index != -1) {
      _vouchers[index] = _vouchers[index].copyWith(
        blockchainStatus: status,
        redemptionTxHash: txHash,
        explorerUrl: explorerUrl,
      );
    }
  }
}
