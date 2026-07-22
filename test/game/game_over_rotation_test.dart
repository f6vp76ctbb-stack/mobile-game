import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  // A board whose ONLY empty cells are a vertical strip of three in column 0.
  // No horizontal run of three empty cells exists anywhere, so a horizontal
  // 1x3 line does not fit as-is — but rotated to vertical it fits the gap.
  Board gapBoard() => Board.fromAscii(const [
        '.XXXXXXX',
        '.XXXXXXX',
        '.XXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
        'XXXXXXXX',
      ]);

  Piece horizontalLine() =>
      Piece('line3_h', const [Cell(0, 0), Cell(0, 1), Cell(0, 2)], 1);

  group('game over must account for rotation', () {
    test('NOT game over when the piece fits only after a free rotation', () {
      final s = GameSession.forTest(
        board: gapBoard(),
        tray: [horizontalLine()],
        freeRotation: true,
      );
      expect(s.isGameOver, isFalse,
          reason: 'a rotation would let the line fit the vertical gap');
    });

    test('NOT game over when charges allow the needed rotation (level 3+)', () {
      final s = GameSession.forTest(
        board: gapBoard(),
        tray: [horizontalLine()],
        freeRotation: false,
        rotationCharges: 1, // one cw rotation reaches the fitting orientation
      );
      expect(s.isGameOver, isFalse);
    });

    test('IS game over only when rotation is truly impossible', () {
      final s = GameSession.forTest(
        board: gapBoard(),
        tray: [horizontalLine()],
        freeRotation: false,
        rotationCharges: 0, // cannot rotate, and it does not fit as-is
      );
      expect(s.isGameOver, isTrue);
    });

    test('a piece that already fits is never game over', () {
      final s = GameSession.forTest(
        board: gapBoard(),
        // Vertical line fits the gap directly.
        tray: [
          Piece('line3_v', const [Cell(0, 0), Cell(1, 0), Cell(2, 0)], 1),
        ],
        freeRotation: false,
        rotationCharges: 0,
      );
      expect(s.isGameOver, isFalse);
    });
  });
}
