import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/coach_hints.dart';

void main() {
  group('CoachHints.next', () {
    test('prioritizes time-sensitive combo and fever signals', () {
      const allSignals = CoachHintSignals(
        comboActive: true,
        feverActive: true,
        rotationUsed: true,
        boosterAffordable: true,
      );

      expect(
        CoachHints.next(signals: allSignals, seen: const {}),
        CoachHintType.combo,
      );
      expect(
        CoachHints.next(signals: allSignals, seen: const {CoachHintType.combo}),
        CoachHintType.fever,
      );
    });

    test(
      'falls through to rotation and booster when earlier hints were seen',
      () {
        const signals = CoachHintSignals(
          comboActive: true,
          feverActive: true,
          rotationUsed: true,
          boosterAffordable: true,
        );

        expect(
          CoachHints.next(
            signals: signals,
            seen: const {CoachHintType.combo, CoachHintType.fever},
          ),
          CoachHintType.rotation,
        );
        expect(
          CoachHints.next(
            signals: signals,
            seen: const {
              CoachHintType.combo,
              CoachHintType.fever,
              CoachHintType.rotation,
            },
          ),
          CoachHintType.booster,
        );
      },
    );

    test('returns null when no active signal is unseen', () {
      expect(
        CoachHints.next(signals: const CoachHintSignals(), seen: const {}),
        isNull,
      );
      expect(
        CoachHints.next(
          signals: const CoachHintSignals(boosterAffordable: true),
          seen: const {CoachHintType.booster},
        ),
        isNull,
      );
    });
  });

  test('every hint has concise player-facing copy', () {
    for (final hint in CoachHintType.values) {
      expect(CoachHints.text(hint).trim(), isNotEmpty);
    }
  });
}
