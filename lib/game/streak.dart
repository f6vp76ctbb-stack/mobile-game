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

/// Streak repair ("Streak-Schutz", MASTERPLAN.md C.2): exactly one missed day
/// can be healed for coins or a rewarded ad, at most once per 7 days.
class StreakRepair {
  const StreakRepair._();

  static const int coinCost = 150;
  static const int cooldownDays = 7;

  static int _dayDiff(DateTime from, DateTime to) {
    final a = DateTime(from.year, from.month, from.day);
    final b = DateTime(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Whether a repair is offered right now: an active streak, exactly one day
  /// missed (last play was 2 days ago), and no repair within the cooldown.
  static bool isRepairable({
    required String? lastDateKey,
    required int currentStreak,
    required DateTime today,
    required String? lastRepairDateKey,
  }) {
    if (lastDateKey == null || currentStreak < 1) return false;
    if (_dayDiff(DateTime.parse(lastDateKey), today) != 2) return false;
    if (lastRepairDateKey != null &&
        _dayDiff(DateTime.parse(lastRepairDateKey), today) < cooldownDays) {
      return false;
    }
    return true;
  }

  /// The `lastDailyDate` value to store after a repair, so completing today's
  /// challenge continues the streak (treats yesterday as played).
  static String repairedLastDateKey(DateTime today) =>
      DailyChallenge.dateKey(today.subtract(const Duration(days: 1)));
}
