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
}
