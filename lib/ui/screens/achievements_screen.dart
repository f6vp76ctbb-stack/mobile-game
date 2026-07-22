/// Achievements gallery: unlocked ones highlighted, locked ones show progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/achievements.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import '../widgets/app_icons.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageProvider);
    final life = storage.lifetimeStats;
    final progress = AchievementProgress(
      games: life.games,
      highscore: storage.highscore,
      totalLines: life.totalLines,
      bestCombo: life.bestCombo,
      level: storage.playerLevel,
      streak: storage.streak,
      puzzlesSolved: storage.puzzleStars.length,
      totalPieces: life.totalPieces,
    );
    final unlocked = storage.unlockedAchievements;
    final unlockedCount =
        Achievements.catalog.where((a) => unlocked.contains(a.id)).length;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Erfolge'),
        backgroundColor: GridColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Header(
            unlocked: unlockedCount,
            total: Achievements.catalog.length,
          ),
          const SizedBox(height: 12),
          for (final a in Achievements.catalog)
            _AchievementTile(
              achievement: a,
              done: unlocked.contains(a.id),
              value: progress.value(a.metric),
              fraction: Achievements.fraction(a, progress),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : unlocked / total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          GridColors.fever.withValues(alpha: 0.3),
          GridColors.boardBackground,
        ]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.trophy, size: 30, color: GridColors.fever),
              const SizedBox(width: 12),
              Text(
                '$unlocked / $total freigeschaltet',
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: GridColors.emptyCell,
              valueColor: const AlwaysStoppedAnimation(GridColors.fever),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.achievement,
    required this.done,
    required this.value,
    required this.fraction,
  });

  final Achievement achievement;
  final bool done;
  final int value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? GridColors.placed : GridColors.gridLine,
        ),
      ),
      child: Row(
        children: [
          Opacity(
            opacity: done ? 1.0 : 0.4,
            child: Text(achievement.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        achievement.title,
                        style: TextStyle(
                          color: done
                              ? GridColors.textPrimary
                              : GridColors.textMuted,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (done)
                      const Icon(Icons.check_circle,
                          color: GridColors.placed, size: 18),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: const TextStyle(
                      color: GridColors.textMuted, fontSize: 12),
                ),
                if (!done) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 5,
                      backgroundColor: GridColors.emptyCell,
                      valueColor:
                          AlwaysStoppedAnimation(GridColors.traySlots[0]),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$value / ${achievement.threshold}',
                    style: const TextStyle(
                        color: GridColors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
