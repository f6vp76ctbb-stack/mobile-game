import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/monetization/iap.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/leaderboard.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the controller by always playing the first legal move it finds.
void _playToGameOver(GameController c) {
  var guard = 0;
  while (!c.state.gameOver && guard < 5000) {
    if (!_playOneMove(c)) break;
    guard++;
  }
}

/// Plays one move like a real player: a direct placement if possible, else a
/// rotation rescue (only spending charges on a piece that will actually fit).
bool _playOneMove(GameController c) {
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
  final budget = c.state.rotationFree ? 3 : c.state.rotationCharges.clamp(0, 3);
  for (var slot = 0; slot < c.state.tray.length; slot++) {
    final piece = c.state.tray[slot];
    if (piece == null) continue;
    var rotated = piece;
    for (var rot = 1; rot <= budget; rot++) {
      rotated = rotated.rotatedCw();
      if (c.state.board.hasAnyPlacement(rotated)) {
        for (var i = 0; i < rot; i++) {
          c.rotateTray(slot);
        }
        for (var r = 0; r < Board.size; r++) {
          for (var col = 0; col < Board.size; col++) {
            if (c.canPlace(slot, Cell(r, col))) {
              c.place(slot, Cell(r, col));
              return true;
            }
          }
        }
      }
    }
  }
  return false;
}

/// Rewarded ad that never grants (user closed it early).
class _NoRewardAds implements AdService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> showRewarded() async => false;
}

/// Records leaderboard submissions; [succeed] simulates online/offline.
class _FakeLeaderboard extends LeaderboardService {
  _FakeLeaderboard({this.succeed = true});
  final bool succeed;
  final List<({String name, int score})> submitted = [];
  @override
  Future<bool> submit({required String name, required int score}) async {
    submitted.add((name: name, score: score));
    return succeed;
  }
}

Future<GameController> _controller({
  AdService? ads,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.create();
  return GameController(
    storage,
    Haptics(enabled: false),
    SilentAudio(),
    ads ?? FakeAdService(),
    NoopAnalytics(),
  );
}

void main() {
  group('revive (coins, never ads)', () {
    test('spends coins, clears the centre, once per run', () async {
      final c = await _controller(prefs: {'coins': 500});
      c.newGame(seed: 1);
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final balance = c.state.coins;
      final ok = await c.reviveWithCoins();
      expect(ok, isTrue);
      expect(c.state.coins, balance - BoosterCosts.revive);
      expect(c.state.reviveUsed, isTrue);

      // Only one revive per run.
      expect(await c.reviveWithCoins(), isFalse);
      expect(c.state.coins, balance - BoosterCosts.revive);
    });

    test('refused without enough coins', () async {
      final c = await _controller(prefs: {'coins': 100});
      c.newGame(seed: 1);
      final before = c.state.board.toAscii();
      expect(await c.reviveWithCoins(), isFalse);
      expect(c.state.board.toAscii(), before);
      expect(c.state.coins, 100);
    });

    test('a new run resets the revive', () async {
      final c = await _controller(prefs: {'coins': 500});
      c.newGame(seed: 1);
      await c.reviveWithCoins();
      expect(c.state.reviveUsed, isTrue);
      c.newGame(seed: 2);
      expect(c.state.reviveUsed, isFalse);
    });
  });

  group('rewarded flows', () {
    test('lucky block rerolls the tray when earned', () async {
      final c = await _controller();
      c.newGame(seed: 5);
      final before = c.state.tray.map((p) => p?.id).toList();
      final ok = await c.luckyBlock();
      expect(ok, isTrue);
      // A reroll draws the next tray from the generator; with this seed it
      // differs from the opening tray.
      expect(c.state.tray.map((p) => p?.id).toList(), isNot(before));
    });
  });

  group('double coins', () {
    test('doubles earned coins once when the ad is watched', () async {
      final c = await _controller(prefs: {'coins': 0});
      c.startDaily(now: DateTime(2026, 7, 5));
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final earned = c.state.coinsEarnedThisRun;
      final balance = c.state.coins;
      expect(earned, greaterThan(0));

      final ok = await c.doubleCoinsWithAd();
      expect(ok, isTrue);
      expect(c.state.coins, balance + earned); // bonus added once
      expect(c.state.coinsDoubled, isTrue);

      // Second attempt is a no-op.
      expect(await c.doubleCoinsWithAd(), isFalse);
    });

    test('cannot double when nothing was earned', () async {
      final c = await _controller();
      expect(await c.doubleCoinsWithAd(), isFalse);
    });
  });

  group('streak repair', () {
    // Yesterday-missed setup: last daily 2 days ago, active streak.
    Map<String, Object> repairablePrefs({int coins = 0}) {
      final today = DateTime.now();
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final key = '${twoDaysAgo.year}-'
          '${twoDaysAgo.month.toString().padLeft(2, '0')}-'
          '${twoDaysAgo.day.toString().padLeft(2, '0')}';
      return {'lastDailyDate': key, 'streak': 4, 'coins': coins};
    }

    test('offer is present when exactly one day was missed', () async {
      final c = await _controller(prefs: repairablePrefs());
      expect(c.state.streakRepairAvailable, isTrue);
    });

    test('coin repair spends coins and clears the offer', () async {
      final c = await _controller(prefs: repairablePrefs(coins: 200));
      final ok = await c.repairStreakWithCoins();
      expect(ok, isTrue);
      expect(c.state.coins, 50); // 200 - 150
      expect(c.state.streakRepairAvailable, isFalse); // repaired -> yesterday
    });

    test('coin repair refused without enough coins', () async {
      final c = await _controller(prefs: repairablePrefs(coins: 100));
      expect(await c.repairStreakWithCoins(), isFalse);
      expect(c.state.streakRepairAvailable, isTrue);
    });

    test('ad repair heals the streak', () async {
      final c = await _controller(prefs: repairablePrefs());
      final ok = await c.repairStreakWithAd();
      expect(ok, isTrue);
      expect(c.state.streakRepairAvailable, isFalse);
    });
  });

  group('piggy bank', () {
    test('fills while playing and opening pays out + raises capacity', () async {
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

      final filled = storage.piggyBank.coins;
      // A full greedy run clears lines, so the piggy has something in it.
      expect(filled, greaterThan(0));
      expect(c.state.piggyCoins, filled);

      final balanceBefore = c.state.coins;
      final payout = await c.openPiggy();
      expect(payout, filled);
      expect(c.state.coins, balanceBefore + payout); // paid into balance
      expect(c.state.piggyCoins, 0); // emptied
      expect(c.state.piggyCapacity, greaterThan(500)); // capacity grew
    });

    test('early open via rewarded video pays out when earned', () async {
      final c = await _controller(prefs: {
        'coins': 0,
        'piggyCoins': 120,
        'piggyCapacity': 500,
      });
      final payout = await c.openPiggyWithAd();
      expect(payout, 120);
      expect(c.state.coins, 120);
      expect(c.state.piggyCoins, 0);
    });

    test('early open pays nothing when the reward is not earned', () async {
      final c = await _controller(ads: _NoRewardAds(), prefs: {
        'coins': 0,
        'piggyCoins': 120,
        'piggyCapacity': 500,
      });
      final payout = await c.openPiggyWithAd();
      expect(payout, isNull);
      expect(c.state.coins, 0);
      expect(c.state.piggyCoins, 120); // untouched
    });
  });

  group('starter offer', () {
    test('activates after the 5th finished run', () async {
      SharedPreferences.setMockInitialValues({'lifetimeStats': '{"games":4}'});
      final storage = await Storage.create();
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
            NoopAnalytics(),
      );
      expect(c.state.starterOfferActive, isFalse);

      c.newGame(seed: 1);
      _playToGameOver(c); // 5th game overall
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(storage.lifetimeStats.games, 5);
      expect(c.state.starterOfferActive, isTrue);
      expect(storage.starterOfferStart, isNotNull);
    });

    test('does not reactivate once purchased', () async {
      SharedPreferences.setMockInitialValues({
        'lifetimeStats': '{"games":10}',
        'starterPurchased': true,
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
      expect(c.state.starterOfferActive, isFalse);
      expect(storage.starterOfferStart, isNull);
    });
  });

  group('leveling', () {
    test('a daily run grants XP and can level up', () async {
      // Start 1 XP short of level 2 (needs 150). Daily bonus alone is +50 XP.
      final c = await _controller(prefs: {'xp': 149, 'playerLevel': 1});
      c.startDaily(now: DateTime(2026, 7, 5));
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(c.state.playerLevel, 2);
      expect(c.state.levelsGainedThisRun, greaterThanOrEqualTo(1));
      expect(c.state.xpForNextLevel, 200); // xpForNext(2)
    });

    test('level state is exposed from storage on start', () async {
      final c = await _controller(prefs: {'xp': 40, 'playerLevel': 3});
      expect(c.state.playerLevel, 3);
      expect(c.state.xpIntoLevel, 40);
      expect(c.state.xpForNextLevel, 250); // 100 + 50*3
    });
  });

  group('auto leaderboard upload', () {
    Future<(GameController, _FakeLeaderboard)> controllerWith({
      required bool succeed,
      Map<String, Object> prefs = const {'playerName': 'Sam'},
    }) async {
      SharedPreferences.setMockInitialValues(prefs);
      final storage = await Storage.create();
      final board = _FakeLeaderboard(succeed: succeed);
      final c = GameController(
        storage,
        Haptics(enabled: false),
        SilentAudio(),
        FakeAdService(),
        NoopAnalytics(),
        leaderboard: board,
      );
      return (c, board);
    }

    test('uploads the best score automatically at game over', () async {
      final (c, board) = await controllerWith(succeed: true);
      c.newGame(seed: 1);
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(board.submitted, hasLength(1));
      expect(board.submitted.first.name, 'Sam');
      expect(board.submitted.first.score, c.state.highscore);
      // Marked as submitted so it won't re-upload the same score.
      expect(c.state.lastSubmittedScore, c.state.highscore);
    });

    test('keeps the score queued when offline (retries later)', () async {
      final (c, board) = await controllerWith(succeed: false);
      c.newGame(seed: 1);
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(board.submitted, isNotEmpty); // attempted
      expect(c.state.lastSubmittedScore, 0); // but not marked done

      // Still queued: a later call retries (best > lastSubmittedScore).
      board.submitted.clear();
      c.autoUploadBestScore();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(board.submitted, isNotEmpty);
    });

    test('does nothing without a player name', () async {
      final (c, board) = await controllerWith(
        succeed: true,
        prefs: const {},
      );
      c.newGame(seed: 1);
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(board.submitted, isEmpty);
    });

    test('renaming re-uploads under the new name', () async {
      final (c, board) = await controllerWith(succeed: true);
      c.newGame(seed: 1);
      _playToGameOver(c);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      board.submitted.clear();

      await c.setPlayerName('NewName');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(board.submitted, hasLength(1));
      expect(board.submitted.first.name, 'NewName');
    });
  });

  group('paid name change', () {
    test('a purchased credit lets the player rename once', () async {
      final c = await _controller(prefs: {'playerName': 'Old'});
      expect(c.state.renameCredits, 0);
      // Renaming is blocked without a credit.
      expect(await c.renameWithCredit('New'), isFalse);
      expect(c.state.playerName, 'Old');

      await c.grantRenameCredit();
      expect(c.state.renameCredits, 1);
      expect(await c.renameWithCredit('New'), isTrue);
      expect(c.state.playerName, 'New');
      expect(c.state.renameCredits, 0); // consumed

      // No more free renames.
      expect(await c.renameWithCredit('Again'), isFalse);
      expect(c.state.playerName, 'New');
    });

    test('rejects a too-short name and keeps the credit', () async {
      final c = await _controller(prefs: {'playerName': 'Old'});
      await c.grantRenameCredit();
      expect(await c.renameWithCredit('x'), isFalse);
      expect(c.state.renameCredits, 1); // not consumed
      expect(c.state.playerName, 'Old');
    });
  });

  group('IAP entitlements', () {
    test('applySupporter flips the flag in the snapshot', () async {
      final c = await _controller();
      expect(c.state.supporter, isFalse);
      await c.applySupporter();
      expect(c.state.supporter, isTrue);
    });

    test('grantCoins increases the balance', () async {
      final c = await _controller(prefs: {'coins': 100});
      await c.grantCoins(500);
      expect(c.state.coins, 600);
    });
  });

  group('FakeIap delivery', () {
    test('buying a product invokes the delivery handler', () async {
      final delivered = <String>[];
      final iap = FakeIap();
      await iap.initialize(delivered.add);
      await iap.buy(IapProducts.supporter);
      await iap.buy(IapProducts.coinsM);
      expect(delivered, [IapProducts.supporter, IapProducts.coinsM]);
    });

    test('LockedIap (public web) never delivers anything', () async {
      final delivered = <String>[];
      final iap = LockedIap();
      await iap.initialize(delivered.add);
      await iap.buy(IapProducts.supporter);
      await iap.buy(IapProducts.coinsL);
      expect(delivered, isEmpty);
      expect(iap.products, isEmpty);
      expect(iap.available, isFalse);
    });

    test('coin amounts are defined for every consumable pack', () {
      for (final id in [
        IapProducts.coinsS,
        IapProducts.coinsM,
        IapProducts.coinsL,
      ]) {
        expect(IapProducts.coinAmounts[id], isNotNull);
        expect(IapProducts.isConsumable(id), isTrue);
      }
      expect(IapProducts.isConsumable(IapProducts.supporter), isFalse);
    });
  });
}
