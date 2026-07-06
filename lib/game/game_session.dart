/// Pure-Dart game session for GridPop — ties board, generator and scorer into
/// one playable run. No Flutter imports, fully unit-testable.
library;

import 'board.dart';
import 'generator.dart';
import 'piece.dart';
import 'scoring.dart';

class GameSession {
  GameSession._(this.seed, this._generator, this._scorer, this._board) {
    _tray = List<Piece?>.of(_generator.nextTray(_board, _placements));
    _recomputeGameOver();
  }

  /// Starts a fresh run for the given [seed] (date seed for the Daily
  /// Challenge, or a random seed for endless).
  factory GameSession.newGame({required int seed}) {
    return GameSession._(
      seed,
      PieceGenerator(seed: seed),
      ScoreKeeper(),
      Board.empty(),
    );
  }

  final int seed;
  final PieceGenerator _generator;
  final ScoreKeeper _scorer;

  Board _board;
  late List<Piece?> _tray; // 3 slots; null once placed
  int _placements = 0;
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
      );

  Board get board => _board;
  List<Piece?> get tray => List.unmodifiable(_tray);
  int get score => _scorer.total;
  int get combo => _scorer.combo;
  double get feverLevel => _scorer.feverLevel;
  int get placements => _placements;
  bool get isGameOver => _gameOver;

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
    );
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
    _undoMemento = null;
    _recomputeGameOver();
    return true;
  }

  /// Board Bomb booster: clears the 3x3 block centred on [origin]. Gives no
  /// points and does not touch the combo. Cannot be undone.
  void bombAt(Cell origin) {
    final rows = _board.toAscii().map((r) => r.split('')).toList();
    for (var r = origin.row - 1; r <= origin.row + 1; r++) {
      for (var c = origin.col - 1; c <= origin.col + 1; c++) {
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          rows[r][c] = '.';
        }
      }
    }
    _board = Board.fromAscii(rows.map((r) => r.join()).toList());
    _undoMemento = null;
    _recomputeGameOver();
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
    _gameOver = !_tray
        .whereType<Piece>()
        .any((piece) => _board.hasAnyPlacement(piece));
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
  });

  final Board board;
  final List<Piece?> tray;
  final int placements;
  final int linesCleared;
  final int maxCombo;
  final ScoreMemento score;
  final List<Cell> lastClearedCells;
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
