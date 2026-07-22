/// Lifetime statistics overview — a visual dashboard rather than a number grid.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/achievements.dart';
import '../../game/leveling.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import '../widgets/app_icons.dart';
import 'achievements_screen.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageProvider);
    final stats = storage.lifetimeStats;
    final puzzleStars = storage.puzzleStars;
    final puzzlesSolved = puzzleStars.length;
    final totalStars = puzzleStars.values.fold(0, (a, b) => a + b);

    final level = storage.playerLevel;
    final xp = storage.xp;
    final xpForNext = LevelSystem.xpForNext(level);

    final cards = <_StatData>[
      _StatData(Icons.casino_outlined, GridColors.traySlots[0],
          'Runden', '${stats.games}'),
      _StatData(Icons.trending_up, GridColors.placed, 'Ø Punkte',
          '${stats.averageScore}'),
      _StatData(Icons.bolt, GridColors.fever, 'Größte Combo',
          '${max(stats.bestCombo, 0)}'),
      _StatData(Icons.grid_on, GridColors.traySlots[1 % GridColors.traySlots.length],
          'Reihen geräumt', '${stats.totalLines}'),
      _StatData(Icons.extension, GridColors.traySlots[2 % GridColors.traySlots.length],
          'Teile platziert', '${stats.totalPieces}'),
      _StatData(Icons.paid_outlined, GridColors.fever, 'Münzen',
          '${storage.coins}'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
        backgroundColor: GridColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HeroCard(
            highscore: storage.highscore,
            level: level,
            xp: xp,
            xpForNext: xpForNext,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [for (final c in cards) _StatCard(data: c)],
          ),
          const SizedBox(height: 16),
          _PuzzleCard(solved: puzzlesSolved, stars: totalStars),
          const SizedBox(height: 16),
          _AchievementsLink(
            unlocked: storage.unlockedAchievements.length,
            total: Achievements.catalog.length,
          ),
        ],
      ),
    );
  }
}

class _AchievementsLink extends StatelessWidget {
  const _AchievementsLink({required this.unlocked, required this.total});

  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.gridLine),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.trophy, size: 24, color: GridColors.fever),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Erfolge',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            Text('$unlocked / $total',
                style: const TextStyle(
                    color: GridColors.textMuted, fontSize: 14)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: GridColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.highscore,
    required this.level,
    required this.xp,
    required this.xpForNext,
  });

  final int highscore;
  final int level;
  final int xp;
  final int xpForNext;

  @override
  Widget build(BuildContext context) {
    final progress = xpForNext == 0 ? 0.0 : (xp / xpForNext).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GridColors.placed.withValues(alpha: 0.35),
            GridColors.boardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(AppIcons.trophy, size: 34, color: GridColors.fever),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('BESTWERT',
                      style: TextStyle(
                        color: GridColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      )),
                  Text('$highscore',
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $level',
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  )),
              Text('$xp / $xpForNext XP',
                  style: const TextStyle(
                      color: GridColors.textMuted, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: GridColors.emptyCell,
              valueColor: AlwaysStoppedAnimation(GridColors.traySlots[0]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.icon, this.color, this.label, this.value);
  final IconData icon;
  final Color color;
  final String label;
  final String value;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: GridColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PuzzleCard extends StatelessWidget {
  const _PuzzleCard({required this.solved, required this.stars});

  final int solved;
  final int stars;

  @override
  Widget build(BuildContext context) {
    // Up to 3 stars per solved level.
    final maxStars = solved * 3;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.extension_outlined,
                  color: GridColors.placed, size: 20),
              const SizedBox(width: 8),
              const Text('Rätsel-Modus',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  )),
              const Spacer(),
              Text('$solved gelöst',
                  style: const TextStyle(
                      color: GridColors.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 22, color: GridColors.fever),
              const SizedBox(width: 8),
              Text('$stars',
                  style: const TextStyle(
                    color: GridColors.fever,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  )),
              if (maxStars > 0) ...[
                const SizedBox(width: 4),
                Text('/ $maxStars',
                    style: const TextStyle(
                        color: GridColors.textMuted, fontSize: 14)),
              ],
            ],
          ),
          if (maxStars > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (stars / maxStars).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: GridColors.emptyCell,
                valueColor: const AlwaysStoppedAnimation(GridColors.fever),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
