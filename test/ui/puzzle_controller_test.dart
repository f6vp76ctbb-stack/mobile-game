import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/game/puzzle.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/state/puzzle_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.create();
  final container = ProviderContainer(
    overrides: [storageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Finds a placement for the current piece that stays on a solution path.
Cell? _solvingMove(PuzzleState s) {
  final piece = s.currentPiece;
  if (piece == null) return null;
  for (var r = 0; r < Board.size; r++) {
    for (var c = 0; c < Board.size; c++) {
      final origin = Cell(r, c);
      if (!s.board.canPlace(piece, origin)) continue;
      final result = s.board.place(piece, origin);
      final remaining = s.pieces.sublist(s.pieceIndex + 1);
      if (result.board.isEmpty ||
          PuzzleSolver.minMovesToEmpty(result.board, remaining) != null) {
        return origin;
      }
    }
  }
  return null;
}

Future<void> _solve(PuzzleController c) async {
  var guard = 0;
  while (!c.state.solved && guard < 50) {
    final move = _solvingMove(c.state);
    if (move == null) break;
    await c.place(move);
    guard++;
  }
}

void main() {
  test('solving a level awards stars and coins on first completion', () async {
    final container = await _container({'coins': 0});
    final c = container.read(puzzleControllerProvider.notifier);
    c.loadLevel(0);

    await _solve(c);
    expect(c.state.solved, isTrue);
    expect(c.state.stars, greaterThanOrEqualTo(1));
    expect(c.state.coinsAwarded, PuzzleRules.coinReward(0));
    expect(container.read(storageProvider).puzzleStars[0], c.state.stars);
    expect(container.read(gameControllerProvider).coins,
        PuzzleRules.coinReward(0));
  });

  test('re-solving a level grants no additional coins', () async {
    final container = await _container({'puzzleStars': '{"0":3}', 'coins': 0});
    final c = container.read(puzzleControllerProvider.notifier);
    c.loadLevel(0);
    await _solve(c);
    expect(c.state.solved, isTrue);
    expect(c.state.coinsAwarded, 0); // already solved before
  });

  test('restart resets the board and progress', () async {
    final container = await _container({});
    final c = container.read(puzzleControllerProvider.notifier);
    c.loadLevel(2);
    final startFill = c.state.board.filledCount;
    await c.place(_solvingMove(c.state)!);
    expect(c.state.moves, 1);
    c.restart();
    expect(c.state.moves, 0);
    expect(c.state.pieceIndex, 0);
    expect(c.state.board.filledCount, startFill);
  });

  test('extra move undoes the last placement once', () async {
    final container = await _container({});
    final c = container.read(puzzleControllerProvider.notifier);
    c.loadLevel(1);
    // Deliberately make a losing move: place the current piece somewhere that
    // is legal but off the solution path, if one exists.
    final piece = c.state.currentPiece!;
    Cell? bad;
    for (var r = 0; r < Board.size && bad == null; r++) {
      for (var col = 0; col < Board.size && bad == null; col++) {
        final o = Cell(r, col);
        if (!c.state.board.canPlace(piece, o)) continue;
        final res = c.state.board.place(piece, o);
        final remaining = c.state.pieces.sublist(1);
        if (!res.board.isEmpty &&
            PuzzleSolver.minMovesToEmpty(res.board, remaining) == null) {
          bad = o;
        }
      }
    }
    if (bad != null) {
      await c.place(bad);
      expect(c.state.failed, isTrue);
      c.applyExtraMove();
      expect(c.state.failed, isFalse);
      expect(c.state.moves, 0);
      expect(c.state.extraMoveUsed, isTrue);
    }
  });
}
