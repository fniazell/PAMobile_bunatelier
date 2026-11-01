import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/rewards/data/reward_repository.dart';

void main() {
  final playedAt = DateTime.utc(2026, 10, 22);

  RewardGameResult result({
    String sessionId = 'session-1',
    int score = 400,
    int layers = 4,
    int precisionHits = 2,
    bool victory = false,
    bool isCompleted = true,
  }) {
    return RewardGameResult(
      sessionId: sessionId,
      score: score,
      stackedIngredients: layers,
      precisionHits: precisionHits,
      victory: victory,
      playedAt: playedAt,
      isCompleted: isCompleted,
    );
  }

  test('awards points for score, layers, precision, and victory', () {
    expect(RewardCalculator.pointsFor(result()), 80);
    expect(
      RewardCalculator.pointsFor(
        result(score: 3000, layers: 15, precisionHits: 15, victory: true),
      ),
      RewardCalculator.maxPointsPerGame,
    );
  });

  test('does not award points for unfinished sessions or invalid results', () {
    expect(
      () => RewardCalculator.pointsFor(result(isCompleted: false)),
      throwsArgumentError,
    );
    expect(
      () => RewardCalculator.pointsFor(
        result(layers: 15, precisionHits: 16, victory: true),
      ),
      throwsArgumentError,
    );
  });

  test('creates unique session identifiers', () {
    expect(createRewardSessionId(), isNot(createRewardSessionId()));
  });
}
