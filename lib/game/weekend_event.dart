/// Pure-Dart weekend coin event (MASTERPLAN.md C.7). No Flutter imports.
///
/// On Saturday and Sunday (device local time), mission and daily rewards are
/// doubled. Offline by design — device time is enough; abusing the clock only
/// grants soft currency, which is acceptable.
library;

class WeekendEvent {
  const WeekendEvent._();

  static const int coinMultiplier = 2;

  static bool isActive(DateTime now) {
    return now.weekday == DateTime.saturday ||
        now.weekday == DateTime.sunday;
  }

  /// Doubles [coins] while the event is active, otherwise returns them as-is.
  static int apply(int coins, DateTime now) =>
      isActive(now) ? coins * coinMultiplier : coins;
}
