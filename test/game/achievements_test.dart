import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/achievements.dart';

void main() {
  group('catalog integrity', () {
    test('ids are unique and thresholds positive', () {
      final ids = Achievements.catalog.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(Achievements.catalog.every((a) => a.threshold > 0), isTrue);
      expect(Achievements.catalog.every((a) => a.icon.isNotEmpty), isTrue);
    });
  });

  group('unlockedFor', () {
    test('nothing unlocked at zero progress except no-op', () {
      expect(Achievements.unlockedFor(const AchievementProgress()), isEmpty);
    });

    test('first game unlocks after one game', () {
      final u = Achievements.unlockedFor(const AchievementProgress(games: 1));
      expect(u, contains('first_game'));
      expect(u, isNot(contains('games_25')));
    });

    test('high metrics unlock all tiers of that metric', () {
      final u =
          Achievements.unlockedFor(const AchievementProgress(highscore: 30000));
      expect(u, containsAll(['score_1k', 'score_5k', 'score_10k', 'score_25k']));
    });
  });

  group('fraction', () {
    test('is clamped between 0 and 1', () {
      final a = Achievements.byId('score_10k'); // threshold 10000
      expect(
        Achievements.fraction(a, const AchievementProgress(highscore: 5000)),
        0.5,
      );
      expect(
        Achievements.fraction(a, const AchievementProgress(highscore: 99999)),
        1.0,
      );
      expect(
        Achievements.fraction(a, const AchievementProgress()),
        0.0,
      );
    });
  });

  group('newlyUnlocked', () {
    test('returns only achievements not already unlocked', () {
      const p = AchievementProgress(games: 1, highscore: 1200);
      final fresh = Achievements.newlyUnlocked(p, {'first_game'});
      final ids = fresh.map((a) => a.id).toList();
      expect(ids, contains('score_1k'));
      expect(ids, isNot(contains('first_game')));
    });

    test('empty when nothing new crosses a threshold', () {
      const p = AchievementProgress(games: 1);
      expect(Achievements.newlyUnlocked(p, {'first_game'}), isEmpty);
    });
  });
}
