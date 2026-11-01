import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/game/presentation/game_screen.dart';
import 'package:mobile/features/rewards/data/reward_repository.dart';
import 'package:mobile/features/rewards/models/voucher_model.dart';
import 'package:mobile/features/rewards/providers/rewards_provider.dart';

void main() {
  testWidgets('Stack Your Bun Intro Screen displays all Stitch reference elements', (tester) async {
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
    await tester.pump();

    // Verify Brand, Title, and Tagline
    expect(find.text('BUN ATELIER'), findsOneWidget);
    expect(find.text('PREMIUM BURGERS'), findsOneWidget);
    expect(find.text('STACK\nYOUR BUN'), findsOneWidget);
    expect(find.text("Build it tall. Don't let it fall."), findsOneWidget);

    // Verify Storefront and Mascot Assets exist
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('bun_intro_storefront')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('splash_frame_1')),
      findsOneWidget,
    );

    // Verify LET'S PLAY button
    expect(find.text("LET'S PLAY"), findsOneWidget);

    // Verify Game 2 tab selector exists
    expect(find.text('Chef Tray Rush'), findsOneWidget);

    // Switch to Game 2 (Chef Tray Rush) to confirm Game 2 is completely intact
    await tester.tap(find.text('Chef Tray Rush'));
    await tester.pump();
    expect(find.text('ANTAR PESANAN KE MEJA #7'), findsOneWidget);

    // Switch back to Stack Your Bun
    await tester.tap(find.text('Stack Your Bun'));
    await tester.pump();
    expect(find.text("LET'S PLAY"), findsOneWidget);

    // Tap LET'S PLAY to enter Gameplay
    await tester.tap(find.text("LET'S PLAY"));
    await tester.pump();

    // Verify Gameplay HUD
    expect(find.text('STACK YOUR BUN'), findsOneWidget);
    expect(find.text('0 PTS'), findsOneWidget);
    expect(find.text('0/15'), findsOneWidget);
    expect(find.textContaining('Tilt:'), findsOneWidget);
    expect(find.textContaining('Balance:'), findsOneWidget);
    expect(find.text('DROP INGREDIENT'), findsOneWidget);
    expect(find.textContaining('Next:'), findsOneWidget);

    // Verify Gameplay Restaurant Background Image exists
    expect(
      find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName.contains('gameplay_restaurant_bg')),
      findsOneWidget,
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
      totalPoints: entries.fold(0, (total, entry) => total + entry.pointsAwarded),
      entries: entries,
    );
  }

  @override
  Future<RewardRecordResult> recordGameResult(
    String userId,
    RewardGameResult result,
  ) async {
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

  @override
  Future<VoucherModel> redeemVoucher(String userId, VoucherType type, {String? idempotencyKey}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<VoucherModel>> loadVouchersForUser(String userId) async {
    return [];
  }

  @override
  Future<VoucherModel?> findVoucherByCode(String userId, String code) async {
    return null;
  }

  @override
  Future<void> markVoucherUsed(String voucherId, String orderId, {String? usageTxHash, String? usageReferenceId}) async {}

  @override
  Future<void> updateVoucherBlockchainStatus(String voucherId, {required BlockchainStatus status, String? txHash, String? explorerUrl}) async {}
}
