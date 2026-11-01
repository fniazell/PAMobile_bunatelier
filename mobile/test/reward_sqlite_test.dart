import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/local/app_database.dart';
import 'package:mobile/features/rewards/data/reward_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'SQLite persists per-user points and processes each session once',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bun_reward_test_',
      );
      final databasePath = p.join(directory.path, 'rewards.db');
      Database? database;
      Database? reopenedDatabase;

      try {
        database = await databaseFactoryFfi.openDatabase(databasePath);
        await createRewardTables(database);
        final repository = SqliteRewardRepository(database: database);
        final result = RewardGameResult(
          sessionId: 'session-unique-1',
          score: 650,
          stackedIngredients: 5,
          precisionHits: 2,
          victory: false,
          playedAt: DateTime.utc(2026, 10, 22, 12),
        );

        final first = await repository.recordGameResult('user-a', result);
        final duplicate = await repository.recordGameResult(
          'user-a',
          RewardGameResult(
            sessionId: result.sessionId,
            score: 9999,
            stackedIngredients: 5,
            precisionHits: 2,
            victory: false,
            playedAt: result.playedAt,
          ),
        );

        expect(first.wasAlreadyProcessed, isFalse);
        expect(duplicate.wasAlreadyProcessed, isTrue);
        expect(duplicate.pointsAwarded, first.pointsAwarded);
        expect((await repository.loadForUser('user-a')).entries, hasLength(1));
        expect((await repository.loadForUser('user-b')).totalPoints, 0);
        await expectLater(
          repository.recordGameResult('user-b', result),
          throwsStateError,
        );

        await database.close();
        database = null;

        reopenedDatabase = await databaseFactoryFfi.openDatabase(databasePath);
        final reopenedRepository = SqliteRewardRepository(
          database: reopenedDatabase,
        );
        final restored = await reopenedRepository.loadForUser('user-a');
        expect(restored.totalPoints, first.pointsAwarded);
        expect(restored.entries.single.sessionId, result.sessionId);
        expect(
          await reopenedRepository.loadForUser('user-b'),
          isA<RewardSnapshot>().having(
            (value) => value.totalPoints,
            'points',
            0,
          ),
        );
      } finally {
        if (database != null) await database.close();
        if (reopenedDatabase != null) await reopenedDatabase.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
