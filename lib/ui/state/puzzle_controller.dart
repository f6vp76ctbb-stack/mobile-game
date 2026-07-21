/// Riverpod controller for a single puzzle level: placement, win/fail, stars,
/// coin reward, restart and the one-shot "extra move" undo.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/board.dart';
import '../../game/piece.dart';
import '../../game/puzzle.dart';
import '../../services/storage.dart';
import 'game_controller.dart';

@immutable
class PuzzleState {
  const PuzzleState({
    required this.level,
    required this.board,
    required this.pieces,
    required this.pieceIndex,
    required this.moves,
    required this.minMoves,
    required this.solved,
    required this.failed,
    required this.stars,
    required this.coinsAwarded,
    required this.extraMoveUsed,
  });

  final int level;
  final Board board;
  final List<Piece> pieces;
  final int pieceIndex;
  final int moves;
  final int minMoves;
  final bool solved;
  final bool failed;
  final int stars;
  final int coinsAwarded;
  final bool extraMoveUsed;

  Piece? get currentPiece =>
      pieceIndex < pieces.length ? pieces[pieceIndex] : null;

  bool get canExtraMove => failed && !extraMoveUsed;
}

typedef _Snapshot = ({Board board, int index, int moves});

final puzzleControllerProvider =
    StateNotifierProvider<PuzzleController, PuzzleState>((ref) {
  return PuzzleController(ref, ref.read(storageProvider));
});

class PuzzleController extends StateNotifier<PuzzleState> {
  PuzzleController(this._ref, this._storage) : super(_load(0));

  final Ref _ref;
  final Storage _storage;
  final List<_Snapshot> _history = [];

  static PuzzleState _load(int level) {
    final puzzle = PuzzleGenerator.generate(level);
    return PuzzleState(
      level: level,
      board: puzzle.start,
      pieces: puzzle.pieces,
      pieceIndex: 0,
      moves: 0,
      minMoves: puzzle.minMoves,
      solved: false,
      failed: false,
      stars: 0,
      coinsAwarded: 0,
      extraMoveUsed: false,
    );
  }

  void loadLevel(int level) {
    _history.clear();
    state = _load(level);
  }

  void restart() {
    _history.clear();
    state = _load(state.level);
  }

  bool canPlace(Cell origin) {
    final piece = state.currentPiece;
    if (piece == null || state.solved || state.failed) return false;
    return state.board.canPlace(piece, origin);
  }

  Future<void> place(Cell origin) async {
    final piece = state.currentPiece;
    if (piece == null ||
        state.solved ||
        state.failed ||
        !state.board.canPlace(piece, origin)) {
      return;
    }

    _history.add((board: state.board, index: state.pieceIndex, moves: state.moves));
    final result = state.board.place(piece, origin);
    final board = result.board;
    final index = state.pieceIndex + 1;
    final moves = state.moves + 1;
    final solved = board.isEmpty;

    // The level is failed the moment it can no longer be emptied with the
    // remaining pieces (detected by the solver, not just "no placement fits").
    // The solver is bounded; if it runs out of budget we don't declare a
    // failure (better to let the player keep trying than to false-positive).
    final remaining = state.pieces.sublist(index);
    final solveResult = solved
        ? const PuzzleSolveResult(moves: 0, budgetExceeded: false)
        : PuzzleSolver.solve(board, remaining, budget: 60000);
    final failed = !solved &&
        !solveResult.budgetExceeded &&
        solveResult.moves == null;

    var stars = 0;
    var coins = 0;
    if (solved) {
      stars = PuzzleRules.stars(moves: moves, minMoves: state.minMoves);
      coins = await _recordWin(state.level, stars);
    }

    state = PuzzleState(
      level: state.level,
      board: board,
      pieces: state.pieces,
      pieceIndex: index,
      moves: moves,
      minMoves: state.minMoves,
      solved: solved,
      failed: failed,
      stars: stars,
      coinsAwarded: coins,
      extraMoveUsed: state.extraMoveUsed,
    );
  }

  /// Undoes the last placement (used by the rewarded "extra move"). Once/level.
  void applyExtraMove() {
    if (!state.canExtraMove || _history.isEmpty) return;
    final prev = _history.removeLast();
    state = PuzzleState(
      level: state.level,
      board: prev.board,
      pieces: state.pieces,
      pieceIndex: prev.index,
      moves: prev.moves,
      minMoves: state.minMoves,
      solved: false,
      failed: false,
      stars: 0,
      coinsAwarded: 0,
      extraMoveUsed: true,
    );
  }

  /// Persists best stars and grants coins only on the first solve of a level.
  Future<int> _recordWin(int level, int stars) async {
    final all = _storage.puzzleStars;
    final firstSolve = !all.containsKey(level);
    final best = all[level] ?? 0;
    if (stars > best) {
      all[level] = stars;
      await _storage.setPuzzleStars(all);
    }
    if (firstSolve) {
      final coins = PuzzleRules.coinReward(level);
      await _ref.read(gameControllerProvider.notifier).grantCoins(coins);
      return coins;
    }
    return 0;
  }
}
