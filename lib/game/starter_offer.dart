/// Pure-Dart starter-pack offer logic (MASTERPLAN.md C.6). No Flutter imports.
///
/// A one-time offer that appears after the player's 5th run and stays for a
/// real 48-hour window, then is gone for good (no fake countdown reset).
library;

class StarterOffer {
  const StarterOffer._();

  static const int triggerAfterGames = 5;
  static const Duration window = Duration(hours: 48);
  static const int coins = 1200;
  static const String themeId = 'wood';

  /// Whether the offer window should be started now (eligible, not yet started,
  /// not already purchased).
  static bool shouldStart({
    required int gamesPlayed,
    required int? startMillis,
    required bool purchased,
  }) {
    return !purchased &&
        startMillis == null &&
        gamesPlayed >= triggerAfterGames;
  }

  /// Whether the offer is currently visible (started, within the window, not
  /// purchased).
  static bool isActive({
    required int? startMillis,
    required bool purchased,
    required DateTime now,
  }) {
    if (purchased || startMillis == null) return false;
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    return now.difference(start) < window;
  }

  /// Remaining time in the window (zero once expired).
  static Duration remaining({
    required int startMillis,
    required DateTime now,
  }) {
    final start = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final left = window - now.difference(start);
    return left.isNegative ? Duration.zero : left;
  }
}
