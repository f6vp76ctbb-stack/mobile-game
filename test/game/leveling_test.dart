import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/leveling.dart';

void main() {
  group('curves', () {
    test('xpForNext follows 100 + 50*level', () {
      expect(LevelSystem.xpForNext(1), 150);
      expect(LevelSystem.xpForNext(2), 200);
      expect(LevelSystem.xpForNext(10), 600);
    });

    test('levelReward follows 20 + 5*level', () {
      expect(LevelSystem.levelReward(2), 30);
      expect(LevelSystem.levelReward(5), 45);
    });
  });

  group('xpForRun', () {
    test('one XP per 100 points, floored', () {
      expect(LevelSystem.xpForRun(score: 250, dailyCompleted: false), 2);
      expect(LevelSystem.xpForRun(score: 99, dailyCompleted: false), 0);
    });

    test('daily completion adds 50', () {
      expect(LevelSystem.xpForRun(score: 250, dailyCompleted: true), 52);
    });
  });

  group('applyXp', () {
    test('no level-up below the threshold', () {
      final o = LevelSystem.applyXp(level: 1, xpIntoLevel: 0, gainedXp: 100);
      expect(o.leveledUp, isFalse);
      expect(o.level, 1);
      expect(o.xpIntoLevel, 100);
      expect(o.coinsAwarded, 0);
    });

    test('single level-up rolls over the remainder', () {
      // level 1 needs 150; 20 + 140 = 160 -> level 2 with 10 left.
      final o = LevelSystem.applyXp(level: 1, xpIntoLevel: 20, gainedXp: 140);
      expect(o.level, 2);
      expect(o.xpIntoLevel, 10);
      expect(o.levelsGained, [2]);
      expect(o.coinsAwarded, LevelSystem.levelReward(2));
    });

    test('multiple level-ups in one gain accumulate rewards', () {
      // From level 1 with 0: need 150 (->2), then 200 (->3) = 350 total.
      final o = LevelSystem.applyXp(level: 1, xpIntoLevel: 0, gainedXp: 350);
      expect(o.level, 3);
      expect(o.xpIntoLevel, 0);
      expect(o.levelsGained, [2, 3]);
      expect(
        o.coinsAwarded,
        LevelSystem.levelReward(2) + LevelSystem.levelReward(3),
      );
    });

    test('every 5th level counts a skin unlock', () {
      // Push from level 4 to level 5.
      final o = LevelSystem.applyXp(
        level: 4,
        xpIntoLevel: 0,
        gainedXp: LevelSystem.xpForNext(4),
      );
      expect(o.level, 5);
      expect(o.skinsUnlocked, 1);
    });
  });
}
