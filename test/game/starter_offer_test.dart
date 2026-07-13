import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/starter_offer.dart';

void main() {
  group('shouldStart', () {
    test('not before the 5th game', () {
      expect(
        StarterOffer.shouldStart(
          gamesPlayed: 4,
          startMillis: null,
          purchased: false,
        ),
        isFalse,
      );
    });

    test('starts at the 5th game', () {
      expect(
        StarterOffer.shouldStart(
          gamesPlayed: 5,
          startMillis: null,
          purchased: false,
        ),
        isTrue,
      );
    });

    test('never starts again once started', () {
      expect(
        StarterOffer.shouldStart(
          gamesPlayed: 9,
          startMillis: 123,
          purchased: false,
        ),
        isFalse,
      );
    });

    test('never starts once purchased', () {
      expect(
        StarterOffer.shouldStart(
          gamesPlayed: 9,
          startMillis: null,
          purchased: true,
        ),
        isFalse,
      );
    });
  });

  group('isActive', () {
    final start = DateTime(2026, 7, 5, 12);

    test('active within the 48h window', () {
      expect(
        StarterOffer.isActive(
          startMillis: start.millisecondsSinceEpoch,
          purchased: false,
          now: start.add(const Duration(hours: 47)),
        ),
        isTrue,
      );
    });

    test('gone after the window expires', () {
      expect(
        StarterOffer.isActive(
          startMillis: start.millisecondsSinceEpoch,
          purchased: false,
          now: start.add(const Duration(hours: 49)),
        ),
        isFalse,
      );
    });

    test('gone once purchased even inside the window', () {
      expect(
        StarterOffer.isActive(
          startMillis: start.millisecondsSinceEpoch,
          purchased: true,
          now: start.add(const Duration(hours: 1)),
        ),
        isFalse,
      );
    });

    test('inactive when never started', () {
      expect(
        StarterOffer.isActive(
          startMillis: null,
          purchased: false,
          now: start,
        ),
        isFalse,
      );
    });
  });

  group('remaining', () {
    final start = DateTime(2026, 7, 5, 12);

    test('counts down within the window', () {
      final left = StarterOffer.remaining(
        startMillis: start.millisecondsSinceEpoch,
        now: start.add(const Duration(hours: 10)),
      );
      expect(left, const Duration(hours: 38));
    });

    test('is zero once expired', () {
      final left = StarterOffer.remaining(
        startMillis: start.millisecondsSinceEpoch,
        now: start.add(const Duration(hours: 50)),
      );
      expect(left, Duration.zero);
    });
  });
}
