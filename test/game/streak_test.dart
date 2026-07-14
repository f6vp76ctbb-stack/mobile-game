import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/streak.dart';

void main() {
  group('rewardForStreak', () {
    test('base reward at streak 1', () {
      expect(DailyStreak.rewardForStreak(1), 60); // 50 + 10
    });

    test('bonus is capped', () {
      expect(DailyStreak.rewardForStreak(10), 150); // 50 + 100
      expect(DailyStreak.rewardForStreak(50), 150); // still capped
    });
  });

  group('onDailyCompleted', () {
    test('first ever completion starts a streak of 1 and rewards', () {
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: null,
        currentStreak: 0,
        today: DateTime(2026, 7, 5),
      );
      expect(r.streak, 1);
      expect(r.alreadyPlayedToday, isFalse);
      expect(r.coinsAwarded, 60);
    });

    test('consecutive day extends the streak', () {
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: '2026-07-04',
        currentStreak: 3,
        today: DateTime(2026, 7, 5),
      );
      expect(r.streak, 4);
      expect(r.coinsAwarded, DailyStreak.rewardForStreak(4));
    });

    test('replaying the same day yields no reward and no change', () {
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: '2026-07-05',
        currentStreak: 4,
        today: DateTime(2026, 7, 5, 20, 0),
      );
      expect(r.streak, 4);
      expect(r.alreadyPlayedToday, isTrue);
      expect(r.coinsAwarded, 0);
    });

    test('a gap resets the streak to 1', () {
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: '2026-07-01',
        currentStreak: 6,
        today: DateTime(2026, 7, 5),
      );
      expect(r.streak, 1);
      expect(r.coinsAwarded, 60);
    });

    test('extends correctly across a month boundary', () {
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: '2026-07-31',
        currentStreak: 2,
        today: DateTime(2026, 8, 1),
      );
      expect(r.streak, 3);
    });
  });

  group('StreakRepair', () {
    test('offered when exactly one day was missed', () {
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-03', // 2 days before the 5th
          currentStreak: 4,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: null,
        ),
        isTrue,
      );
    });

    test('not offered when yesterday was played (still on track)', () {
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-04',
          currentStreak: 4,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: null,
        ),
        isFalse,
      );
    });

    test('not offered when two or more days were missed', () {
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-02', // 3 days gap
          currentStreak: 4,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: null,
        ),
        isFalse,
      );
    });

    test('not offered without an active streak', () {
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-03',
          currentStreak: 0,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: null,
        ),
        isFalse,
      );
    });

    test('blocked within the 7-day cooldown, allowed after', () {
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-03',
          currentStreak: 4,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: '2026-07-01', // 4 days ago
        ),
        isFalse,
      );
      expect(
        StreakRepair.isRepairable(
          lastDateKey: '2026-07-03',
          currentStreak: 4,
          today: DateTime(2026, 7, 5),
          lastRepairDateKey: '2026-06-26', // 9 days ago
        ),
        isTrue,
      );
    });

    test('repaired key is yesterday, so completing today extends the streak',
        () {
      final today = DateTime(2026, 7, 5);
      final repaired = StreakRepair.repairedLastDateKey(today);
      expect(repaired, '2026-07-04');
      final r = DailyStreak.onDailyCompleted(
        lastDateKey: repaired,
        currentStreak: 4,
        today: today,
      );
      expect(r.streak, 5); // continued, not reset
    });
  });
}
