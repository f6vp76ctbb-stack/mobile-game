import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/monetization/ad_gate.dart';

void main() {
  group('round gating', () {
    test('no interstitial before round 3', () {
      final gate = AdGate(now: () => DateTime(2026, 7, 5, 12));
      expect(gate.canShowInterstitial(), isFalse);
      gate.recordRoundComplete(); // 1
      expect(gate.canShowInterstitial(), isFalse);
      gate.recordRoundComplete(); // 2
      expect(gate.canShowInterstitial(), isFalse);
      gate.recordRoundComplete(); // 3
      expect(gate.canShowInterstitial(), isTrue);
    });
  });

  group('90 second cap', () {
    test('blocks a second interstitial within the gap, allows after', () {
      var now = DateTime(2026, 7, 5, 12, 0, 0);
      final gate = AdGate(now: () => now);
      for (var i = 0; i < 3; i++) {
        gate.recordRoundComplete();
      }
      expect(gate.canShowInterstitial(), isTrue);
      gate.recordInterstitialShown();

      gate.recordRoundComplete(); // round 4
      now = now.add(const Duration(seconds: 60));
      expect(gate.canShowInterstitial(), isFalse); // still within 90s

      now = now.add(const Duration(seconds: 31)); // 91s since last
      expect(gate.canShowInterstitial(), isTrue);
    });

    test('just under the gap is capped, exactly at the gap is allowed', () {
      var now = DateTime(2026, 7, 5, 12, 0, 0);
      final gate = AdGate(now: () => now);
      for (var i = 0; i < 3; i++) {
        gate.recordRoundComplete();
      }
      gate.recordInterstitialShown();
      now = now.add(const Duration(seconds: 89));
      expect(gate.canShowInterstitial(), isFalse); // still within 90s
      now = now.add(const Duration(seconds: 1)); // exactly 90s -> min gap met
      expect(gate.canShowInterstitial(), isTrue);
    });
  });

  group('ad-free', () {
    test('suppresses interstitials regardless of rounds or time', () {
      final gate = AdGate(now: () => DateTime(2026, 7, 5, 12))..adFree = true;
      for (var i = 0; i < 10; i++) {
        gate.recordRoundComplete();
      }
      expect(gate.canShowInterstitial(), isFalse);
    });
  });
}
