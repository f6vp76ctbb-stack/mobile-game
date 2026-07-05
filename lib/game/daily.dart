/// Pure-Dart Daily Challenge seeding for GridPop. No Flutter imports.
///
/// Every calendar day maps to one fixed seed, so all players face the same
/// puzzle. The same seed feeds [PieceGenerator], making the day reproducible.
library;

class DailyChallenge {
  const DailyChallenge._();

  /// A stable seed derived only from the calendar date (time-of-day ignored).
  static int seedForDate(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  /// The seed for today. Pass [now] in tests for determinism.
  static int seedForToday({DateTime? now}) {
    return seedForDate(now ?? DateTime.now());
  }

  /// Canonical `YYYY-MM-DD` key for persistence (e.g. streak bookkeeping).
  static String dateKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  /// Whether [b] is exactly one calendar day after [a] (streak continuation).
  static bool isConsecutiveDay(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays == 1;
  }
}
