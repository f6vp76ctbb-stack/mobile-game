/// Pure-Dart game session for GridPop — ties board, generator and scorer into
/// one playable run. No Flutter imports, fully unit-testable.
library;

import 'board.dart';
import 'generator.dart';
import 'piece.dart';
import 'scoring.dart';

class GameSession {
  GameSession._(
    this.seed,
    this._generator,
    this._scorer,
    this._board,
    this._clock,
    this.freeRotation,
  );

  /// Starts a fresh run for the given [seed] (date seed for the Daily
  /// Challenge, or a random seed for endless).
  ///
  /// [clock] feeds the combo window (injectable for tests). With
  /// [freeRotation] tray pieces rotate without consuming charges (used while
  /// the player is still learning the game).
  factory GameSession.newGame({
    required int seed,
    DateTime Function()? clock,
    bool freeRotation = false,
  }) {
    final s = GameSession._(
      seed,
      PieceGenerator(seed: seed),
      ScoreKeeper(),
      Board.empty(),
      clock ?? DateTime.now,
      freeRotation,
    );
    s._tray = List<Piece?>.of(s._generator.nextTray(s._board, s._placements));
    s._recomputeGameOver();
    return s;
  }

  /// Test-only seam: builds a session with an explicit [board], [tray] and
  /// rotation state, so game-over / rotation scenarios can be set up directly
  /// (the seed-driven [newGame] can't reach arbitrary board states).
  factory GameSession.forTest({
    required Board board,
    required List<Piece?> tray,
    bool freeRotation = false,
    int rotationCharges = startRotationCharges,
    DateTime Function()? clock,
  }) {
    final s = GameSession._(
      0,
      PieceGenerator(seed: 0),
      ScoreKeeper(),
      board,
      clock ?? DateTime.now,
      freeRotation,
    );
    s._tray = List<Piece?>.of(tray);
    s._rotationCharges = rotationCharges;
    s._recomputeGameOver();
    return s;
  }

  /// Maximum stored rotation charges; every clearing move refills one.
  static const int maxRotationCharges = 3;

  /// Charges a fresh run starts with.
  static const int startRotationCharges = 2;

  final int seed;
  final PieceGenerator _generator;
  final ScoreKeeper _scorer;
  final DateTime Function() _clock;

  /// True while rotation is free (beginner mode) — charges are not consumed.
  final bool freeRotation;

  Board _board;
  late List<Piece?> _tray; // 3 slots; null once placed
  int _placements = 0;
  int _rotationCharges = startRotationCharges;
  int _linesCleared = 0;
  int _maxCombo = 0;
  bool _gameOver = false;
  List<Cell> _lastClearedCells = const [];
  int _lastClearedLineCount = 0;
  bool _lastWasAllClear = false;
  _SessionMemento? _undoMemento; // pre-move state; null = nothing to undo

  /// Cells removed by the most recent placement (for clear animations).
  List<Cell> get lastClearedCells => _lastClearedCells;

  /// Lines cleared by the most recent placement (for screen-shake threshold).
  int get lastClearedLineCount => _lastClearedLineCount;

  /// Whether the most recent placement emptied the whole board.
  bool get lastWasAllClear => _lastWasAllClear;

  /// Whether the last placement can be undone (one step, not across boosters).
  bool get canUndo => _undoMemento != null;

  _SessionMemento _snapshot() => _SessionMemento(
        board: _board,
        tray: List<Piece?>.of(_tray),
        placements: _placements,
        linesCleared: _linesCleared,
        maxCombo: _maxCombo,
        score: _scorer.save(),
        lastClearedCells: _lastClearedCells,
        rotationCharges: _rotationCharges,
      );

  Board get board => _board;
  List<Piece?> get tray => List.unmodifiable(_tray);
  int get score => _scorer.total;
  int get combo => _scorer.combo;
  double get feverLevel => _scorer.feverLevel;
  int get placements => _placements;
  bool get isGameOver => _gameOver;

  /// When the running combo expires (UI countdown), or null without a combo.
  DateTime? get comboExpiresAt => _scorer.comboExpiresAt;

  /// Remaining rotation charges (meaningless while [freeRotation] is true).
  int get rotationCharges => _rotationCharges;

  /// Whether the piece in [slot] can currently be rotated.
  bool canRotate(int slot) {
    if (_gameOver || _tray[slot] == null) return false;
    return freeRotation || _rotationCharges > 0;
  }

  /// Rotates the piece in [slot] 90° clockwise, consuming one charge (unless
  /// [freeRotation]). Rotation can rescue a stuck board, so the game-over
  /// state is recomputed. Returns whether it ran.
  bool rotate(int slot) {
    if (!canRotate(slot)) return false;
    _tray[slot] = _tray[slot]!.rotatedCw();
    if (!freeRotation) _rotationCharges -= 1;
    _recomputeGameOver();
    return true;
  }

  /// Per-run statistics (basis for missions and analytics).
  int get linesCleared => _linesCleared;
  int get maxCombo => _maxCombo;

  /// A snapshot of the current run's stats.
  GameStats get stats => GameStats(
        score: score,
        piecesPlaced: _placements,
        linesCleared: _linesCleared,
        maxCombo: _maxCombo,
      );

  /// Whether the piece in [slot] can legally be placed at [origin].
  bool canPlace(int slot, Cell origin) {
    final piece = _tray[slot];
    if (piece == null || _gameOver) return false;
    return _board.canPlace(piece, origin);
  }

  /// Places the piece in [slot] at [origin]. Returns the resulting
  /// [ScoreEvent], or null if the move was illegal.
  ScoreEvent? place(int slot, Cell origin) {
    final piece = _tray[slot];
    if (piece == null || _gameOver || !_board.canPlace(piece, origin)) {
      return null;
    }

    _undoMemento = _snapshot();

    final result = _board.place(piece, origin);
    _board = result.board;
    _tray[slot] = null;
    _placements += 1;

    final event = _scorer.applyPlacement(
      placedCells: result.placedCells,
      clearedLines: result.clearedLines,
      clearedCells: result.clearedCells.length,
      isAllClear: result.isAllClear,
      now: _clock(),
    );
    if (result.clearedLines > 0 && _rotationCharges < maxRotationCharges) {
      _rotationCharges += 1; // clears recharge the rotate booster
    }
    _linesCleared += result.clearedLines;
    _lastClearedCells = result.clearedCells.toList(growable: false);
    _lastClearedLineCount = result.clearedLines;
    _lastWasAllClear = result.isAllClear;
    if (event.combo > _maxCombo) _maxCombo = event.combo;

    if (_tray.every((p) => p == null)) {
      _tray = List<Piece?>.of(_generator.nextTray(_board, _placements));
    }
    _recomputeGameOver();
    return event;
  }

  /// Undoes the last placement (board, tray, score, combo, fever, stats).
  /// Only one step, and not across a booster/revive. Returns whether it ran.
  bool undo() {
    final m = _undoMemento;
    if (m == null) return false;
    _board = m.board;
    _tray = List<Piece?>.of(m.tray);
    _placements = m.placements;
    _linesCleared = m.linesCleared;
    _maxCombo = m.maxCombo;
    _scorer.restore(m.score);
    _lastClearedCells = m.lastClearedCells;
    _rotationCharges = m.rotationCharges;
    _undoMemento = null;
    _recomputeGameOver();
    return true;
  }

  /// Board Bomb booster: clears the 3x3 block centred on [origin]. Gives no
  /// points and does not touch the combo. Cannot be undone. Returns the
  /// in-bounds cells the bomb hit (for the UI's particle burst).
  List<Cell> bombAt(Cell origin) {
    final hit = <Cell>[];
    final rows = _board.toAscii().map((r) => r.split('')).toList();
    for (var r = origin.row - 1; r <= origin.row + 1; r++) {
      for (var c = origin.col - 1; c <= origin.col + 1; c++) {
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          rows[r][c] = '.';
          hit.add(Cell(r, c));
        }
      }
    }
    _board = Board.fromAscii(rows.map((r) => r.join()).toList());
    _undoMemento = null;
    _recomputeGameOver();
    return hit;
  }

  /// Draws a fresh tray (used by "Lucky Block" and the swap booster) and
  /// rechecks the game-over state. Cannot be undone.
  void rerollTray() {
    _tray = List<Piece?>.of(_generator.nextTray(_board, _placements));
    _undoMemento = null;
    _recomputeGameOver();
  }

  /// Empties the central 4x4 block (used by the "Revive" reward) and clears
  /// the game-over flag if a move becomes possible again.
  void reviveClearCenter() {
    final rows = _board.toAscii().map((r) => r.split('')).toList();
    for (var r = 2; r < 6; r++) {
      for (var c = 2; c < 6; c++) {
        rows[r][c] = '.';
      }
    }
    _board = Board.fromAscii(rows.map((r) => r.join()).toList());
    _undoMemento = null;
    _recomputeGameOver();
  }

  void _recomputeGameOver() {
    // A tray piece counts as playable if it fits as-is OR — while the player
    // can still rotate (free, or with charges) — if any rotation reachable
    // within the available charges fits. Ignoring rotation here caused false
    // game-overs (e.g. at level 3+, where rotation costs charges): the board
    // was declared dead even though a piece could have been rotated to fit.
    final maxRotations = freeRotation ? 3 : _rotationCharges.clamp(0, 3);
    _gameOver = !_tray
        .whereType<Piece>()
        .any((piece) => _hasPlacementWithin(piece, maxRotations));
  }

  /// Whether [piece] can be placed somewhere either as-is or after up to
  /// [maxRotations] clockwise rotations (each costing one charge in normal
  /// play). Rotating a single piece can use the whole charge budget, so this
  /// checks each piece independently against the full budget.
  bool _hasPlacementWithin(Piece piece, int maxRotations) {
    var p = piece;
    for (var r = 0; r <= maxRotations; r++) {
      if (_board.hasAnyPlacement(p)) return true;
      if (r < maxRotations) p = p.rotatedCw();
    }
    return false;
  }
}

/// Captured pre-move state for one-step undo. [Board] and [ScoreMemento] are
/// immutable; the tray list is copied when the memento is taken.
class _SessionMemento {
  _SessionMemento({
    required this.board,
    required this.tray,
    required this.placements,
    required this.linesCleared,
    required this.maxCombo,
    required this.score,
    required this.lastClearedCells,
    required this.rotationCharges,
  });

  final Board board;
  final List<Piece?> tray;
  final int placements;
  final int linesCleared;
  final int maxCombo;
  final ScoreMemento score;
  final List<Cell> lastClearedCells;
  final int rotationCharges;
}

/// Immutable summary of one run, consumed by missions and analytics.
class GameStats {
  const GameStats({
    required this.score,
    required this.piecesPlaced,
    required this.linesCleared,
    required this.maxCombo,
  });

  final int score;
  final int piecesPlaced;
  final int linesCleared;
  final int maxCombo;
}
