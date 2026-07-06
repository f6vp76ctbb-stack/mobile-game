/// The main play screen: score header, board, tray and game-over overlay.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/clear_burst.dart';
import '../widgets/tray_view.dart';

/// True while the player is choosing a target cell for the Board Bomb booster.
final bombModeProvider = StateProvider<bool>((ref) => false);

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(gameControllerProvider);
    final theme = ref.watch(activeThemeProvider);
    final bombMode = ref.watch(bombModeProvider);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _Header(
                  score: snap.score,
                  highscore: snap.highscore,
                  combo: snap.combo,
                  fever: snap.feverLevel,
                  isDaily: snap.isDaily,
                  feverColor: theme.fever,
                ),
                if (!snap.gameOver)
                  TextButton.icon(
                    onPressed: () =>
                        ref.read(gameControllerProvider.notifier).luckyBlock(),
                    icon: const Icon(Icons.card_giftcard, size: 18),
                    label: const Text('Neue Teile (Video)'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.fever,
                    ),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const trayHeight = 96.0;
                      const gap = 16.0;
                      const boosterHeight = 64.0;
                      final hintReserve = snap.onboardingHint != null ? 52.0 : 0.0;
                      final maxBoard = constraints.maxWidth - 24;
                      final boardSize = maxBoard.clamp(
                        0.0,
                        constraints.maxHeight -
                            trayHeight -
                            boosterHeight -
                            gap -
                            hintReserve -
                            2,
                      );
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _FeverGlow(
                            fever: snap.feverLevel,
                            color: theme.fever,
                            child: SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: Stack(
                                children: [
                                  BoardView(
                                    size: boardSize,
                                    onCellTap: bombMode
                                        ? (cell) async {
                                            await ref
                                                .read(gameControllerProvider
                                                    .notifier)
                                                .tryBomb(cell);
                                            ref
                                                .read(bombModeProvider.notifier)
                                                .state = false;
                                          }
                                        : null,
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: ClearBurst(
                                        size: boardSize,
                                        cellSize: boardSize / 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: gap),
                          _BoosterBar(snap: snap, bombMode: bombMode),
                          if (snap.onboardingHint != null)
                            _CoachHint(text: snap.onboardingHint!),
                          TrayView(
                            boardCell: boardSize / 8,
                            height: trayHeight,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            if (snap.gameOver) _GameOverOverlay(snap: snap),
          ],
        ),
      ),
    );
  }
}

/// A soft glow around the board that intensifies with the fever meter.
class _FeverGlow extends StatelessWidget {
  const _FeverGlow({
    required this.fever,
    required this.color,
    required this.child,
  });

  final double fever;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final f = fever.clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (f > 0)
            BoxShadow(
              color: color.withValues(alpha: f * 0.6),
              blurRadius: f * 34,
              spreadRadius: f * 4,
            ),
        ],
      ),
      child: child,
    );
  }
}

/// The in-run booster bar: undo, swap pieces, board bomb.
class _BoosterBar extends ConsumerWidget {
  const _BoosterBar({required this.snap, required this.bombMode});

  final GameSnapshot snap;
  final bool bombMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);

    Future<void> run(Future<bool> action) async {
      final ok = await action;
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 1),
            content: Text('Nicht möglich (zu wenig Münzen?)'),
          ),
        );
      }
    }

    return SizedBox(
      height: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BoosterButton(
            icon: Icons.undo,
            label: 'Undo',
            cost: BoosterCosts.undo,
            enabled: snap.canUndo && !snap.gameOver,
            active: false,
            onTap: () => run(controller.tryUndo()),
          ),
          _BoosterButton(
            icon: Icons.autorenew,
            label: 'Tausch',
            cost: BoosterCosts.swap,
            enabled: !snap.gameOver,
            active: false,
            onTap: () => run(controller.trySwapPieces()),
          ),
          _BoosterButton(
            icon: Icons.blur_circular,
            label: 'Bombe',
            cost: BoosterCosts.bomb,
            enabled: !snap.gameOver,
            active: bombMode,
            onTap: () {
              final notifier = ref.read(bombModeProvider.notifier);
              notifier.state = !notifier.state;
            },
          ),
        ],
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.icon,
    required this.label,
    required this.cost,
    required this.enabled,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int cost;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? GridColors.fever
        : enabled
            ? GridColors.textPrimary
            : GridColors.textMuted;
    return Expanded(
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
              Text(
                '🪙$cost',
                style: const TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small pulsing coach banner used during the first-run guided moves.
class _CoachHint extends StatelessWidget {
  const _CoachHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GridColors.gridLine),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: GridColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.score,
    required this.highscore,
    required this.combo,
    required this.fever,
    required this.isDaily,
    required this.feverColor,
  });

  final int score;
  final int highscore;
  final int combo;
  final double fever;
  final bool isDaily;
  final Color feverColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Column(
        children: [
          if (isDaily)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                'TÄGLICHE CHALLENGE',
                style: TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat('PUNKTE', '$score'),
              if (combo > 1) _ComboBadge(combo: combo, color: feverColor),
              _stat('BEST', '$highscore', alignEnd: true),
            ],
          ),
          const SizedBox(height: 10),
          _FeverBar(level: fever, color: feverColor),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: GridColors.textMuted, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(
            color: GridColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Combo indicator that pulses each time the combo count changes.
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({required this.combo, required this.color});

  final int combo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(combo),
      tween: Tween(begin: 1.35, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Text(
        'COMBO x$combo',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _FeverBar extends StatelessWidget {
  const _FeverBar({required this.level, required this.color});

  final double level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: level.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: GridColors.emptyCell,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _GameOverOverlay extends ConsumerWidget {
  const _GameOverOverlay({required this.snap});

  final GameSnapshot snap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${snap.score} Punkte',
              style:
                  const TextStyle(color: GridColors.textPrimary, fontSize: 22),
            ),
            if (snap.isNewHighscore)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Neuer Rekord! 🎉',
                  style: TextStyle(color: GridColors.fever, fontSize: 16),
                ),
              ),
            if (snap.isDaily && snap.streak > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🔥 ${snap.streak} Tage Streak',
                  style: const TextStyle(
                    color: GridColors.fever,
                    fontSize: 16,
                  ),
                ),
              ),
            if (snap.coinsEarnedThisRun > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '🪙 +${snap.coinsEarnedThisRun} Münzen'
                  '${snap.coinsDoubled ? ' (x2)' : ''}',
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ),
            if (snap.coinsEarnedThisRun > 0 && !snap.coinsDoubled)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: GridColors.fever,
                    foregroundColor: GridColors.background,
                  ),
                  onPressed: () => controller.doubleCoinsWithAd(),
                  child: const Text('▶  Münzen verdoppeln'),
                ),
              ),
            for (final mission in snap.completedMissions)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '✓ $mission',
                  style: const TextStyle(
                    color: GridColors.placed,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 28),
            // Rewarded revive — always voluntary, always grants the reward.
            FilledButton.tonal(
              onPressed: () => controller.reviveWithAd(),
              child: const Text('▶  Weiterspielen (Video ansehen)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => controller.newGameWithInterstitial(),
              child: const Text('Nochmal'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Hauptmenü'),
            ),
          ],
        ),
      ),
    );
  }
}
