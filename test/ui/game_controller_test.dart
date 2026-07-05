import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameController> _controller() async {
  SharedPreferences.setMockInitialValues({});
  final storage = await Storage.create();
  return GameController(storage, Haptics(enabled: false), SilentAudio());
}

/// Drives the controller by always playing the first legal move it can find.
/// Returns when the game is over or the guard trips.
void _playToGameOver(GameController c) {
  var guard = 0;
  while (!c.state.gameOver && guard < 5000) {
    var moved = false;
    for (var slot = 0; slot < c.state.tray.length && !moved; slot++) {
      if (c.state.tray[slot] == null) continue;
      for (var r = 0; r < Board.size && !moved; r++) {
        for (var col = 0; col < Board.size && !moved; col++) {
          if (c.canPlace(slot, Cell(r, col))) {
            c.place(slot, Cell(r, col));
            moved = true;
          }
        }
      }
    }
    if (!moved) break;
    guard++;
  }
}

void main() {
  test('endless run does not touch the daily streak', () async {
    final c = await _controller();
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(c.state.gameOver, isTrue);
    expect(c.state.isDaily, isFalse);
    expect(c.state.streak, 0);
  });

  test('completing the daily awards coins and starts a streak', () async {
    final c = await _controller();
    final startCoins = c.state.coins;
    c.startDaily(now: DateTime(2026, 7, 5));
    expect(c.state.isDaily, isTrue);

    _playToGameOver(c);
    // Let the async finalize (storage writes) settle.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(c.state.streak, 1);
    // First daily completion always grants at least the base + streak reward.
    expect(c.state.coinsEarnedThisRun, greaterThanOrEqualTo(60));
    expect(c.state.coins, greaterThan(startCoins));
  });

  test('an illegal placement is a no-op', () async {
    final c = await _controller();
    c.newGame(seed: 2);
    final before = c.state.score;
    c.place(0, const Cell(100, 100));
    expect(c.state.score, before);
  });
}
