/// Pure-Dart piggy bank logic (MASTERPLAN.md C.5). No Flutter imports.
///
/// Fills with +1 coin per cleared line during play (separate from the normal
/// coin balance). Emptying it is a consumable IAP. Capacity grows each time it
/// is opened, up to a cap.
library;

class PiggyBank {
  const PiggyBank({required this.coins, required this.capacity});

  static const int coinsPerLine = 1;
  static const int baseCapacity = 500;
  static const int capacityStep = 500;
  static const int maxCapacity = 3000;

  /// Fill level warranting the "nearly full" hint (never nags earlier).
  static const double hintThreshold = 0.8;

  final int coins;
  final int capacity;

  factory PiggyBank.initial() =>
      const PiggyBank(coins: 0, capacity: baseCapacity);

  double get fillFraction => capacity == 0 ? 0 : (coins / capacity).clamp(0, 1);
  bool get showHint => fillFraction >= hintThreshold;
  bool get isEmpty => coins == 0;

  /// Adds [lines] worth of coins, capped at [capacity].
  PiggyBank addLines(int lines) {
    if (lines <= 0) return this;
    final next = (coins + lines * coinsPerLine).clamp(0, capacity);
    return PiggyBank(coins: next, capacity: capacity);
  }

  /// Empties the bank and raises capacity by one step (up to the max). Returns
  /// the emptied bank; the payout is [coins].
  PiggyBank opened() {
    final nextCapacity =
        (capacity + capacityStep).clamp(baseCapacity, maxCapacity);
    return PiggyBank(coins: 0, capacity: nextCapacity);
  }
}
