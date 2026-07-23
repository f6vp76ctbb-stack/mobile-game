/// Pure-Dart decision logic for one-time, contextual in-game hints.
///
/// The controller owns persistence and presentation. Keeping the decision
/// here makes the order and trigger rules deterministic and unit-testable.
library;

enum CoachHintType { combo, fever, rotation, booster }

class CoachHintSignals {
  const CoachHintSignals({
    this.comboActive = false,
    this.feverActive = false,
    this.rotationUsed = false,
    this.boosterAffordable = false,
  });

  final bool comboActive;
  final bool feverActive;
  final bool rotationUsed;
  final bool boosterAffordable;
}

class CoachHints {
  const CoachHints._();

  /// Returns the highest-priority unseen hint whose trigger is active.
  ///
  /// Combo and fever are time-sensitive, so they take precedence over the
  /// persistent booster-affordability signal.
  static CoachHintType? next({
    required CoachHintSignals signals,
    required Set<CoachHintType> seen,
  }) {
    final candidates = <(CoachHintType, bool)>[
      (CoachHintType.combo, signals.comboActive),
      (CoachHintType.fever, signals.feverActive),
      (CoachHintType.rotation, signals.rotationUsed),
      (CoachHintType.booster, signals.boosterAffordable),
    ];
    for (final (hint, active) in candidates) {
      if (active && !seen.contains(hint)) return hint;
    }
    return null;
  }

  static String text(CoachHintType hint) => switch (hint) {
    CoachHintType.combo =>
      'Combo! Räume innerhalb von 10 s weiter, sonst läuft sie ab ⏱',
    CoachHintType.fever => 'FIEBER! Doppelte Punkte, solange es glüht 🔥',
    CoachHintType.rotation =>
      'Drehen kostet eine Ladung – Clears füllen sie wieder auf',
    CoachHintType.booster => 'Tipp: Unten kannst du Booster einsetzen 🪙',
  };
}
