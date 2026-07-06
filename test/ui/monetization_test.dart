import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/piece.dart';
import 'package:gridpop/monetization/ad_gate.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/monetization/iap.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the controller by always playing the first legal move it finds.
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

/// Rewarded ad that never grants (user closed it early).
class _NoRewardAds implements AdService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> showInterstitial() async {}
  @override
  Future<bool> showRewarded() async => false;
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
    AdGate(now: DateTime.now),
    NoopAnalytics(),
  );
}

void main() {
  group('rewarded flows', () {
    test('revive grants when the reward is earned', () async {
      final c = await _controller(); // FakeAdService always earns
      final ok = await c.reviveWithAd();
      expect(ok, isTrue);
    });

    test('revive does nothing when the reward is not earned', () async {
      final c = await _controller(ads: _NoRewardAds());
      final before = c.state.board.toAscii();
      final ok = await c.reviveWithAd();
      expect(ok, isFalse);
      expect(c.state.board.toAscii(), before);
    });

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

  group('IAP entitlements', () {
    test('applyAdFree flips the flag in the snapshot', () async {
      final c = await _controller();
      expect(c.state.adFree, isFalse);
      await c.applyAdFree();
      expect(c.state.adFree, isTrue);
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
      await iap.buy(IapProducts.removeAds);
      await iap.buy(IapProducts.coinsM);
      expect(delivered, [IapProducts.removeAds, IapProducts.coinsM]);
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
      expect(IapProducts.isConsumable(IapProducts.removeAds), isFalse);
    });
  });
}
