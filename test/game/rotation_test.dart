import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  group('Piece.rotatedCw', () {
    test('rotates a horizontal line into a vertical one', () {
      final h = Piece('line3_h', const [Cell(0, 0), Cell(0, 1), Cell(0, 2)], 1);
      final v = h.rotatedCw();
      expect(v.cells, const [Cell(0, 0), Cell(1, 0), Cell(2, 0)]);
      expect(v.width, 1);
      expect(v.height, 3);
      expect(v.id, 'line3_h', reason: 'rotation keeps the catalog id');
    });

    test('rotates an L shape correctly', () {
      // .X      XX      X.
      // .X  ->  ..  ->  X.  (two cw rotations = 180°)
      // XX      ..      XX ... verify one step:
      final l = Piece('l', const [Cell(0, 1), Cell(1, 1), Cell(2, 0), Cell(2, 1)], 1);
      final r = l.rotatedCw();
      // 90° cw: (r,c) -> (c, maxR - r); maxR = 2.
      expect(
        r.cells,
        const [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(1, 2)],
      );
    });

    test('four rotations return to the original shape', () {
      final s = Piece('s_h', const [Cell(0, 1), Cell(0, 2), Cell(1, 0), Cell(1, 1)], 1);
      final back = s.rotatedCw().rotatedCw().rotatedCw().rotatedCw();
      expect(back.cells, s.cells);
    });

    test('a square is rotation-invariant', () {
      final sq = Piece('square2',
          const [Cell(0, 0), Cell(0, 1), Cell(1, 0), Cell(1, 1)], 1);
      expect(sq.rotatedCw().cells, sq.cells);
    });
  });

  group('GameSession rotation charges', () {
    test('starts with the configured charges and consumes one per rotate', () {
      final s = GameSession.newGame(seed: 7);
      expect(s.rotationCharges, GameSession.startRotationCharges);
      expect(s.rotate(0), isTrue);
      expect(s.rotationCharges, GameSession.startRotationCharges - 1);
    });

    test('cannot rotate without charges; free mode ignores charges', () {
      final s = GameSession.newGame(seed: 7);
      for (var i = 0; i < GameSession.startRotationCharges; i++) {
        expect(s.rotate(0), isTrue);
      }
      expect(s.canRotate(0), isFalse);
      expect(s.rotate(0), isFalse);

      final free = GameSession.newGame(seed: 7, freeRotation: true);
      for (var i = 0; i < 10; i++) {
        expect(free.rotate(0), isTrue);
      }
      expect(free.rotationCharges, GameSession.startRotationCharges,
          reason: 'free rotation never consumes charges');
    });

    test('a clearing move refills one charge up to the cap', () {
      final s = GameSession.newGame(seed: 7);
      // Drain the charges first.
      s.rotate(0);
      s.rotate(0);
      expect(s.rotationCharges, 0);

      // Play greedily (first legal spot each move) until a clear happens —
      // seeded, so this is deterministic and bounded.
      Cell? firstLegal(int slot) {
        final piece = s.tray[slot];
        if (piece == null) return null;
        for (var r = 0; r <= 8 - piece.height; r++) {
          for (var c = 0; c <= 8 - piece.width; c++) {
            if (s.canPlace(slot, Cell(r, c))) return Cell(r, c);
          }
        }
        return null;
      }

      var cleared = false;
      for (var move = 0; move < 200 && !cleared && !s.isGameOver; move++) {
        var placedAny = false;
        for (var slot = 0; slot < 3 && !cleared; slot++) {
          final cell = firstLegal(slot);
          if (cell == null) continue;
          final before = s.rotationCharges;
          s.place(slot, cell);
          placedAny = true;
          if (s.lastClearedLineCount > 0) {
            expect(s.rotationCharges, before + 1);
            cleared = true;
          }
        }
        if (!placedAny) break;
      }
      expect(cleared, isTrue, reason: 'the seeded run should clear a line');
    });

    test('undo restores the pre-move rotation charges', () {
      final s = GameSession.newGame(seed: 7);
      // Place one piece (creates the memento), then rotate — undo should
      // restore the tray AND the charge count captured before the move.
      final piece = s.tray[0]!;
      Cell? target;
      for (var r = 0; r <= 8 - piece.height && target == null; r++) {
        for (var c = 0; c <= 8 - piece.width && target == null; c++) {
          if (s.canPlace(0, Cell(r, c))) target = Cell(r, c);
        }
      }
      final chargesBeforeMove = s.rotationCharges;
      s.place(0, target!);
      s.undo();
      expect(s.rotationCharges, chargesBeforeMove);
    });
  });
}
