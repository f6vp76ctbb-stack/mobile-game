import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/piece.dart';

void main() {
  test('checkpoint restores the board, score and next generated tray', () {
    final original = GameSession.newGame(seed: 42, freeRotation: false);
    _placeAnywhere(original, 0);
    original.rotate(1);

    final restored = GameSession.fromCheckpoint(
      Map<String, dynamic>.from(original.toCheckpoint()),
    );

    expect(restored.board.toAscii(), original.board.toAscii());
    expect(restored.score, original.score);
    expect(restored.combo, original.combo);
    expect(restored.placements, original.placements);
    expect(restored.rotationCharges, original.rotationCharges);
    expect(
      restored.tray.map((piece) => piece?.id),
      original.tray.map((piece) => piece?.id),
    );

    _placeRemainingTray(original);
    _placeRemainingTray(restored);
    expect(
      restored.tray.map((piece) => piece?.id),
      original.tray.map((piece) => piece?.id),
    );
  });

  test('checkpoint rejects missing generator state', () {
    final checkpoint = GameSession.newGame(seed: 7).toCheckpoint()
      ..remove('generatedTrays');

    expect(
      () => GameSession.fromCheckpoint(Map<String, dynamic>.from(checkpoint)),
      throwsFormatException,
    );
  });
}

bool _placeAnywhere(GameSession session, int slot) {
  for (var row = 0; row < Board.size; row++) {
    for (var column = 0; column < Board.size; column++) {
      final origin = Cell(row, column);
      if (session.canPlace(slot, origin)) {
        return session.place(slot, origin) != null;
      }
    }
  }
  return false;
}

void _placeRemainingTray(GameSession session) {
  for (var slot = 0; slot < 3; slot++) {
    if (session.tray[slot] != null) _placeAnywhere(session, slot);
  }
}
