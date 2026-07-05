/// Pure-Dart scoring for GridPop. No Flutter imports.
///
/// Rules (MASTERPLAN.md §4 "Scoring" + Anhang A):
///  - Placement: +1 point per occupied cell.
///  - Clear: 10 points per cleared cell, multiplied by the number of lines
///    cleared in that move (capped at x4).
///  - Combo: consecutive moves that clear at least one line build a combo
///    multiplier (1.0, 1.5, 2.0, ...). A move without a clear breaks it.
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
    this.feverPerLine = 0.2,
    this.feverDecayNoClear = 0.1,
    this.allClearBonus = 300,
  });

  final int pointsPerPlacedCell;
  final int pointsPerClearedCell;
  final int maxLineMultiplier;
  final double comboStep;
  final double feverPerLine;
  final double feverDecayNoClear;
  final int allClearBonus;

  int _total = 0;
  int _combo = 0;
  double _fever = 0;

  int get total => _total;
  int get combo => _combo;
  double get feverLevel => _fever;

  void reset() {
    _total = 0;
    _combo = 0;
    _fever = 0;
  }

  /// Applies a placement outcome and returns the resulting [ScoreEvent].
  ScoreEvent applyPlacement({
    required int placedCells,
    required int clearedLines,
    required int clearedCells,
    required bool isAllClear,
  }) {
    var gained = placedCells * pointsPerPlacedCell;
    var burst = false;

    if (clearedLines > 0) {
      _combo += 1;
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
      _combo = 0;
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
