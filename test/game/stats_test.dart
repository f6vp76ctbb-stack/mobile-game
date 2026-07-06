import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/stats.dart';

GameStats _run({
  int score = 0,
  int pieces = 0,
  int lines = 0,
  int combo = 0,
}) {
  return GameStats(
    score: score,
    piecesPlaced: pieces,
    linesCleared: lines,
    maxCombo: combo,
  );
}

void main() {
  test('empty stats have zero average', () {
    const s = LifetimeStats();
    expect(s.averageScore, 0);
    expect(s.games, 0);
  });

  test('merge accumulates totals and keeps the best combo', () {
    var s = const LifetimeStats();
    s = s.merge(_run(score: 300, pieces: 40, lines: 12, combo: 3));
    s = s.merge(_run(score: 100, pieces: 20, lines: 5, combo: 5));
    s = s.merge(_run(score: 200, pieces: 30, lines: 8, combo: 2));

    expect(s.games, 3);
    expect(s.totalScore, 600);
    expect(s.totalLines, 25);
    expect(s.totalPieces, 90);
    expect(s.bestCombo, 5);
    expect(s.averageScore, 200); // 600 / 3
  });

  test('json round-trips', () {
    final s = const LifetimeStats().merge(_run(score: 150, lines: 4, combo: 2));
    final restored = LifetimeStats.fromJson(s.toJson());
    expect(restored.games, s.games);
    expect(restored.totalScore, s.totalScore);
    expect(restored.bestCombo, s.bestCombo);
  });

  test('fromJson tolerates missing keys', () {
    final s = LifetimeStats.fromJson(const {'games': 2});
    expect(s.games, 2);
    expect(s.totalScore, 0);
  });
}
