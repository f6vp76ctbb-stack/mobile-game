/// Home screen: title, best score, coins, and entry into endless / daily.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/leveling.dart';
import '../../game/piggy_bank.dart';
import '../../game/streak.dart';
import '../../monetization/iap.dart';
import '../state/game_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/menu_particles.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';
import 'missions_screen.dart';
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

  /// Lets the player rename themselves (leaderboard identity).
  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: GridColors.boardBackground,
        title: const Text('Dein Name',
            style: TextStyle(color: GridColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 14,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: GridColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    if (name != null && name.length >= 2) {
      await ref.read(gameControllerProvider.notifier).setPlayerName(name);
    }
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
      body: Stack(
        children: [
          // Subtle drifting particles behind everything.
          Positioned.fill(
            child: MenuParticles(colors: ref.watch(activeThemeProvider).traySlots),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
          // Scrolls when the content is taller than the screen (small phones,
          // landscape), while the Spacers still center it when there's room.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
              const Spacer(flex: 2),
              // Compact brand + profile (deliberately understated).
              const Text(
                'Qubble',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _editName(context, ref, snap.playerName),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person,
                        size: 13, color: GridColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      snap.playerName,
                      style: const TextStyle(
                        color: GridColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.edit,
                        size: 12, color: GridColors.textMuted),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              // Prominent best score, right above the play button.
              const Text(
                'BESTWERT',
                style: TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${snap.highscore}',
                style: const TextStyle(
                  color: GridColors.placed,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 12),
              _LevelBadge(
                level: snap.playerLevel,
                xp: snap.xpIntoLevel,
                xpForNext: snap.xpForNextLevel,
              ),
              if (snap.weekendActive) ...[
                const SizedBox(height: 12),
                const _WeekendBanner(),
              ],
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
              Row(
                children: [
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.emoji_events_outlined,
                      label: 'Bestenliste',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LeaderboardScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SecondaryButton(
                      icon: Icons.extension_outlined,
                      label: 'Rätsel-Modus',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PuzzleLevelsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
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
            ),
          ),
              ),
            ),
          ],
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
          if (LevelSystem.nextReward(level) case final next?) ...[
            const SizedBox(height: 6),
            Text(
              '${next.kind == LevelRewardKind.theme ? '🎨' : '🧊'} '
              'Level ${next.level}: ${next.name}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GridColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
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
    // Vertical layout (icon over label) so narrow half-width buttons never
    // wrap the text; the label scales down to fit if needed.
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        foregroundColor: GridColors.textPrimary,
        side: const BorderSide(color: GridColors.gridLine),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
