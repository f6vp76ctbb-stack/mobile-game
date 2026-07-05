import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/scoring.dart';

void main() {
  group('placement points', () {
    test('placing without a clear scores one point per cell', () {
      final s = ScoreKeeper();
      final e = s.applyPlacement(
        placedCells: 4,
        clearedLines: 0,
        clearedCells: 0,
        isAllClear: false,
      );
      expect(e.gained, 4);
      expect(e.total, 4);
      expect(e.combo, 0);
    });
  });

  group('clear points', () {
    test('single line: 10 per cleared cell x1 x combo1', () {
      final s = ScoreKeeper();
      final e = s.applyPlacement(
        placedCells: 1,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: false,
      );
      // placement 1 + clear 8*10*1*1.0 = 81
      expect(e.gained, 81);
      expect(e.combo, 1);
    });

    test('double line applies x2 line multiplier', () {
      final s = ScoreKeeper();
      final e = s.applyPlacement(
        placedCells: 2,
        clearedLines: 2,
        clearedCells: 15,
        isAllClear: false,
      );
      // placement 2 + clear 15*10*2*1.0 = 302
      expect(e.gained, 302);
    });

    test('line multiplier is capped at max', () {
      final s = ScoreKeeper(feverPerLine: 0); // isolate from fever burst
      final e = s.applyPlacement(
        placedCells: 0,
        clearedLines: 6,
        clearedCells: 10,
        isAllClear: false,
      );
      // capped at x4: 10*10*4*1.0 = 400
      expect(e.gained, 400);
    });
  });

  group('combo', () {
    test('consecutive clears raise the combo multiplier', () {
      final s = ScoreKeeper(feverPerLine: 0);
      s.applyPlacement(
        placedCells: 0,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: false,
      );
      final e2 = s.applyPlacement(
        placedCells: 0,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: false,
      );
      expect(e2.combo, 2);
      // combo2 multiplier 1.5: 8*10*1*1.5 = 120
      expect(e2.gained, 120);
    });

    test('a move without a clear breaks the combo', () {
      final s = ScoreKeeper(feverPerLine: 0);
      s.applyPlacement(
        placedCells: 0,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: false,
      );
      final broken = s.applyPlacement(
        placedCells: 3,
        clearedLines: 0,
        clearedCells: 0,
        isAllClear: false,
      );
      expect(broken.combo, 0);
    });
  });

  group('fever', () {
    test('meter fills with cleared lines', () {
      final s = ScoreKeeper();
      final e = s.applyPlacement(
        placedCells: 0,
        clearedLines: 2,
        clearedCells: 15,
        isAllClear: false,
      );
      expect(e.feverLevel, closeTo(0.4, 1e-9));
      expect(e.feverBurst, isFalse);
    });

    test('full meter triggers a burst that doubles clear points and resets', () {
      final s = ScoreKeeper();
      // Fill meter to 0.8 first (4 lines across two moves would burst; use one
      // move of 4 lines = 0.8, then a 1-line move to reach 1.0).
      s.applyPlacement(
        placedCells: 0,
        clearedLines: 4,
        clearedCells: 10,
        isAllClear: false,
      ); // fever 0.8
      final burst = s.applyPlacement(
        placedCells: 0,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: false,
      );
      expect(burst.feverBurst, isTrue);
      expect(burst.feverLevel, 0.0); // reset after burst
      // combo is now 2 (both moves cleared). clear = 8*10*1*1.5 = 120, doubled.
      expect(burst.gained, 240);
    });

    test('meter decays on a move without a clear', () {
      final s = ScoreKeeper();
      s.applyPlacement(
        placedCells: 0,
        clearedLines: 2,
        clearedCells: 15,
        isAllClear: false,
      ); // fever 0.4
      final e = s.applyPlacement(
        placedCells: 1,
        clearedLines: 0,
        clearedCells: 0,
        isAllClear: false,
      );
      expect(e.feverLevel, closeTo(0.3, 1e-9));
    });
  });

  group('all clear', () {
    test('adds the all-clear bonus on top', () {
      final s = ScoreKeeper(feverPerLine: 0);
      final e = s.applyPlacement(
        placedCells: 1,
        clearedLines: 1,
        clearedCells: 8,
        isAllClear: true,
      );
      // 1 + 8*10*1*1.0 + 300 = 381
      expect(e.gained, 381);
    });
  });

  test('reset clears total, combo and fever', () {
    final s = ScoreKeeper();
    s.applyPlacement(
      placedCells: 4,
      clearedLines: 1,
      clearedCells: 8,
      isAllClear: false,
    );
    s.reset();
    expect(s.total, 0);
    expect(s.combo, 0);
    expect(s.feverLevel, 0.0);
  });
}
