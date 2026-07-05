import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/monetization/ad_gate.dart';
import 'package:gridpop/monetization/ads.dart';
import 'package:gridpop/monetization/iap.dart';
import 'package:gridpop/services/analytics.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
