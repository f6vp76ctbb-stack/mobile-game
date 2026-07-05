import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  group('Board basics', () {
    test('empty board has no filled cells', () {
      final b = Board.empty();
      expect(b.isEmpty, isTrue);
      expect(b.filledCount, 0);
    });

    test('fromAscii / toAscii round-trips', () {
      final rows = [
        '#.......',
        '.#......',
        '..#.....',
        '...#....',
        '....#...',
        '.....#..',
        '......#.',
        '.......#',
      ];
      final b = Board.fromAscii(rows);
      expect(b.toAscii(), rows);
      expect(b.filledCount, 8);
    });
  });

  group('canPlace', () {
    test('rejects out-of-bounds', () {
      final b = Board.empty();
      final line5 = buildCatalog().firstWhere((p) => p.id == 'line5_h');
      expect(b.canPlace(line5, const Cell(0, 4)), isFalse); // needs cols 4..8
      expect(b.canPlace(line5, const Cell(0, 3)), isTrue); // cols 3..7
    });

    test('rejects overlap with filled cells', () {
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
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      expect(b.canPlace(dot, const Cell(0, 0)), isFalse);
      expect(b.canPlace(dot, const Cell(0, 1)), isTrue);
    });
  });

  group('place and clear', () {
    test('placing without a full line clears nothing', () {
      final b = Board.empty();
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      final r = b.place(dot, const Cell(3, 3));
      expect(r.clearedLines, 0);
      expect(r.board.filledAt(3, 3), isTrue);
      expect(r.board.filledCount, 1);
    });

    test('completing a row clears it', () {
      // Row 0 filled except the last cell; drop a dot to complete it.
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
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      final r = b.place(dot, const Cell(0, 7));
      expect(r.clearedRows, 1);
      expect(r.clearedCols, 0);
      expect(r.board.isEmpty, isTrue);
      expect(r.clearedCells.length, 8);
    });

    test('row and column clearing at once counts both', () {
      // Column 0 and row 7 both one cell short; the corner completes both.
      final b = Board.fromAscii(const [
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '#.......',
        '.#######',
      ]);
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      final r = b.place(dot, const Cell(7, 0));
      expect(r.clearedRows, 1);
      expect(r.clearedCols, 1);
      expect(r.clearedLines, 2);
      // 8 (row) + 8 (col) - 1 shared corner = 15 cells cleared.
      expect(r.clearedCells.length, 15);
    });

    test('all-clear is detected', () {
      final b = Board.fromAscii(const [
        '.#######',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
      ]);
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      final r = b.place(dot, const Cell(0, 0));
      expect(r.isAllClear, isTrue);
    });
  });

  group('hasAnyPlacement', () {
    test('true on empty board for every catalog piece', () {
      final b = Board.empty();
      for (final p in buildCatalog()) {
        expect(b.hasAnyPlacement(p), isTrue, reason: p.id);
      }
    });

    test('false when the board is completely full', () {
      final b = Board.fromAscii(List.filled(8, '########'));
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      expect(b.hasAnyPlacement(dot), isFalse);
    });

    test('finds the single remaining gap', () {
      final rows = List.filled(8, '########').toList();
      rows[4] = '####.###'; // one gap at (4,4)
      final b = Board.fromAscii(rows);
      final dot = buildCatalog().firstWhere((p) => p.id == 'dot');
      final line2 = buildCatalog().firstWhere((p) => p.id == 'line2_h');
      expect(b.hasAnyPlacement(dot), isTrue);
      expect(b.hasAnyPlacement(line2), isFalse); // no room for two cells
    });
  });
}
