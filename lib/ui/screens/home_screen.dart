/// Home screen: title, best score, coins, and entry into endless / daily.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/piggy_bank.dart';
import '../../game/streak.dart';
import '../../monetization/iap.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import 'game_screen.dart';
import 'missions_screen.dart';
import 'profiles_screen.dart';
import 'puzzle_levels_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'skins_screen.dart';
import 'stats_screen.dart';
import 'themes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const GameScreen()),
    );
  }

  void _handlePiggy(BuildContext context, WidgetRef ref, int coins) {
    if (coins <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Das Sparschwein füllt sich, während du Reihen räumst.',
          ),
        ),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: const Text(
          'Sparschwein öffnen?',
          style: TextStyle(color: GridColors.textPrimary),
        ),
        content: Text(
          'Hol dir 🪙 $coins Münzen für 2,99 €.',
          style: const TextStyle(color: GridColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(iapServiceProvider).buy(IapProducts.piggy);
            },
            child: const Text('Öffnen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shopping_bag_outlined,
                          color: GridColors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ShopScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.bar_chart,
                          color: GridColors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StatsScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: GridColors.textPrimary,
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.people_outline,
                          color: GridColors.textPrimary,
                        ),
                        tooltip: 'Profile',
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfilesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _PiggyChip(
                        coins: snap.piggyCoins,
                        capacity: snap.piggyCapacity,
                        onTap: () => _handlePiggy(context, ref, snap.piggyCoins),
                      ),
                      const SizedBox(width: 10),
                      _CoinPill(coins: snap.coins),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Qubble',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Block Puzzle',
                style: TextStyle(color: GridColors.textMuted, fontSize: 18),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfilesScreen(),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person,
                        size: 16, color: GridColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      snap.profileName,
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(Icons.expand_more,
                        size: 16, color: GridColors.textMuted),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bestwert: ${snap.highscore}',
                style: const TextStyle(
                  color: GridColors.placed,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _LevelBadge(
                level: snap.playerLevel,
                xp: snap.xpIntoLevel,
                xpForNext: snap.xpForNextLevel,
              ),
              if (snap.weekendActive) ...[
                const SizedBox(height: 14),
                const _WeekendBanner(),
              ],
              const Spacer(),
              _PrimaryButton(
                // A running game resumes instead of silently restarting.
                label: snap.runActive ? 'Weiterspielen' : 'Spielen',
                onPressed: () {
                  ref.read(musicProvider).ensureStarted();
                  if (!snap.runActive) controller.newGame();
                  _openGame(context);
                },
              ),
              if (snap.runActive)
                TextButton(
                  onPressed: () {
                    ref.read(musicProvider).ensureStarted();
                    controller.newGame();
                    _openGame(context);
                  },
                  child: const Text(
                    'Neue Runde starten',
                    style: TextStyle(color: GridColors.textMuted),
                  ),
                ),
              const SizedBox(height: 14),
              if (snap.streakRepairAvailable) ...[
                _StreakRepairBanner(streak: snap.streak),
                const SizedBox(height: 14),
              ],
              _DailyCard(
                streak: snap.streak,
                onPlay: () {
                  ref.read(musicProvider).ensureStarted();
                  controller.startDaily();
                  _openGame(context);
                },
              ),
              const SizedBox(height: 14),
              _SecondaryButton(
                icon: Icons.extension_outlined,
                label: 'Rätsel-Modus',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PuzzleLevelsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.flag_outlined,
                      label: 'Missionen',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MissionsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.palette_outlined,
                      label: 'Themes',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ThemesScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.grid_view,
                      label: 'Skins',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SkinsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(58),
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

class _PiggyChip extends StatelessWidget {
  const _PiggyChip({
    required this.coins,
    required this.capacity,
    required this.onTap,
  });

  final int coins;
  final int capacity;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final piggy = PiggyBank(coins: coins, capacity: capacity);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(20),
          border: piggy.showHint
              ? Border.all(color: GridColors.fever)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐷', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 5),
            Text(
              '$coins',
              style: TextStyle(
                color: piggy.showHint
                    ? GridColors.fever
                    : GridColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekendBanner extends StatelessWidget {
  const _WeekendBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GridColors.fever.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: GridColors.fever),
      ),
      child: const Text(
        '🎉 Wochenende: doppelte Münzen!',
        style: TextStyle(
          color: GridColors.fever,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({
    required this.level,
    required this.xp,
    required this.xpForNext,
  });

  final int level;
  final int xp;
  final int xpForNext;

  @override
  Widget build(BuildContext context) {
    final progress = xpForNext == 0 ? 0.0 : (xp / xpForNext).clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Level $level',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$xp / $xpForNext XP',
                style: const TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: GridColors.emptyCell,
              valueColor: AlwaysStoppedAnimation(GridColors.traySlots[0]),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRepairBanner extends ConsumerWidget {
  const _StreakRepairBanner({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);

    Future<void> repair(Future<bool> action) async {
      final ok = await action;
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reparatur nicht möglich')),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GridColors.boardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GridColors.fever),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 $streak-Tage-Streak in Gefahr!',
            style: const TextStyle(
              color: GridColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Du hast gestern ausgesetzt — rette deinen Streak:',
            style: TextStyle(color: GridColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => repair(controller.repairStreakWithAd()),
                  child: const Text('▶ Video'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => repair(controller.repairStreakWithCoins()),
                  child: Text('🪙 ${StreakRepair.coinCost}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: GridColors.textPrimary,
        side: const BorderSide(color: GridColors.gridLine),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.streak, required this.onPlay});

  final int streak;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.traySlots[0]),
        ),
        child: Row(
          children: [
            const Icon(Icons.today, color: GridColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tägliche Challenge',
                    style: TextStyle(
                      color: GridColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    streak > 0 ? '🔥 $streak Tage Streak' : 'Heute noch offen',
                    style: const TextStyle(
                      color: GridColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_arrow, color: GridColors.placed),
          ],
        ),
      ),
    );
  }
}
