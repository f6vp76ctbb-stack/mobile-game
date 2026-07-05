import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/game_session.dart';
import 'package:gridpop/game/missions.dart';

GameStats _stats({
  int score = 0,
  int piecesPlaced = 0,
  int linesCleared = 0,
  int maxCombo = 0,
}) {
  return GameStats(
    score: score,
    piecesPlaced: piecesPlaced,
    linesCleared: linesCleared,
    maxCombo: maxCombo,
  );
}

void main() {
  test('default missions have unique ids and positive targets/rewards', () {
    final missions = defaultMissions();
    expect(missions.map((m) => m.id).toSet().length, missions.length);
    for (final m in missions) {
      expect(m.target, greaterThan(0));
      expect(m.reward, greaterThan(0));
    }
  });

  group('cumulative metrics', () {
    test('pieces and lines accumulate across games', () {
      final e = MissionEngine();
      e.recordGame(_stats(piecesPlaced: 60, linesCleared: 20));
      e.recordGame(_stats(piecesPlaced: 60, linesCleared: 20));
      expect(e.progressOf('place_100'), 120);
      expect(e.progressOf('clear_50'), 40);
    });

    test('gamesPlayed increments once per recorded game', () {
      final e = MissionEngine();
      e.recordGame(_stats());
      e.recordGame(_stats());
      expect(e.progressOf('games_10'), 2);
    });
  });

  group('best-value metrics', () {
    test('maxCombo and score keep the best, not the sum', () {
      final e = MissionEngine();
      e.recordGame(_stats(maxCombo: 3, score: 800));
      e.recordGame(_stats(maxCombo: 2, score: 500));
      expect(e.progressOf('combo_5'), 3);
      expect(e.progressOf('score_1000'), 800);
    });
  });

  group('completion', () {
    test('returns a mission only on the run that completes it', () {
      final e = MissionEngine();
      final first = e.recordGame(_stats(piecesPlaced: 40));
      expect(first.any((m) => m.id == 'place_100'), isFalse);
      final second = e.recordGame(_stats(piecesPlaced: 70)); // total 110
      expect(second.any((m) => m.id == 'place_100'), isTrue);
      final third = e.recordGame(_stats(piecesPlaced: 70)); // already done
      expect(third.any((m) => m.id == 'place_100'), isFalse);
    });

    test('view reports fraction and completed flag', () {
      final e = MissionEngine();
      e.recordGame(_stats(linesCleared: 25));
      final view = e.views.firstWhere((v) => v.mission.id == 'clear_50');
      expect(view.fraction, closeTo(0.5, 1e-9));
      expect(view.completed, isFalse);
    });
  });

  test('engine can be restored from a persisted progress map', () {
    final e = MissionEngine(progress: {'place_100': 95});
    final completed = e.recordGame(_stats(piecesPlaced: 10)); // 105
    expect(completed.any((m) => m.id == 'place_100'), isTrue);
    expect(e.progress['place_100'], 105);
  });
}
