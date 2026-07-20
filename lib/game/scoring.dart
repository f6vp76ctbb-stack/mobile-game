/// Pure-Dart scoring for GridPop. No Flutter imports.
///
/// Rules (MASTERPLAN.md §4 "Scoring" + Anhang A):
///  - Placement: +1 point per occupied cell.
///  - Clear: 10 points per cleared cell, multiplied by the number of lines
///    cleared in that move (capped at x4).
///  - Combo: clears within [comboWindow] of the previous clear build a combo
///    multiplier (1.0, 1.5, 2.0, ...). The combo survives non-clearing moves
///    but expires when the window runs out (the UI shows the countdown).
///  - Fever meter: each cleared line fills the meter; when it fills up, that
///    move's clear points are doubled ("fever burst") and the meter resets.
///  - All Clear: +300 bonus.
library;

/// Outcome of scoring a single placement.
class ScoreEvent {
  const ScoreEvent({
    required this.gained,
    required this.total,
    required this.combo,
    required this.feverLevel,
    required this.feverBurst,
  });

  /// Points added by this move.
  final int gained;

  /// Running total after this move.
  final int total;

  /// Combo count after this move (0 when no active streak).
  final int combo;

  /// Fever meter in the range 0.0 .. 1.0 after this move.
  final double feverLevel;

  /// True if this move triggered a fever burst (doubled clear points).
  final bool feverBurst;
}

/// Mutable scorer that carries combo and fever state across a run.
class ScoreKeeper {
  ScoreKeeper({
    this.pointsPerPlacedCell = 1,
    this.pointsPerClearedCell = 10,
    this.maxLineMultiplier = 4,
    this.comboStep = 0.5,
    this.comboWindow = const Duration(seconds: 10),
    this.feverPerLine = 0.2,
    this.feverDecayNoClear = 0.1,
    this.allClearBonus = 300,
  });

  final int pointsPerPlacedCell;
  final int pointsPerClearedCell;
  final int maxLineMultiplier;
  final double comboStep;

  /// How long a combo stays alive after its most recent clear. A clear inside
  /// the window extends the combo; outside it, the streak restarts at 1.
  final Duration comboWindow;

  final double feverPerLine;
  final double feverDecayNoClear;
  final int allClearBonus;

  int _total = 0;
  int _combo = 0;
  double _fever = 0;
  DateTime? _lastClearAt;

  int get total => _total;
  int get combo => _combo;
  double get feverLevel => _fever;

  /// When the current combo expires, or null while no combo is running (or no
  /// clock was passed to [applyPlacement]).
  DateTime? get comboExpiresAt =>
      _combo > 0 && _lastClearAt != null ? _lastClearAt!.add(comboWindow) : null;

  void reset() {
    _total = 0;
    _combo = 0;
    _fever = 0;
    _lastClearAt = null;
  }

  /// Captures the current scoring state (for one-step undo).
  ScoreMemento save() => ScoreMemento(_total, _combo, _fever, _lastClearAt);

  /// Restores a previously [save]d state.
  void restore(ScoreMemento m) {
    _total = m.total;
    _combo = m.combo;
    _fever = m.fever;
    _lastClearAt = m.lastClearAt;
  }

  /// Applies a placement outcome and returns the resulting [ScoreEvent].
  ///
  /// [now] drives the combo window; when omitted the combo never expires
  /// (useful for tests that don't care about timing).
  ScoreEvent applyPlacement({
    required int placedCells,
    required int clearedLines,
    required int clearedCells,
    required bool isAllClear,
    DateTime? now,
  }) {
    var gained = placedCells * pointsPerPlacedCell;
    var burst = false;

    if (clearedLines > 0) {
      final last = _lastClearAt;
      final expired = now != null &&
          last != null &&
          now.difference(last) > comboWindow;
      _combo = (_combo == 0 || expired) ? 1 : _combo + 1;
      if (now != null) _lastClearAt = now;

      final lineMultiplier =
          clearedLines > maxLineMultiplier ? maxLineMultiplier : clearedLines;
      final comboMultiplier = 1.0 + (_combo - 1) * comboStep;

      _fever += clearedLines * feverPerLine;
      if (_fever >= 1.0) {
        burst = true;
        _fever = 0;
      }

      var clearPoints =
          clearedCells * pointsPerClearedCell * lineMultiplier * comboMultiplier;
      if (burst) clearPoints *= 2;
      gained += clearPoints.round();

      if (isAllClear) gained += allClearBonus;
    } else {
      // A non-clearing move no longer kills the combo — only the clock does.
      // It still cools the fever meter, and an expired combo is dropped so
      // the next clear starts a fresh streak.
      final last = _lastClearAt;
      if (now != null && last != null && now.difference(last) > comboWindow) {
        _combo = 0;
        _lastClearAt = null;
      }
      _fever -= feverDecayNoClear;
      if (_fever < 0) _fever = 0;
    }

    _total += gained;
    return ScoreEvent(
      gained: gained,
      total: _total,
      combo: _combo,
      feverLevel: _fever,
      feverBurst: burst,
    );
  }
}

/// Immutable snapshot of [ScoreKeeper] state for one-step undo.
class ScoreMemento {
  const ScoreMemento(this.total, this.combo, this.fever, [this.lastClearAt]);

  final int total;
  final int combo;
  final double fever;
  final DateTime? lastClearAt;
}
