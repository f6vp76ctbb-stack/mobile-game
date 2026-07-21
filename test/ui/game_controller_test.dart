import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/leveling.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GameController> _controller({AdService? ads}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = await Storage.create();
  return GameController(
    storage,
    Haptics(enabled: false),
    SilentAudio(),
    ads ?? FakeAdService(),
    NoopAnalytics(),
  );
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

/// Plays a single first-legal move. Returns whether one was made.
bool _placeOneLegalMove(GameController c) {
  for (var slot = 0; slot < c.state.tray.length; slot++) {
    if (c.state.tray[slot] == null) continue;
    for (var r = 0; r < Board.size; r++) {
      for (var col = 0; col < Board.size; col++) {
        if (c.canPlace(slot, Cell(r, col))) {
          c.place(slot, Cell(r, col));
          return true;
        }
      }
    }
  }
  return false;
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

  test('onboarding hint shows on first run and clears after 3 moves', () async {
    final c = await _controller(); // fresh prefs => onboarding active
    c.newGame(seed: 3);
    expect(c.state.onboardingHint, isNotNull);

    for (var i = 0; i < 3; i++) {
      _placeOneLegalMove(c);
    }
    expect(c.state.onboardingHint, isNull);
  });

  test('daily mode never shows the onboarding hint', () async {
    final c = await _controller();
    c.startDaily(now: DateTime(2026, 7, 5));
    expect(c.state.onboardingHint, isNull);
  });

  test('a finished run updates lifetime stats', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await Storage.create();
    final c = GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
    );
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final stats = storage.lifetimeStats;
    expect(stats.games, 1);
    expect(stats.totalPieces, greaterThan(0));
  });

  test('clearing lines increments the clear event id', () async {
    final c = await _controller();
    c.newGame(seed: 1);
    _playToGameOver(c);
    // A greedy full run reliably clears lines, so the particle trigger must
    // have fired at least once and exposed the cleared cells.
    expect(c.state.clearEventId, greaterThan(0));
  });

  group('boosters', () {
    test('undo is unavailable with nothing to undo', () async {
      final c = await _controller();
      c.newGame(seed: 1);
      expect(c.state.canUndo, isFalse);
      expect(await c.tryUndo(), isFalse);
    });

    test('undo reverts the last move and costs coins', () async {
      SharedPreferences.setMockInitialValues({'coins': 100});
      final storage = await Storage.create();
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
          NoopAnalytics(),
      );
      c.newGame(seed: 3);
      final scoreBefore = c.state.score;
      _placeOneLegalMove(c);
      expect(c.state.canUndo, isTrue);
      final ok = await c.tryUndo();
      expect(ok, isTrue);
      expect(c.state.score, scoreBefore);
      expect(c.state.coins, 50); // 100 - 50
      expect(c.state.canUndo, isFalse); // only one undo
    });

    test('undo is refused without enough coins', () async {
      SharedPreferences.setMockInitialValues({'coins': 10});
      final storage = await Storage.create();
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
          NoopAnalytics(),
      );
      c.newGame(seed: 3);
      _placeOneLegalMove(c);
      expect(await c.tryUndo(), isFalse);
      expect(c.state.canUndo, isTrue); // move preserved
    });

    test('swap costs coins and redraws the tray', () async {
      SharedPreferences.setMockInitialValues({'coins': 100});
      final storage = await Storage.create();
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
          NoopAnalytics(),
      );
      c.newGame(seed: 5);
      final before = c.state.tray.map((p) => p?.id).toList();
      final ok = await c.trySwapPieces();
      expect(ok, isTrue);
      expect(c.state.coins, 25); // 100 - 75
      expect(c.state.tray.map((p) => p?.id).toList(), isNot(before));
    });

    test('bomb costs coins', () async {
      SharedPreferences.setMockInitialValues({'coins': 200});
      final storage = await Storage.create();
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
          NoopAnalytics(),
      );
      c.newGame(seed: 5);
      final ok = await c.tryBomb(const Cell(4, 4));
      expect(ok, isTrue);
      expect(c.state.coins, 50); // 200 - 150
    });
  });

  test('an illegal placement is a no-op', () async {
    final c = await _controller();
    c.newGame(seed: 2);
    final before = c.state.score;
    c.place(0, const Cell(100, 100));
    expect(c.state.score, before);
  });

  test('reaching a milestone level unlocks its cosmetic reward', () async {
    // One XP shy of level 3 (neon theme milestone); any run earns >=1 XP.
    SharedPreferences.setMockInitialValues({
      'playerLevel': 2,
      'xp': LevelSystem.xpForNext(2) - 1,
    });
    final storage = await Storage.create();
    var cosmeticsCallbackFired = false;
    final c = GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
      onCosmeticsGranted: () => cosmeticsCallbackFired = true,
    );
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(storage.playerLevel, greaterThanOrEqualTo(3));
    expect(storage.unlockedThemes, contains('neon'));
    expect(
      c.state.rewardsUnlockedThisRun.map((r) => r.id),
      contains('neon'),
    );
    expect(cosmeticsCallbackFired, isTrue);
  });

  test('an already-owned reward is not re-announced', () async {
    SharedPreferences.setMockInitialValues({
      'playerLevel': 2,
      'xp': LevelSystem.xpForNext(2) - 1,
      'unlockedThemes': <String>['neon'],
    });
    final storage = await Storage.create();
    final c = GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
    );
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Crossed level 3 but already owned neon → nothing new to announce.
    expect(storage.playerLevel, greaterThanOrEqualTo(3));
    expect(c.state.rewardsUnlockedThisRun, isEmpty);
  });

  test('clearing lines awards live coins during play', () async {
    SharedPreferences.setMockInitialValues({'coins': 0});
    final storage = await Storage.create();
    final c = GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
    );
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // A greedy full run clears many lines, each worth kCoinsPerLine coins,
    // so the balance must have grown from the live rewards.
    expect(storage.coins, greaterThan(0));
    // The run total shown on game-over includes those play coins.
    expect(c.state.coinsEarnedThisRun, greaterThan(0));
  });

  test('finishing a run unlocks and persists achievements', () async {
    final c = await _controller();
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // At minimum the "first game" achievement unlocks after one finished run.
    final ids = c.state.achievementsUnlockedThisRun.map((a) => a.id).toList();
    expect(ids, contains('first_game'));
    expect(c.state.achievementsUnlockedThisRun, isNotEmpty);
  });

  test('achievements already unlocked are not re-announced next run', () async {
    SharedPreferences.setMockInitialValues({
      'achievements': <String>['first_game'],
    });
    final storage = await Storage.create();
    final c = GameController(
      storage,
      Haptics(enabled: false),
      SilentAudio(),
      FakeAdService(),
      NoopAnalytics(),
    );
    c.newGame(seed: 1);
    _playToGameOver(c);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final ids = c.state.achievementsUnlockedThisRun.map((a) => a.id).toList();
    expect(ids, isNot(contains('first_game')));
    // The unlocked set persists across the run.
    expect(storage.unlockedAchievements, contains('first_game'));
  });
}
