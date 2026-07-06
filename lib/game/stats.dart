/// Pure-Dart lifetime statistics (MASTERPLAN.md Tier 2). No Flutter imports.
///
/// Aggregated across all runs; folded from per-run [GameStats] at game over.
library;

import 'game_session.dart';

class LifetimeStats {
  const LifetimeStats({
    this.games = 0,
    this.totalScore = 0,
    this.totalLines = 0,
    this.totalPieces = 0,
    this.bestCombo = 0,
  });

  final int games;
  final int totalScore;
  final int totalLines;
  final int totalPieces;
  final int bestCombo;

  int get averageScore => games == 0 ? 0 : totalScore ~/ games;

  /// Returns a new aggregate with [run] folded in.
  LifetimeStats merge(GameStats run) {
    return LifetimeStats(
      games: games + 1,
      totalScore: totalScore + run.score,
      totalLines: totalLines + run.linesCleared,
      totalPieces: totalPieces + run.piecesPlaced,
      bestCombo: run.maxCombo > bestCombo ? run.maxCombo : bestCombo,
    );
  }

  Map<String, int> toJson() => {
        'games': games,
        'totalScore': totalScore,
        'totalLines': totalLines,
        'totalPieces': totalPieces,
        'bestCombo': bestCombo,
      };

  factory LifetimeStats.fromJson(Map<String, dynamic> json) {
    int v(String k) => (json[k] as num?)?.toInt() ?? 0;
    return LifetimeStats(
      games: v('games'),
      totalScore: v('totalScore'),
      totalLines: v('totalLines'),
      totalPieces: v('totalPieces'),
      bestCombo: v('bestCombo'),
    );
  }
}
