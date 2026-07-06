/// Pure-Dart player XP / level system (MASTERPLAN.md C.3). No Flutter imports.
///
/// Level starts at 1. XP is tracked *within* the current level; reaching the
/// threshold levels up and rolls the remainder over.
library;

class LevelSystem {
  const LevelSystem._();

  static const int baseCost = 100;
  static const int costPerLevel = 50;
  static const int skinEveryLevels = 5;

  /// XP required to advance from [level] to [level] + 1.
  static int xpForNext(int level) => baseCost + costPerLevel * level;

  /// Coins granted for reaching [level].
  static int levelReward(int level) => 20 + 5 * level;

  /// XP earned for a finished run.
  static int xpForRun({required int score, required bool dailyCompleted}) {
    return (score ~/ 100) + (dailyCompleted ? 50 : 0);
  }

  /// Applies [gainedXp] to a (level, xpIntoLevel) state and returns the new
  /// state plus any level-ups.
  static LevelOutcome applyXp({
    required int level,
    required int xpIntoLevel,
    required int gainedXp,
  }) {
    var lvl = level;
    var xp = xpIntoLevel + (gainedXp < 0 ? 0 : gainedXp);
    var coins = 0;
    final gained = <int>[];
    while (xp >= xpForNext(lvl)) {
      xp -= xpForNext(lvl);
      lvl += 1;
      gained.add(lvl);
      coins += levelReward(lvl);
    }
    return LevelOutcome(
      level: lvl,
      xpIntoLevel: xp,
      levelsGained: gained,
      coinsAwarded: coins,
      skinsUnlocked: gained.where((l) => l % skinEveryLevels == 0).length,
    );
  }
}

class LevelOutcome {
  const LevelOutcome({
    required this.level,
    required this.xpIntoLevel,
    required this.levelsGained,
    required this.coinsAwarded,
    required this.skinsUnlocked,
  });

  final int level;
  final int xpIntoLevel;
  final List<int> levelsGained;
  final int coinsAwarded;
  final int skinsUnlocked;

  bool get leveledUp => levelsGained.isNotEmpty;
}
