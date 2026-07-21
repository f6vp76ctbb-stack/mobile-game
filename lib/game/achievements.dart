/// Pure-Dart achievements. No Flutter imports.
///
/// Each achievement unlocks when a single tracked metric reaches its
/// threshold. Evaluation is a pure function of the player's aggregate progress,
/// so it's fully deterministic and unit-testable. Unlock state is persisted
/// separately (see Storage); newly-unlocked achievements are the set-difference
/// between a fresh evaluation and what was already stored.
library;

enum AchievementMetric {
  games,
  highscore,
  totalLines,
  bestCombo,
  level,
  streak,
  puzzlesSolved,
  totalPieces,
}

class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.metric,
    required this.threshold,
  });

  final String id;

  /// Emoji shown in the UI (kept as a string so this stays Flutter-free).
  final String icon;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int threshold;
}

/// A snapshot of the metrics achievements are evaluated against.
class AchievementProgress {
  const AchievementProgress({
    this.games = 0,
    this.highscore = 0,
    this.totalLines = 0,
    this.bestCombo = 0,
    this.level = 1,
    this.streak = 0,
    this.puzzlesSolved = 0,
    this.totalPieces = 0,
  });

  final int games;
  final int highscore;
  final int totalLines;
  final int bestCombo;
  final int level;
  final int streak;
  final int puzzlesSolved;
  final int totalPieces;

  int value(AchievementMetric m) => switch (m) {
        AchievementMetric.games => games,
        AchievementMetric.highscore => highscore,
        AchievementMetric.totalLines => totalLines,
        AchievementMetric.bestCombo => bestCombo,
        AchievementMetric.level => level,
        AchievementMetric.streak => streak,
        AchievementMetric.puzzlesSolved => puzzlesSolved,
        AchievementMetric.totalPieces => totalPieces,
      };
}

class Achievements {
  const Achievements._();

  /// The full catalog, grouped loosely by metric and ascending threshold.
  static const List<Achievement> catalog = [
    // Playing
    Achievement(
        id: 'first_game',
        icon: '🎮',
        title: 'Erste Runde',
        description: 'Spiele deine erste Runde',
        metric: AchievementMetric.games,
        threshold: 1),
    Achievement(
        id: 'games_25',
        icon: '🕹️',
        title: 'Stammspieler',
        description: 'Spiele 25 Runden',
        metric: AchievementMetric.games,
        threshold: 25),
    Achievement(
        id: 'games_100',
        icon: '👑',
        title: 'Süchtig',
        description: 'Spiele 100 Runden',
        metric: AchievementMetric.games,
        threshold: 100),
    // Score
    Achievement(
        id: 'score_1k',
        icon: '🥉',
        title: 'Aufsteiger',
        description: 'Erreiche 1.000 Punkte',
        metric: AchievementMetric.highscore,
        threshold: 1000),
    Achievement(
        id: 'score_5k',
        icon: '🥈',
        title: 'Profi',
        description: 'Erreiche 5.000 Punkte',
        metric: AchievementMetric.highscore,
        threshold: 5000),
    Achievement(
        id: 'score_10k',
        icon: '🥇',
        title: 'Meister',
        description: 'Erreiche 10.000 Punkte',
        metric: AchievementMetric.highscore,
        threshold: 10000),
    Achievement(
        id: 'score_25k',
        icon: '🏆',
        title: 'Legende',
        description: 'Erreiche 25.000 Punkte',
        metric: AchievementMetric.highscore,
        threshold: 25000),
    // Lines
    Achievement(
        id: 'lines_100',
        icon: '✨',
        title: 'Aufräumer',
        description: 'Räume insgesamt 100 Reihen',
        metric: AchievementMetric.totalLines,
        threshold: 100),
    Achievement(
        id: 'lines_1000',
        icon: '🧹',
        title: 'Putzteufel',
        description: 'Räume insgesamt 1.000 Reihen',
        metric: AchievementMetric.totalLines,
        threshold: 1000),
    // Combo
    Achievement(
        id: 'combo_5',
        icon: '🔥',
        title: 'Combo-Starter',
        description: 'Erreiche eine 5er-Combo',
        metric: AchievementMetric.bestCombo,
        threshold: 5),
    Achievement(
        id: 'combo_10',
        icon: '💥',
        title: 'Combo-König',
        description: 'Erreiche eine 10er-Combo',
        metric: AchievementMetric.bestCombo,
        threshold: 10),
    // Level
    Achievement(
        id: 'level_10',
        icon: '⭐',
        title: 'Erfahren',
        description: 'Erreiche Level 10',
        metric: AchievementMetric.level,
        threshold: 10),
    Achievement(
        id: 'level_20',
        icon: '🌟',
        title: 'Veteran',
        description: 'Erreiche Level 20',
        metric: AchievementMetric.level,
        threshold: 20),
    // Streak
    Achievement(
        id: 'streak_7',
        icon: '📅',
        title: 'Wochenstreak',
        description: '7 Tage Daily-Streak',
        metric: AchievementMetric.streak,
        threshold: 7),
    Achievement(
        id: 'streak_30',
        icon: '🗓️',
        title: 'Monatsstreak',
        description: '30 Tage Daily-Streak',
        metric: AchievementMetric.streak,
        threshold: 30),
    // Puzzles
    Achievement(
        id: 'puzzles_10',
        icon: '🧩',
        title: 'Knobler',
        description: 'Löse 10 Rätsel',
        metric: AchievementMetric.puzzlesSolved,
        threshold: 10),
    // Pieces
    Achievement(
        id: 'pieces_5000',
        icon: '🧱',
        title: 'Baumeister',
        description: 'Platziere 5.000 Teile',
        metric: AchievementMetric.totalPieces,
        threshold: 5000),
  ];

  static Achievement byId(String id) =>
      catalog.firstWhere((a) => a.id == id);

  /// Ids currently satisfied by [p].
  static Set<String> unlockedFor(AchievementProgress p) => {
        for (final a in catalog)
          if (p.value(a.metric) >= a.threshold) a.id,
      };

  /// Progress toward [a] in the range 0..1.
  static double fraction(Achievement a, AchievementProgress p) =>
      (p.value(a.metric) / a.threshold).clamp(0.0, 1.0);

  /// Achievements newly satisfied by [p] that aren't in [already].
  static List<Achievement> newlyUnlocked(
    AchievementProgress p,
    Set<String> already,
  ) =>
      [
        for (final a in catalog)
          if (!already.contains(a.id) && p.value(a.metric) >= a.threshold) a,
      ];
}
