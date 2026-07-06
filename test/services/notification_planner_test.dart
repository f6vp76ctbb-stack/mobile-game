import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/notification_planner.dart';

void main() {
  ScheduledNote? noteOf(List<ScheduledNote> notes, GridNotification t) {
    for (final n in notes) {
      if (n.type == t) return n;
    }
    return null;
  }

  group('daily reminder', () {
    test('scheduled for today 19:00 when open and before 19:00', () {
      final notes = NotificationPlanner.plan(
        now: DateTime(2026, 7, 5, 10),
        dailyDoneToday: false,
        streak: 0,
      );
      final n = noteOf(notes, GridNotification.dailyReminder)!;
      expect(n.when, DateTime(2026, 7, 5, 19));
    });

    test('moves to tomorrow when past 19:00', () {
      final notes = NotificationPlanner.plan(
        now: DateTime(2026, 7, 5, 20),
        dailyDoneToday: false,
        streak: 0,
      );
      final n = noteOf(notes, GridNotification.dailyReminder)!;
      expect(n.when, DateTime(2026, 7, 6, 19));
    });

    test('moves to tomorrow when the daily is already done', () {
      final notes = NotificationPlanner.plan(
        now: DateTime(2026, 7, 5, 10),
        dailyDoneToday: true,
        streak: 5,
      );
      final n = noteOf(notes, GridNotification.dailyReminder)!;
      expect(n.when, DateTime(2026, 7, 6, 19));
    });
  });

  group('streak warning', () {
    test('absent below the minimum streak', () {
      final notes = NotificationPlanner.plan(
        now: DateTime(2026, 7, 5, 10),
        dailyDoneToday: false,
        streak: 2,
      );
      expect(noteOf(notes, GridNotification.streakWarning), isNull);
    });

    test('present at 21:30 with an active streak', () {
      final notes = NotificationPlanner.plan(
        now: DateTime(2026, 7, 5, 10),
        dailyDoneToday: false,
        streak: 3,
      );
      final n = noteOf(notes, GridNotification.streakWarning)!;
      expect(n.when, DateTime(2026, 7, 5, 21, 30));
      expect(n.title, contains('3'));
    });
  });

  group('comeback', () {
    test('scheduled 72h out', () {
      final now = DateTime(2026, 7, 5, 10);
      final notes = NotificationPlanner.plan(
        now: now,
        dailyDoneToday: false,
        streak: 0,
      );
      final n = noteOf(notes, GridNotification.comeback)!;
      expect(n.when, now.add(const Duration(hours: 72)));
    });

    test('gift only after 72h of absence', () {
      final now = DateTime(2026, 7, 5, 10);
      expect(NotificationPlanner.comebackGift(lastActive: null, now: now), 0);
      expect(
        NotificationPlanner.comebackGift(
          lastActive: now.subtract(const Duration(hours: 71)),
          now: now,
        ),
        0,
      );
      expect(
        NotificationPlanner.comebackGift(
          lastActive: now.subtract(const Duration(hours: 73)),
          now: now,
        ),
        NotificationPlanner.comebackGiftCoins,
      );
    });
  });

  test('note ids are stable and unique per type', () {
    final notes = NotificationPlanner.plan(
      now: DateTime(2026, 7, 5, 10),
      dailyDoneToday: false,
      streak: 5,
    );
    final ids = notes.map((n) => n.id).toSet();
    expect(ids.length, notes.length);
  });
}
