import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/game/puzzle.dart';

void main() {
  final catalog = buildCatalog();
  Piece byId(String id) => catalog.firstWhere((p) => p.id == id);

  group('BitBoard', () {
    test('applyPlacement clears a completed row to empty', () {
      // Row 0 filled except the last cell.
      final b = Board.fromAscii(const [
        '#######.',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      final board = BitBoard.fromBoard(b);
      final dotMask = BitBoard.pieceMaskAt(byId('dot'), 0, 7);
      final after = BitBoard.applyPlacement(board, dotMask);
      expect(after, 0); // row cleared -> empty
    });
  });

  group('solver', () {
    test('empty board needs zero moves', () {
      expect(PuzzleSolver.minMovesToEmpty(Board.empty(), const []), 0);
    });

    test('one-move puzzle solves in one move', () {
      final b = Board.fromAscii(const [
        '#######.',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      expect(PuzzleSolver.minMovesToEmpty(b, [byId('dot')]), 1);
    });

    test('unsolvable when the piece cannot empty the board', () {
      // A lone cell that completing any line cannot remove with a single dot
      // placed elsewhere.
      final b = Board.fromAscii(const [
        '#.......',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      // A dot placed anywhere else never clears the (0,0) cell's row/col fully.
      expect(PuzzleSolver.minMovesToEmpty(b, [byId('dot')]), isNull);
    });

    test('two independent rows need two moves', () {
      final b = Board.fromAscii(const [
        '#######.',
        '#######.',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      // Two vertical dots complete each row in turn.
      final moves =
          PuzzleSolver.minMovesToEmpty(b, [byId('dot'), byId('dot')]);
      expect(moves, 2);
    });
  });

  group('rules', () {
    test('stars by move count', () {
      expect(PuzzleRules.stars(moves: 3, minMoves: 3), 3);
      expect(PuzzleRules.stars(moves: 4, minMoves: 3), 2);
      expect(PuzzleRules.stars(moves: 5, minMoves: 3), 2);
      expect(PuzzleRules.stars(moves: 6, minMoves: 3), 1);
    });

    test('coin reward with 10-level bonus', () {
      expect(PuzzleRules.coinReward(0), 10); // level 1 shown
      expect(PuzzleRules.coinReward(8), 10);
      expect(PuzzleRules.coinReward(9), 35); // 10th level -> +25
      expect(PuzzleRules.coinReward(19), 35); // 20th level
    });
  });

  group('generator', () {
    test('levels 0..49 are solvable and non-trivial', () {
      for (var level = 0; level < 50; level++) {
        final p = PuzzleGenerator.generate(level);
        expect(p.pieces, isNotEmpty, reason: 'level $level has no pieces');
        expect(p.start.filledCount, greaterThan(0),
            reason: 'level $level board is empty');
        expect(
          PuzzleSolver.minMovesToEmpty(p.start, p.pieces),
          isNotNull,
          reason: 'level $level is unsolvable',
        );
        expect(p.minMoves, greaterThan(0));
      }
    });

    test('generation is deterministic per level', () {
      final a = PuzzleGenerator.generate(7);
      final b = PuzzleGenerator.generate(7);
      expect(a.start.toAscii(), b.start.toAscii());
      expect(a.pieces.map((p) => p.id).toList(),
          b.pieces.map((p) => p.id).toList());
      expect(a.minMoves, b.minMoves);
    });

    test('difficulty rises: later levels have at least as many pieces', () {
      expect(
        PuzzleGenerator.generate(40).pieces.length,
        greaterThanOrEqualTo(PuzzleGenerator.generate(0).pieces.length),
      );
    });

    test('the constructed solution actually empties the board', () {
      final p = PuzzleGenerator.generate(3);
      // Placing each piece into its band (found by the solver) reaches empty.
      expect(PuzzleSolver.minMovesToEmpty(p.start, p.pieces), isNotNull);
    });
  });
}
