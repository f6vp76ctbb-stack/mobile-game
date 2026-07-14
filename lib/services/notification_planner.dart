/// Pure-Dart planning for local notifications. No Flutter imports — decides
/// WHAT to schedule and WHEN from the current state (MASTERPLAN.md C.2). The
/// delivery plugin is wired separately in `notifications.dart`.
library;

enum GridNotification { dailyReminder, streakWarning, comeback }

class ScheduledNote {
  const ScheduledNote({
    required this.type,
    required this.when,
    required this.title,
    required this.body,
  });

  final GridNotification type;
  final DateTime when;
  final String title;
  final String body;

  /// Stable per-type id for the plugin (so re-scheduling replaces cleanly).
  int get id => type.index;
}

class NotificationPlanner {
  const NotificationPlanner._();

  static const int dailyReminderHour = 19;
  static const int streakWarningHour = 21;
  static const int streakWarningMinute = 30;
  static const int streakWarningMinStreak = 3;
  static const Duration comebackAfter = Duration(hours: 72);
  static const int comebackGiftCoins = 100;

  static DateTime _nextAt(
    DateTime now,
    int hour,
    int minute, {
    required bool skipToday,
  }) {
    var d = DateTime(now.year, now.month, now.day, hour, minute);
    if (skipToday || !d.isAfter(now)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  /// The set of notifications to (re)schedule right now. Callers cancel all,
  /// then schedule these.
  static List<ScheduledNote> plan({
    required DateTime now,
    required bool dailyDoneToday,
    required int streak,
  }) {
    return [
      ScheduledNote(
        type: GridNotification.dailyReminder,
        when: _nextAt(now, dailyReminderHour, 0, skipToday: dailyDoneToday),
        title: 'Dein Puzzle des Tages wartet 🧩',
        body: 'Spiel die heutige Challenge!',
      ),
      if (streak >= streakWarningMinStreak)
        ScheduledNote(
          type: GridNotification.streakWarning,
          when: _nextAt(
            now,
            streakWarningHour,
            streakWarningMinute,
            skipToday: dailyDoneToday,
          ),
          title: '🔥 $streak-Tage-Streak in Gefahr!',
          body: 'Spiel heute, um ihn zu halten.',
        ),
      ScheduledNote(
        type: GridNotification.comeback,
        when: now.add(comebackAfter),
        title: 'Dein Puzzle vermisst dich 🧩',
        body: 'Komm zurück und hol dir ein Geschenk!',
      ),
    ];
  }

  /// Coins to grant on opening after a long absence (comeback gift, C.2).
  static int comebackGift({
    required DateTime? lastActive,
    required DateTime now,
  }) {
    if (lastActive == null) return 0;
    return now.difference(lastActive) >= comebackAfter ? comebackGiftCoins : 0;
  }
}
