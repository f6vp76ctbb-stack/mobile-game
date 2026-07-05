import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/board.dart';
import 'package:gridpop/game/daily.dart';
import 'package:gridpop/game/generator.dart';

void main() {
  group('seed', () {
    test('is stable for a given date regardless of time of day', () {
      final morning = DateTime(2026, 7, 5, 8, 30);
      final night = DateTime(2026, 7, 5, 23, 59);
      expect(
        DailyChallenge.seedForDate(morning),
        DailyChallenge.seedForDate(night),
      );
    });

    test('differs across days', () {
      expect(
        DailyChallenge.seedForDate(DateTime(2026, 7, 5)),
        isNot(DailyChallenge.seedForDate(DateTime(2026, 7, 6))),
      );
    });

    test('drives a reproducible generator sequence', () {
      final seed = DailyChallenge.seedForDate(DateTime(2026, 7, 5));
      final board = Board.empty();
      final a = PieceGenerator(seed: seed).nextTray(board, 0).map((p) => p.id);
      final b = PieceGenerator(seed: seed).nextTray(board, 0).map((p) => p.id);
      expect(a.toList(), b.toList());
    });
  });

  group('dateKey', () {
    test('zero-pads month and day', () {
      expect(DailyChallenge.dateKey(DateTime(2026, 1, 3)), '2026-01-03');
      expect(DailyChallenge.dateKey(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('isConsecutiveDay', () {
    test('true for adjacent days', () {
      expect(
        DailyChallenge.isConsecutiveDay(
          DateTime(2026, 7, 5),
          DateTime(2026, 7, 6),
        ),
        isTrue,
      );
    });

    test('true across a month boundary', () {
      expect(
        DailyChallenge.isConsecutiveDay(
          DateTime(2026, 7, 31),
          DateTime(2026, 8, 1),
        ),
        isTrue,
      );
    });

    test('false for the same day or a gap', () {
      expect(
        DailyChallenge.isConsecutiveDay(
          DateTime(2026, 7, 5),
          DateTime(2026, 7, 5),
        ),
        isFalse,
      );
      expect(
        DailyChallenge.isConsecutiveDay(
          DateTime(2026, 7, 5),
          DateTime(2026, 7, 7),
        ),
        isFalse,
      );
    });
  });
}
