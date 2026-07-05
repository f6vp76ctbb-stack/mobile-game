/// Pure-Dart Daily Challenge streak + reward logic. No Flutter imports.
library;

import 'daily.dart';

/// Outcome of completing (or re-opening) today's Daily Challenge.
class StreakResult {
  const StreakResult({
    required this.streak,
    required this.alreadyPlayedToday,
    required this.coinsAwarded,
  });

  final int streak;

  /// True when today's challenge was already completed earlier (no new reward).
  final bool alreadyPlayedToday;

  /// Coins granted for this completion (0 when already played today).
  final int coinsAwarded;
}

class DailyStreak {
  const DailyStreak._();

  /// Base reward for finishing the Daily Challenge (Anhang A.3).
  static const int baseReward = 50;

  /// Extra coins per streak day, capped at [maxStreakBonus].
  static const int perStreakDay = 10;
  static const int maxStreakBonus = 100;

  /// Coins for completing the daily at the given [streak] length.
  static int rewardForStreak(int streak) {
    final bonus = (streak * perStreakDay).clamp(0, maxStreakBonus);
    return baseReward + bonus;
  }

  /// Computes the new streak state when the player completes today's challenge.
  ///
  /// - Same day as [lastDateKey] → no change, no reward.
  /// - Exactly one day after → streak extends.
  /// - First ever, or a gap of 2+ days → streak resets to 1.
  static StreakResult onDailyCompleted({
    required String? lastDateKey,
    required int currentStreak,
    required DateTime today,
  }) {
    final todayKey = DailyChallenge.dateKey(today);
    if (lastDateKey == todayKey) {
      return StreakResult(
        streak: currentStreak,
        alreadyPlayedToday: true,
        coinsAwarded: 0,
      );
    }

    var newStreak = 1;
    if (lastDateKey != null) {
      final last = DateTime.parse(lastDateKey);
      if (DailyChallenge.isConsecutiveDay(last, today)) {
        newStreak = currentStreak + 1;
      }
    }

    return StreakResult(
      streak: newStreak,
      alreadyPlayedToday: false,
      coinsAwarded: rewardForStreak(newStreak),
    );
  }
}
