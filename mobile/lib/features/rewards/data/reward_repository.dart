import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../data/local/app_database.dart';
import '../models/voucher_model.dart';

class RewardGameResult {
  const RewardGameResult({
    required this.sessionId,
    required this.score,
    required this.stackedIngredients,
    required this.precisionHits,
    required this.victory,
    required this.playedAt,
    this.isCompleted = true,
  });

  final String sessionId;
  final int score;
  final int stackedIngredients;
  final int precisionHits;
  final bool victory;
  final DateTime playedAt;
  final bool isCompleted;
}

class RewardEntry {
  const RewardEntry({
    required this.sessionId,
    required this.score,
    required this.stackedIngredients,
    required this.precisionHits,
    required this.victory,
    required this.pointsAwarded,
    required this.playedAt,
  });

  final String sessionId;
  final int score;
  final int stackedIngredients;
  final int precisionHits;
  final bool victory;
  final int pointsAwarded;
  final DateTime playedAt;

  factory RewardEntry.fromMap(Map<String, Object?> map) {
    return RewardEntry(
      sessionId: map['session_id']! as String,
      score: map['score']! as int,
      stackedIngredients: map['stacked_ingredients']! as int,
      precisionHits: map['precision_hits']! as int,
      victory: map['victory'] == 1,
      pointsAwarded: map['points_awarded']! as int,
      playedAt: DateTime.parse(map['played_at']! as String),
    );
  }
}

class RewardSnapshot {
  const RewardSnapshot({required this.totalPoints, required this.entries});

  final int totalPoints;
  final List<RewardEntry> entries;

  static const empty = RewardSnapshot(totalPoints: 0, entries: []);
}

class RewardRecordResult {
  const RewardRecordResult({
    required this.pointsAwarded,
    required this.wasAlreadyProcessed,
  });

  final int pointsAwarded;
  final bool wasAlreadyProcessed;
}

class InsufficientPointsException implements Exception {
  final int required;
  final int available;
  const InsufficientPointsException({required this.required, required this.available});

  @override
  String toString() => 'Poin tidak mencukupi: Butuh $required poin, tersedia $available poin.';
}

abstract interface class RewardRepository {
  Future<RewardSnapshot> loadForUser(String userId);

  Future<RewardRecordResult> recordGameResult(
    String userId,
    RewardGameResult result,
  );

  Future<VoucherModel> redeemVoucher(
    String userId,
    VoucherType type, {
    String? idempotencyKey,
  });

  Future<List<VoucherModel>> loadVouchersForUser(String userId);

  Future<VoucherModel?> findVoucherByCode(String userId, String code);

  Future<void> markVoucherUsed(
    String voucherId,
    String orderId, {
    String? usageTxHash,
    String? usageReferenceId,
  });

  Future<void> updateVoucherBlockchainStatus(
    String voucherId, {
    required BlockchainStatus status,
    String? txHash,
    String? explorerUrl,
  });
}

class RewardCalculator {
  const RewardCalculator._();

  static const int maxPointsPerGame = 500;
  static const int victoryBonus = 100;

  static int pointsFor(RewardGameResult result) {
    if (!result.isCompleted) {
      throw ArgumentError.value(result.isCompleted, 'isCompleted');
    }
    if (result.score < 0 ||
        result.stackedIngredients < 0 ||
        result.stackedIngredients > 15 ||
        result.precisionHits < 0 ||
        result.precisionHits > result.stackedIngredients ||
        (result.victory && result.stackedIngredients != 15)) {
      throw ArgumentError('Invalid completed Stack Bun result.');
    }

    final earned =
        result.score ~/ 10 +
        result.stackedIngredients * 5 +
        result.precisionHits * 10 +
        (result.victory ? victoryBonus : 0);
    return min(maxPointsPerGame, earned);
  }
}

String createRewardSessionId() {
  final random = Random.secure();
  final entropy = List<int>.generate(
    16,
    (_) => random.nextInt(256),
    growable: false,
  );
  final hex = entropy.map((value) => value.toRadixString(16).padLeft(2, '0'));
  final id = hex.join();
  return '${id.substring(0, 8)}-${id.substring(8, 12)}-'
      '${id.substring(12, 16)}-${id.substring(16, 20)}-${id.substring(20)}';
}

class SqliteRewardRepository implements RewardRepository {
  SqliteRewardRepository({AppDatabase? appDatabase, Database? database})
    : _appDatabase = appDatabase ?? AppDatabase.instance,
      _providedDatabase = database {
    if (appDatabase != null && database != null) {
      throw ArgumentError('Provide either AppDatabase or Database, not both.');
    }
  }

  final AppDatabase _appDatabase;
  final Database? _providedDatabase;

  Future<Database> get _database async =>
      _providedDatabase ?? await _appDatabase.database;

  @override
  Future<RewardSnapshot> loadForUser(String userId) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite reward storage is only available on mobile.',
      );
    }

    final db = await _database;
    return db.transaction((txn) async {
      final totalResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(points_awarded), 0) AS total '
        'FROM game_reward_sessions WHERE user_id = ?',
        [userId],
      );
      int spent = 0;
      try {
        final spentResult = await txn.rawQuery(
          'SELECT COALESCE(SUM(points_spent), 0) AS total '
          'FROM user_point_redemptions WHERE user_id = ?',
          [userId],
        );
        spent = spentResult.single['total']! as int;
      } catch (_) {
        spent = 0;
      }
      final rows = await txn.query(
        'game_reward_sessions',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'played_at DESC',
      );
      final earned = totalResult.single['total']! as int;
      final netPoints = max(0, earned - spent);

      return RewardSnapshot(
        totalPoints: netPoints,
        entries: rows.map(RewardEntry.fromMap).toList(growable: false),
      );
    });
  }

  @override
  Future<RewardRecordResult> recordGameResult(
    String userId,
    RewardGameResult result,
  ) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    if (result.sessionId.isEmpty) {
      throw ArgumentError.value(result.sessionId, 'sessionId');
    }
    if (!result.isCompleted) {
      throw StateError('Points are only awarded for completed game sessions.');
    }
    if (kIsWeb) {
      throw UnsupportedError(
        'SQLite reward storage is only available on mobile.',
      );
    }
    final points = RewardCalculator.pointsFor(result);
    final db = await _database;

    return db.transaction((txn) async {
      final existingRows = await txn.query(
        'game_reward_sessions',
        where: 'session_id = ?',
        whereArgs: [result.sessionId],
        limit: 1,
      );
      if (existingRows.isNotEmpty) {
        final existing = existingRows.single;
        if (existing['user_id'] != userId) {
          throw StateError('This game session belongs to another account.');
        }
        return RewardRecordResult(
          pointsAwarded: existing['points_awarded']! as int,
          wasAlreadyProcessed: true,
        );
      }

      await txn.insert('game_reward_sessions', {
        'session_id': result.sessionId,
        'user_id': userId,
        'score': result.score,
        'stacked_ingredients': result.stackedIngredients,
        'precision_hits': result.precisionHits,
        'victory': result.victory ? 1 : 0,
        'points_awarded': points,
        'played_at': result.playedAt.toUtc().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      return RewardRecordResult(
        pointsAwarded: points,
        wasAlreadyProcessed: false,
      );
    });
  }

  @override
  Future<VoucherModel> redeemVoucher(
    String userId,
    VoucherType type, {
    String? idempotencyKey,
  }) async {
    if (userId.isEmpty) throw ArgumentError.value(userId, 'userId');
    final db = await _database;
    final cost = type.pointsCost;

    return db.transaction((txn) async {
      // 1. Idempotency check: if key already exists, return existing voucher
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        final existingRedemption = await txn.query(
          'user_point_redemptions',
          where: 'reference_id = ?',
          whereArgs: [idempotencyKey],
          limit: 1,
        );
        if (existingRedemption.isNotEmpty) {
          final voucherId = existingRedemption.first['voucher_id'] as String;
          final existingVoucherRows = await txn.query(
            'user_vouchers',
            where: 'id = ?',
            whereArgs: [voucherId],
            limit: 1,
          );
          if (existingVoucherRows.isNotEmpty) {
            return VoucherModel.fromMap(existingVoucherRows.first);
          }
        }
      }

      // 2. Atomic check of current net points balance
      final earnedResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(points_awarded), 0) AS total FROM game_reward_sessions WHERE user_id = ?',
        [userId],
      );
      final spentResult = await txn.rawQuery(
        'SELECT COALESCE(SUM(points_spent), 0) AS total FROM user_point_redemptions WHERE user_id = ?',
        [userId],
      );
      final earned = earnedResult.single['total']! as int;
      final spent = spentResult.single['total']! as int;
      final currentBalance = max(0, earned - spent);

      if (currentBalance < cost) {
        throw InsufficientPointsException(required: cost, available: currentBalance);
      }

      final now = DateTime.now();
      final nowIso = now.toIso8601String();
      final voucherId = 'vch_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final randomSuffix = Random().nextInt(0xFFFFFF).toRadixString(16).toUpperCase().padLeft(6, '0');
      final code = 'BUN${type.discountPercent}-$randomSuffix';
      final referenceId = idempotencyKey ??
          sha256.convert(utf8.encode('$voucherId|$userId|$code|$nowIso')).toString();
      final redemptionId = 'red_${now.millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      final expiresAt = now.add(const Duration(days: 30));

      // Insert point deduction
      await txn.insert('user_point_redemptions', {
        'redemption_id': redemptionId,
        'user_id': userId,
        'voucher_id': voucherId,
        'points_spent': cost,
        'redeemed_at': nowIso,
        'reference_id': referenceId,
        'blockchain_status': 'PENDING',
        'tx_hash': null,
      });

      final voucherMap = <String, dynamic>{
        'id': voucherId,
        'user_id': userId,
        'code': code,
        'voucher_type': type.name,
        'discount_percent': type.discountPercent,
        'points_cost': cost,
        'status': 'AVAILABLE',
        'issued_at': nowIso,
        'expires_at': expiresAt.toIso8601String(),
        'used_at': null,
        'used_order_id': null,
        'redemption_reference_id': referenceId,
        'redemption_tx_hash': null,
        'blockchain_status': 'PENDING',
        'usage_tx_hash': null,
        'usage_reference_id': null,
      };

      await txn.insert('user_vouchers', voucherMap);
      return VoucherModel.fromMap(voucherMap);
    });
  }

  @override
  Future<List<VoucherModel>> loadVouchersForUser(String userId) async {
    if (userId.isEmpty) return [];
    final db = await _database;
    final nowIso = DateTime.now().toIso8601String();

    // Automatically transition expired available vouchers
    await db.update(
      'user_vouchers',
      {'status': 'EXPIRED'},
      where: 'user_id = ? AND status = ? AND expires_at < ?',
      whereArgs: [userId, 'AVAILABLE', nowIso],
    );

    final rows = await db.query(
      'user_vouchers',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'issued_at DESC',
    );

    return rows.map(VoucherModel.fromMap).toList();
  }

  @override
  Future<VoucherModel?> findVoucherByCode(String userId, String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return null;
    final db = await _database;
    final rows = await db.query(
      'user_vouchers',
      where: 'user_id = ? AND UPPER(code) = ?',
      whereArgs: [userId, trimmed],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return VoucherModel.fromMap(rows.first);
  }

  @override
  Future<void> markVoucherUsed(
    String voucherId,
    String orderId, {
    String? usageTxHash,
    String? usageReferenceId,
  }) async {
    final db = await _database;
    final nowIso = DateTime.now().toIso8601String();
    final values = <String, Object?>{
      'status': 'USED',
      'used_at': nowIso,
      'used_order_id': orderId,
    };
    if (usageTxHash != null) values['usage_tx_hash'] = usageTxHash;
    if (usageReferenceId != null) values['usage_reference_id'] = usageReferenceId;

    await db.update(
      'user_vouchers',
      values,
      where: 'id = ?',
      whereArgs: [voucherId],
    );
  }

  @override
  Future<void> updateVoucherBlockchainStatus(
    String voucherId, {
    required BlockchainStatus status,
    String? txHash,
    String? explorerUrl,
  }) async {
    final db = await _database;
    final voucherValues = <String, Object?>{
      'blockchain_status': status.name.toUpperCase(),
    };
    if (txHash != null) voucherValues['redemption_tx_hash'] = txHash;

    await db.update(
      'user_vouchers',
      voucherValues,
      where: 'id = ?',
      whereArgs: [voucherId],
    );

    final redemptionValues = <String, Object?>{
      'blockchain_status': status.name.toUpperCase(),
    };
    if (txHash != null) redemptionValues['tx_hash'] = txHash;

    await db.update(
      'user_point_redemptions',
      redemptionValues,
      where: 'voucher_id = ?',
      whereArgs: [voucherId],
    );
  }
}
