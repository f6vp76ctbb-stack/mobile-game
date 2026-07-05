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
  bool _gameOver = false;

  Board get board => _board;
  List<Piece?> get tray => List.unmodifiable(_tray);
  int get score => _scorer.total;
  int get combo => _scorer.combo;
  double get feverLevel => _scorer.feverLevel;
  int get placements => _placements;
  bool get isGameOver => _gameOver;

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

    if (_tray.every((p) => p == null)) {
      _tray = List<Piece?>.of(_generator.nextTray(_board, _placements));
    }
    _recomputeGameOver();
    return event;
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
    _recomputeGameOver();
  }

  void _recomputeGameOver() {
    _gameOver = !_tray
        .whereType<Piece>()
        .any((piece) => _board.hasAnyPlacement(piece));
  }
}
