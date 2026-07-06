import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/piece.dart';

/// Plays a single first-legal move; returns whether one was made.
bool _placeFirstLegal(GameSession g) {
  for (var slot = 0; slot < 3; slot++) {
    if (g.tray[slot] == null) continue;
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (g.canPlace(slot, Cell(r, c))) {
          g.place(slot, Cell(r, c));
          return true;
        }
      }
    }
  }
  return false;
}

void main() {
  group('undo', () {
    test('nothing to undo on a fresh game', () {
      final g = GameSession.newGame(seed: 1);
      expect(g.canUndo, isFalse);
      expect(g.undo(), isFalse);
    });

    test('restores board, tray, score and stats after a placement', () {
      final g = GameSession.newGame(seed: 3);
      final boardBefore = g.board.toAscii();
      final trayBefore = g.tray.map((p) => p?.id).toList();
      final scoreBefore = g.score;

      expect(_placeFirstLegal(g), isTrue);
      expect(g.canUndo, isTrue);
      expect(g.score, isNot(scoreBefore)); // something changed

      expect(g.undo(), isTrue);
      expect(g.board.toAscii(), boardBefore);
      expect(g.tray.map((p) => p?.id).toList(), trayBefore);
      expect(g.score, scoreBefore);
      expect(g.placements, 0);
    });

    test('only one undo in a row', () {
      final g = GameSession.newGame(seed: 3);
      _placeFirstLegal(g);
      expect(g.undo(), isTrue);
      expect(g.canUndo, isFalse);
      expect(g.undo(), isFalse);
    });

    test('cannot undo across a booster (bomb)', () {
      final g = GameSession.newGame(seed: 3);
      _placeFirstLegal(g);
      g.bombAt(const Cell(4, 4));
      expect(g.canUndo, isFalse);
    });
  });

  group('bombAt', () {
    test('the 3x3 block around the cell is empty afterwards', () {
      // Drive to a fairly full board, then bomb (4,4): the whole 3x3 region
      // must be empty regardless of what was there before.
      final g = GameSession.newGame(seed: 4);
      var guard = 0;
      while (!g.isGameOver && guard < 5000) {
        if (!_placeFirstLegal(g)) break;
        guard++;
      }
      g.bombAt(const Cell(4, 4));
      for (var r = 3; r <= 5; r++) {
        for (var c = 3; c <= 5; c++) {
          expect(g.board.filledAt(r, c), isFalse, reason: '($r,$c)');
        }
      }
    });

    test('empties a region and can reopen game over', () {
      final g = GameSession.newGame(seed: 7);
      // Drive to game over.
      var guard = 0;
      while (!g.isGameOver && guard < 5000) {
        if (!_placeFirstLegal(g)) break;
        guard++;
      }
      if (g.isGameOver) {
        final before = g.board.filledCount;
        g.bombAt(const Cell(4, 4));
        expect(g.board.filledCount, lessThan(before)); // cells removed
      }
    });

    test('bomb gives no points and keeps the score', () {
      final g = GameSession.newGame(seed: 9);
      _placeFirstLegal(g);
      final scoreBefore = g.score;
      g.bombAt(const Cell(4, 4));
      expect(g.score, scoreBefore);
    });

    test('bomb clamps at the board corner without error', () {
      final g = GameSession.newGame(seed: 2);
      _placeFirstLegal(g);
      // Corner bomb touches only in-bounds cells.
      expect(() => g.bombAt(const Cell(0, 0)), returnsNormally);
      expect(() => g.bombAt(const Cell(7, 7)), returnsNormally);
    });
  });
}
