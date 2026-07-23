import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/generator.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  group('determinism', () {
    test('same seed yields identical tray sequences', () {
      final board = Board.empty();
      final a = PieceGenerator(seed: 42);
      final b = PieceGenerator(seed: 42);
      for (var i = 0; i < 20; i++) {
        final ta = a.nextTray(board, i);
        final tb = b.nextTray(board, i);
        expect(ta.map((p) => p.id).toList(), tb.map((p) => p.id).toList());
      }
    });

    test('different seeds diverge', () {
      final board = Board.empty();
      final a = PieceGenerator(seed: 1);
      final b = PieceGenerator(seed: 2);
      final seqA = [
        for (var i = 0; i < 10; i++) ...a.nextTray(board, i).map((p) => p.id),
      ];
      final seqB = [
        for (var i = 0; i < 10; i++) ...b.nextTray(board, i).map((p) => p.id),
      ];
      expect(seqA, isNot(equals(seqB)));
    });
  });

  group('tray shape', () {
    test('always returns exactly 3 pieces from the catalog', () {
      final gen = PieceGenerator(seed: 7);
      final board = Board.empty();
      final ids = buildCatalog().map((p) => p.id).toSet();
      for (var i = 0; i < 30; i++) {
        final tray = gen.nextTray(board, i);
        expect(tray.length, 3);
        for (final p in tray) {
          expect(ids.contains(p.id), isTrue);
        }
      }
    });
  });

  group('rescue rule', () {
    test('guarantees a placeable piece when the board is nearly full', () {
      // Fill everything except a single 1x1 gap at (4,4): only a dot fits.
      final rows = List.filled(8, '########').toList();
      rows[4] = '####.###';
      final board = Board.fromAscii(rows);

      // Try many seeds; every tray must contain at least one placeable piece
      // (the rescue slot), so the game never dead-ends unfairly.
      for (var seed = 0; seed < 50; seed++) {
        final gen = PieceGenerator(seed: seed);
        final tray = gen.nextTray(board, 100); // late phase, no bonus
        expect(
          tray.any(board.hasAnyPlacement),
          isTrue,
          reason: 'seed $seed produced an all-unplaceable tray',
        );
      }
    });

    test('does not force a piece when the board is truly full', () {
      final board = Board.fromAscii(List.filled(8, '########'));
      final gen = PieceGenerator(seed: 3);
      final tray = gen.nextTray(board, 100);
      expect(tray.length, 3);
      expect(tray.any(board.hasAnyPlacement), isFalse); // legit game over
    });
  });

  group('early-phase weighting', () {
    test('does not crash and stays deterministic across move indices', () {
      final board = Board.empty();
      final gen = PieceGenerator(seed: 99);
      // moves 0..9 are early phase, 10+ normal — both must produce valid trays.
      for (var i = 0; i < 15; i++) {
        expect(gen.nextTray(board, i).length, 3);
      }
    });

    test('can extend the fairness weighting through the first 20 moves', () {
      final rows = List.filled(8, '########').toList();
      rows[4] = '####.###';
      final board = Board.fromAscii(rows);
      final catalog = [
        Piece('dot', const [Cell(0, 0)], 1),
        Piece('domino', const [Cell(0, 0), Cell(0, 1)], 1),
      ];
      var extendedPlaceablePieces = 0;
      var defaultPlaceablePieces = 0;

      for (var seed = 0; seed < 100; seed++) {
        final extended = PieceGenerator(
          seed: seed,
          catalog: catalog,
          earlyPhaseMoves: 20,
        );
        final normal = PieceGenerator(seed: seed, catalog: catalog);
        extendedPlaceablePieces += extended
            .nextTray(board, 15)
            .where(board.hasAnyPlacement)
            .length;
        defaultPlaceablePieces += normal
            .nextTray(board, 15)
            .where(board.hasAnyPlacement)
            .length;
      }

      expect(PieceGenerator.defaultEarlyPhaseMoves, 10);
      expect(extendedPlaceablePieces, greaterThan(defaultPlaceablePieces));
    });
  });
}
