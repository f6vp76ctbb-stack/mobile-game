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
      expect(after, Mask.zero); // row cleared -> empty
    });

    test('a completed column spanning both 32-bit halves clears fully', () {
      // Column 0 filled for rows 0-6 (row 3 is the lo/hi split boundary);
      // completing row 7's cell empties the whole column across both halves.
      final b = Board.fromAscii(const [
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '........',
      ]);
      final board = BitBoard.fromBoard(b);
      final dotMask = BitBoard.pieceMaskAt(byId('dot'), 7, 0);
      final after = BitBoard.applyPlacement(board, dotMask);
      expect(after, Mask.zero);
    });

    test('a row entirely in the high half (rows 4-7) clears correctly', () {
      final b = Board.fromAscii(const [
        '........',
        '........',
        '........',
        '........',
        '#######.',
        '........',
        '........',
        '........',
      ]);
      final board = BitBoard.fromBoard(b);
      final dotMask = BitBoard.pieceMaskAt(byId('dot'), 4, 7);
      final after = BitBoard.applyPlacement(board, dotMask);
      expect(after, Mask.zero);
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

  // Replays a puzzle's recorded solution and returns whether it empties.
  bool solutionEmpties(Puzzle p) {
    var board = p.start;
    for (var i = 0; i < p.pieces.length; i++) {
      if (!board.canPlace(p.pieces[i], p.solution[i])) return false;
      board = board.place(p.pieces[i], p.solution[i]).board;
    }
    return board.isEmpty;
  }

  group('generator', () {
    test('levels 0..49 are solvable (via recorded solution) and non-trivial',
        () {
      for (var level = 0; level < 50; level++) {
        final p = PuzzleGenerator.generate(level);
        expect(p.pieces, isNotEmpty, reason: 'level $level has no pieces');
        expect(p.solution.length, p.pieces.length,
            reason: 'level $level solution mismatch');
        expect(p.start.filledCount, greaterThan(0),
            reason: 'level $level board is empty');
        expect(solutionEmpties(p), isTrue,
            reason: 'level $level solution does not empty the board');
        // minMoves is exactly one move per piece.
        expect(p.minMoves, p.pieces.length);
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
      for (final level in [3, 10, 25, 49]) {
        final p = PuzzleGenerator.generate(level);
        expect(solutionEmpties(p), isTrue, reason: 'level $level');
      }
    });

    test('harder levels need more moves than the first ones', () {
      // Later levels carry more pieces (more holes / bands).
      expect(
        PuzzleGenerator.generate(20).pieces.length,
        greaterThan(PuzzleGenerator.generate(0).pieces.length),
      );
    });
  });
}
