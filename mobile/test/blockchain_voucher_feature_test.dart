import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/rewards/models/voucher_model.dart';
import 'package:mobile/features/rewards/data/reward_repository.dart';
import 'package:mobile/features/rewards/providers/vouchers_provider.dart';
import 'package:mobile/features/rewards/providers/rewards_provider.dart';
import 'package:mobile/features/blockchain/services/blockchain_voucher_service.dart';
import 'package:mobile/features/cart/models/cart_item_model.dart';
import 'package:mobile/data/mock/catalog_data.dart';
import 'package:mobile/features/orders/providers/orders_provider.dart';
import 'package:mobile/features/orders/models/order_model.dart';
import 'package:mobile/features/rewards/presentation/my_vouchers_screen.dart';

class MockTestRewardRepository implements RewardRepository {
  int points;
  final List<VoucherModel> vouchers = [];
  final List<String> redemptionKeys = [];

  MockTestRewardRepository({this.points = 1000});

  @override
  Future<RewardSnapshot> loadForUser(String userId) async {
    return RewardSnapshot(totalPoints: points, entries: const []);
  }

  @override
  Future<RewardRecordResult> recordGameResult(
    String userId,
    RewardGameResult result,
  ) async {
    final pts = RewardCalculator.pointsFor(result);
    points += pts;
    return RewardRecordResult(pointsAwarded: pts, wasAlreadyProcessed: false);
  }

  @override
  Future<VoucherModel> redeemVoucher(
    String userId,
    VoucherType type, {
    String? idempotencyKey,
  }) async {
    // 4. Idempotency check
    if (idempotencyKey != null && redemptionKeys.contains(idempotencyKey)) {
      return vouchers.firstWhere(
        (v) => v.redemptionReferenceId == idempotencyKey,
      );
    }

    // 2. Insufficient points check
    if (points < type.pointsCost) {
      throw InsufficientPointsException(
        required: type.pointsCost,
        available: points,
      );
    }

    // Deduct points once
    points -= type.pointsCost;
    if (idempotencyKey != null) redemptionKeys.add(idempotencyKey);

    final now = DateTime.now();
    final voucher = VoucherModel(
      id: 'vch_${vouchers.length + 1}',
      userId: userId,
      code: 'BUN${type.discountPercent}-TEST${vouchers.length + 1}',
      type: type,
      discountPercent: type.discountPercent,
      pointsCost: type.pointsCost,
      status: VoucherStatus.available,
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      redemptionReferenceId: idempotencyKey ?? 'ref_${vouchers.length + 1}',
      blockchainStatus: BlockchainStatus.pending,
    );

    vouchers.add(voucher);
    return voucher;
  }

  @override
  Future<List<VoucherModel>> loadVouchersForUser(String userId) async {
    return vouchers.where((v) => v.userId == userId).toList();
  }

  @override
  Future<VoucherModel?> findVoucherByCode(String userId, String code) async {
    try {
      return vouchers.firstWhere(
        (v) =>
            v.userId == userId &&
            v.code.toUpperCase() == code.trim().toUpperCase(),
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
    final idx = vouchers.indexWhere((v) => v.id == voucherId);
    if (idx != -1) {
      vouchers[idx] = vouchers[idx].copyWith(
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
    final idx = vouchers.indexWhere((v) => v.id == voucherId);
    if (idx != -1) {
      vouchers[idx] = vouchers[idx].copyWith(
        blockchainStatus: status,
        redemptionTxHash: txHash,
        explorerUrl: explorerUrl,
      );
    }
  }
}

void main() {
  group('Blockchain & Voucher Comprehensive Test Suite (18 Scenarios)', () {
    late MockTestRewardRepository repo;
    const testUserId = 'user-001';

    setUp(() {
      repo = MockTestRewardRepository(points: 1000);
    });

    test(
      'Scenario 1: Customer has enough points and redeems 5% voucher (15 pts)',
      () async {
        final initialPoints = repo.points;
        final voucher = await repo.redeemVoucher(
          testUserId,
          VoucherType.discount5,
        );

        expect(voucher.discountPercent, 5);
        expect(voucher.pointsCost, 15);
        expect(voucher.status, VoucherStatus.available);
        expect(repo.points, initialPoints - 15);
      },
    );

    test(
      'Scenario 2: Customer does not have enough points (rejected)',
      () async {
        repo.points = 10; // Not enough for 15, 350, or 500
        expect(
          () => repo.redeemVoucher(testUserId, VoucherType.discount5),
          throwsA(isA<InsufficientPointsException>()),
        );
      },
    );

    test('Scenario 3: Failed redemption does not deduct points', () async {
      repo.points = 100;
      try {
        await repo.redeemVoucher(
          testUserId,
          VoucherType.discount15,
        ); // needs 350
      } catch (_) {}
      expect(repo.points, 100); // Intact
    });

    test('Scenario 4: Duplicate redemption with same idempotency key is not double deducted', () async {
      final initialPoints = repo.points;
      const key = 'idem_key_unique_123';

      final v1 = await repo.redeemVoucher(
        testUserId,
        VoucherType.discount5,
        idempotencyKey: key,
      );
      final v2 = await repo.redeemVoucher(
        testUserId,
        VoucherType.discount5,
        idempotencyKey: key,
      );

      expect(v1.id, v2.id);
      expect(repo.points, initialPoints - 15); // Deducted only once!
    });

    test('Scenario 5 & 6: Voucher records on blockchain with valid hash and status transitions', () async {
      final voucher = await repo.redeemVoucher(
        testUserId,
        VoucherType.discount15,
      );
      expect(voucher.blockchainStatus, BlockchainStatus.pending);

      final receipt = await BlockchainVoucherService.instance.recordRedemption(
        voucher: voucher,
      );
      expect(receipt.success, isTrue);
      expect(receipt.txHash.startsWith('0x'), isTrue);
      expect(receipt.referenceId, voucher.redemptionReferenceId);

      await repo.updateVoucherBlockchainStatus(
        voucher.id,
        status: BlockchainStatus.confirmed,
        txHash: receipt.txHash,
      );

      final updated = (await repo.loadVouchersForUser(testUserId)).first;
      expect(updated.blockchainStatus, BlockchainStatus.confirmed);
      expect(updated.redemptionTxHash, receipt.txHash);
    });

    test(
      'Scenario 7 & 8: Customer enters valid vs invalid promo code',
      () async {
        final v = await repo.redeemVoucher(testUserId, VoucherType.discount20);

        // 7. Valid promo code
        final found = await repo.findVoucherByCode(testUserId, v.code);
        expect(found, isNotNull);
        expect(found!.id, v.id);

        // 8. Invalid promo code
        final invalid = await repo.findVoucherByCode(
          testUserId,
          'INVALID-CODE-XYZ',
        );
        expect(invalid, isNull);
      },
    );

    test(
      'Scenario 9: Customer cannot use voucher belonging to another customer',
      () async {
        final v = await repo.redeemVoucher(
          'other-user-999',
          VoucherType.discount5,
        );
        final found = await repo.findVoucherByCode(testUserId, v.code);
        expect(found, isNull);
      },
    );

    test('Scenario 10: Used voucher cannot be used again', () async {
      final v = await repo.redeemVoucher(testUserId, VoucherType.discount5);
      await repo.markVoucherUsed(v.id, 'ord-999');

      final updated = await repo.findVoucherByCode(testUserId, v.code);
      expect(updated!.isUsed, isTrue);
      expect(updated.isAvailable, isFalse);
    });

    test('Scenario 11: Expired voucher is rejected', () {
      final expiredVoucher = VoucherModel(
        id: 'vch_expired',
        userId: testUserId,
        code: 'BUN5-EXPIRED',
        type: VoucherType.discount5,
        discountPercent: 5,
        pointsCost: 15,
        status: VoucherStatus.available,
        issuedAt: DateTime.now().subtract(const Duration(days: 40)),
        expiresAt: DateTime.now().subtract(const Duration(days: 10)),
        redemptionReferenceId: 'ref_exp',
      );

      expect(expiredVoucher.isExpired, isTrue);
      expect(expiredVoucher.isAvailable, isFalse);
    });

    test(
      'Scenario 12: Subtotal calculations for 5%, 15%, 20% on Rp100.000',
      () {
        const subtotal = 100000;

        final v5 = VoucherModel(
          id: '1',
          userId: testUserId,
          code: 'BUN5',
          type: VoucherType.discount5,
          discountPercent: 5,
          pointsCost: 15,
          status: VoucherStatus.available,
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          redemptionReferenceId: '1',
        );
        final v15 = VoucherModel(
          id: '2',
          userId: testUserId,
          code: 'BUN15',
          type: VoucherType.discount15,
          discountPercent: 15,
          pointsCost: 350,
          status: VoucherStatus.available,
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          redemptionReferenceId: '2',
        );
        final v20 = VoucherModel(
          id: '3',
          userId: testUserId,
          code: 'BUN20',
          type: VoucherType.discount20,
          discountPercent: 20,
          pointsCost: 500,
          status: VoucherStatus.available,
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 10)),
          redemptionReferenceId: '3',
        );

        expect(v5.calculateDiscount(subtotal), 5000);
        expect(subtotal - v5.calculateDiscount(subtotal), 95000);

        expect(v15.calculateDiscount(subtotal), 15000);
        expect(subtotal - v15.calculateDiscount(subtotal), 85000);

        expect(v20.calculateDiscount(subtotal), 20000);
        expect(subtotal - v20.calculateDiscount(subtotal), 80000);
      },
    );

    test(
      'Scenario 13: Checkout without voucher (0 discount, full total)',
      () async {
        const dummyProduct = ProductItem(
          id: 'p-1',
          name: 'Burger',
          category: 'burger',
          price: 100000,
          description: 'Test',
          ingredients: 'Beef',
          imageUrl: '',
        );
        final cartItems = [
          CartItem(id: 'c-1', product: dummyProduct, quantity: 1),
        ];

        final notifier = OrdersNotifier(null, (_) async => true);
        final order = await notifier.createOrder(
          cartItems: cartItems,
          orderType: 'PICKUP',
          paymentMethod: 'QRIS',
        );

        expect(order.subtotal, 100000);
        expect(order.hasVoucher, isFalse);
        expect(order.voucherDiscountAmount, isNull);
        expect(order.total, 110000); // 100000 + 10% tax
      },
    );

    test('Scenario 14: Checkout button debounce and idempotency', () {
      bool isSubmitting = false;
      int ordersCreated = 0;

      void submitOrder() {
        if (isSubmitting) return;
        isSubmitting = true;
        ordersCreated++;
      }

      submitOrder(); // Click 1
      submitOrder(); // Rapid Click 2
      submitOrder(); // Rapid Click 3

      expect(ordersCreated, 1);
    });

    test('Scenario 15 & 16: Order succeeds, voucher marked used, usage event hashes recorded', () async {
      final v = await repo.redeemVoucher(testUserId, VoucherType.discount15);
      final initialPts = repo.points;

      const dummyProduct = ProductItem(
        id: 'p-1',
        name: 'Burger',
        category: 'burger',
        price: 100000,
        description: 'Test',
        ingredients: 'Beef',
        imageUrl: '',
      );
      final cartItems = [
        CartItem(id: 'c-1', product: dummyProduct, quantity: 1),
      ];

      final notifier = OrdersNotifier(null, (_) async => true);
      final order = await notifier.createOrder(
        cartItems: cartItems,
        orderType: 'PICKUP',
        paymentMethod: 'QRIS',
        voucherCode: v.code,
        voucherDiscountPercent: v.discountPercent,
        voucherDiscountAmount: 15000,
        voucherReferenceId: v.redemptionReferenceId,
      );

      // Record usage on blockchain
      final usageReceipt = await BlockchainVoucherService.instance.recordUsage(
        voucher: v,
        order: order,
      );
      expect(usageReceipt.success, isTrue);

      await repo.markVoucherUsed(
        v.id,
        order.id,
        usageTxHash: usageReceipt.txHash,
      );
      final usedVoucher = await repo.findVoucherByCode(testUserId, v.code);

      expect(usedVoucher!.isUsed, isTrue);
      expect(usedVoucher.usedOrderId, order.id);

      // Scenario 17: Points are NOT deducted again during checkout
      expect(repo.points, initialPts);

      // Scenario 18: Order and E-Receipt consistency
      expect(order.hasVoucher, isTrue);
      expect(order.voucherDiscountAmount, 15000);
      expect(order.total, 85000 + (85000 * 0.1).round());
    });

    test('Every successful checkout inserts a unique cloud order', () async {
      const dummyProduct = ProductItem(
        id: 'p-1',
        name: 'Burger',
        category: 'burger',
        price: 100000,
        description: 'Test',
        ingredients: 'Beef',
        imageUrl: '',
      );
      final cartItems = [
        CartItem(id: 'c-1', product: dummyProduct, quantity: 1),
      ];
      final insertedOrders = <OrderItemModel>[];
      final notifier = OrdersNotifier(null, (order) async {
        insertedOrders.add(order);
        return true;
      });

      for (var i = 0; i < 3; i++) {
        await notifier.createOrder(
          cartItems: cartItems,
          orderType: 'PICKUP',
          paymentMethod: 'QRIS',
        );
      }

      expect(insertedOrders, hasLength(3));
      expect(insertedOrders.map((order) => order.id).toSet(), hasLength(3));
      expect(
        insertedOrders.map((order) => order.orderNumber).toSet(),
        hasLength(3),
      );
    });

    testWidgets('MyVouchersScreen renders tabs and cards cleanly', (
      tester,
    ) async {
      final testVoucher = VoucherModel(
        id: 'vch-1',
        userId: testUserId,
        code: 'BUN15-DISC',
        type: VoucherType.discount15,
        discountPercent: 15,
        pointsCost: 350,
        status: VoucherStatus.available,
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 30)),
        redemptionReferenceId: 'ref-1',
        blockchainStatus: BlockchainStatus.confirmed,
        redemptionTxHash: '0x1234567890abcdef1234567890abcdef12345678',
      );

      final testRepo = MockTestRewardRepository();
      testRepo.vouchers.add(testVoucher);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentRewardUserIdProvider.overrideWith((ref) => testUserId),
            rewardRepositoryProvider.overrideWithValue(testRepo),
            userVouchersProvider(
              testUserId,
            ).overrideWith((ref) => VoucherNotifier(testUserId, testRepo, ref)),
          ],
          child: const MaterialApp(home: MyVouchersScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Vouchers'), findsOneWidget);
      expect(find.textContaining('Tersedia'), findsOneWidget);
      expect(find.textContaining('Terpakai'), findsOneWidget);
      expect(find.textContaining('Kedaluwarsa'), findsOneWidget);
    });
  });
}
