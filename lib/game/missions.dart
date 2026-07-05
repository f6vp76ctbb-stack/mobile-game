/// Pure-Dart mission system for GridPop. No Flutter imports.
///
/// Missions are cumulative "career" goals that reward coins, driving the coin
/// economy (MASTERPLAN.md §4). Progress is a plain id->value map so it can be
/// persisted as JSON without extra machinery.
library;

import 'dart:math' as math;

import 'game_session.dart';

enum MissionMetric {
  piecesPlaced,
  linesCleared,
  maxComboReached,
  scoreReached,
  gamesPlayed,
}

class Mission {
  const Mission({
    required this.id,
    required this.description,
    required this.metric,
    required this.target,
    required this.reward,
  });

  final String id;
  final String description;
  final MissionMetric metric;
  final int target;
  final int reward;
}

/// A mission plus the player's current progress toward it.
class MissionView {
  const MissionView({required this.mission, required this.progress});

  final Mission mission;
  final int progress;

  bool get completed => progress >= mission.target;
  double get fraction =>
      mission.target == 0 ? 1.0 : (progress / mission.target).clamp(0.0, 1.0);
}

/// The default career mission set (German user-facing text).
List<Mission> defaultMissions() => const [
      Mission(
        id: 'place_100',
        description: 'Platziere 100 Teile',
        metric: MissionMetric.piecesPlaced,
        target: 100,
        reward: 30,
      ),
      Mission(
        id: 'clear_50',
        description: 'Räume 50 Reihen ab',
        metric: MissionMetric.linesCleared,
        target: 50,
        reward: 40,
      ),
      Mission(
        id: 'combo_5',
        description: 'Erreiche eine 5er-Combo',
        metric: MissionMetric.maxComboReached,
        target: 5,
        reward: 50,
      ),
      Mission(
        id: 'score_1000',
        description: 'Knacke 1000 Punkte in einer Runde',
        metric: MissionMetric.scoreReached,
        target: 1000,
        reward: 50,
      ),
      Mission(
        id: 'games_10',
        description: 'Spiele 10 Runden',
        metric: MissionMetric.gamesPlayed,
        target: 10,
        reward: 25,
      ),
    ];

class MissionEngine {
  MissionEngine({List<Mission>? missions, Map<String, int>? progress})
      : missions = missions ?? defaultMissions(),
        _progress = {...?progress};

  final List<Mission> missions;
  final Map<String, int> _progress;

  Map<String, int> get progress => Map.unmodifiable(_progress);

  int progressOf(String id) => _progress[id] ?? 0;

  List<MissionView> get views => [
        for (final m in missions)
          MissionView(mission: m, progress: progressOf(m.id)),
      ];

  int _apply(MissionMetric metric, int current, GameStats s) {
    switch (metric) {
      case MissionMetric.piecesPlaced:
        return current + s.piecesPlaced;
      case MissionMetric.linesCleared:
        return current + s.linesCleared;
      case MissionMetric.gamesPlayed:
        return current + 1;
      case MissionMetric.maxComboReached:
        return math.max(current, s.maxCombo);
      case MissionMetric.scoreReached:
        return math.max(current, s.score);
    }
  }

  /// Folds a finished run's [stats] into progress and returns the missions that
  /// became complete on this run (for coin rewards). Already-complete missions
  /// never re-trigger.
  List<Mission> recordGame(GameStats stats) {
    final newlyCompleted = <Mission>[];
    for (final m in missions) {
      final before = progressOf(m.id);
      final wasComplete = before >= m.target;
      final after = _apply(m.metric, before, stats);
      _progress[m.id] = after;
      if (!wasComplete && after >= m.target) newlyCompleted.add(m);
    }
    return newlyCompleted;
  }
}
