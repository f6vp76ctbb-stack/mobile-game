/// The main play screen: score header, board, tray and game-over overlay.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/leveling.dart';
import '../../game/piece.dart';
import '../../monetization/iap.dart';
import '../state/game_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/board_view.dart';
import '../widgets/clear_burst.dart';
import '../widgets/coin_popup.dart';
import '../widgets/juice_overlay.dart';
import '../widgets/shake.dart';
import '../widgets/tray_view.dart';

/// True while the player is choosing a target cell for the Board Bomb booster.
final bombModeProvider = StateProvider<bool>((ref) => false);

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Attached to the board container; maps global drag positions to cells.
  final GlobalKey _boardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Entering the game is always a user gesture, so the music may start here
    // (satisfies web/PWA autoplay policies).
    ref.read(musicProvider).ensureStarted();
  }

  void _updateDragPreview(int slot, Offset feedbackTopLeft) {
    final piece = ref.read(gameControllerProvider).tray[slot];
    final notifier = ref.read(dragPreviewProvider.notifier);
    if (piece == null) {
      notifier.state = null;
      return;
    }
    final origin = boardOriginForDrag(
      boardKey: _boardKey,
      piece: piece,
      feedbackTopLeft: feedbackTopLeft,
    );
    if (origin == null) {
      notifier.state = null;
      return;
    }
    final valid =
        ref.read(gameControllerProvider.notifier).canPlace(slot, origin);
    notifier.state = DragPreview(piece: piece, origin: origin, valid: valid);
  }

  void _handleDrop(int slot, Offset feedbackTopLeft) {
    final piece = ref.read(gameControllerProvider).tray[slot];
    if (piece != null) {
      final origin = boardOriginForDrag(
        boardKey: _boardKey,
        piece: piece,
        feedbackTopLeft: feedbackTopLeft,
      );
      if (origin != null) {
        ref.read(gameControllerProvider.notifier).place(slot, origin);
      }
    }
    ref.read(dragPreviewProvider.notifier).state = null;
  }

  Future<void> _handleBombTap(Cell cell) async {
    final ok =
        await ref.read(gameControllerProvider.notifier).tryBomb(cell);
    ref.read(bombModeProvider.notifier).state = false;
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 1),
          content: Text('Nicht genug Münzen für die Bombe'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  coins: snap.coins,
                  combo: snap.combo,
                  comboEndsAt: snap.comboEndsAt,
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
                      final hintReserve =
                          (snap.onboardingHint != null || bombMode)
                              ? 52.0
                              : 0.0;
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
                      // The DragTarget spans board AND tray: with the
                      // finger-lift the finger sits below the hovering piece,
                      // so drops targeting the bottom rows happen while the
                      // finger is over the booster/tray area.
                      return DragTarget<int>(
                        onMove: (d) => _updateDragPreview(d.data, d.offset),
                        onLeave: (_) =>
                            ref.read(dragPreviewProvider.notifier).state = null,
                        onAcceptWithDetails: (d) =>
                            _handleDrop(d.data, d.offset),
                        builder: (context, _, _) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Shake(
                              trigger: snap.clearEventId,
                              enabled: snap.lastClearedLineCount >= 3,
                              child: _FeverGlow(
                                fever: snap.feverLevel,
                                color: theme.fever,
                                child: SizedBox(
                                  width: boardSize,
                                  height: boardSize,
                                  child: Stack(
                                    children: [
                                      BoardView(
                                        size: boardSize,
                                        board: snap.board,
                                        boardKey: _boardKey,
                                        onCellTap:
                                            bombMode ? _handleBombTap : null,
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: ClearBurst(
                                            size: boardSize,
                                            cellSize: boardSize / 8,
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: JuiceOverlay(
                                            size: boardSize,
                                            cellSize: boardSize / 8,
                                          ),
                                        ),
                                      ),
                                      CoinPopup(size: boardSize),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: gap),
                            _BoosterBar(snap: snap, bombMode: bombMode),
                            if (bombMode)
                              const _CoachHint(
                                  text: '💣 Tippe auf eine Zelle im Board')
                            else if (snap.onboardingHint != null)
                              _CoachHint(text: snap.onboardingHint!),
                            TrayView(
                              boardCell: boardSize / 8,
                              height: trayHeight,
                            ),
                          ],
                        ),
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

/// Compact live coin balance shown in the game header; pulses when it grows.
class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(coins),
      tween: Tween(begin: 1.18, end: 1.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: GridColors.boardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.gridLine),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🪙', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 5),
            Text(
              '$coins',
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
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
            sub: '🪙${BoosterCosts.undo}',
            enabled: snap.canUndo &&
                !snap.gameOver &&
                snap.coins >= BoosterCosts.undo,
            active: false,
            onTap: () => run(controller.tryUndo()),
          ),
          _BoosterButton(
            icon: Icons.autorenew,
            label: 'Tausch',
            sub: '🪙${BoosterCosts.swap}',
            enabled: !snap.gameOver && snap.coins >= BoosterCosts.swap,
            active: false,
            onTap: () => run(controller.trySwapPieces()),
          ),
          _BoosterButton(
            icon: Icons.blur_circular,
            label: 'Bombe',
            sub: '🪙${BoosterCosts.bomb}',
            enabled: !snap.gameOver && snap.coins >= BoosterCosts.bomb,
            active: bombMode,
            onTap: () {
              final notifier = ref.read(bombModeProvider.notifier);
              notifier.state = !notifier.state;
            },
          ),
          // Rotation status: not a coin booster — tapping a tray piece
          // rotates it; this chip shows the remaining charges.
          _BoosterButton(
            icon: Icons.rotate_right,
            label: 'Drehen',
            sub: snap.rotationFree ? 'frei' : '⟳${snap.rotationCharges}',
            enabled: !snap.gameOver &&
                (snap.rotationFree || snap.rotationCharges > 0),
            active: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(seconds: 2),
                  content:
                      Text('Tippe ein Teil in der Ablage, um es zu drehen'),
                ),
              );
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
    required this.sub,
    required this.enabled,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// Small line under the label (coin cost or rotation charges).
  final String sub;

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
                sub,
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
    required this.coins,
    required this.combo,
    required this.comboEndsAt,
    required this.fever,
    required this.isDaily,
    required this.feverColor,
  });

  final int score;
  final int highscore;
  final int coins;
  final int combo;
  final DateTime? comboEndsAt;
  final double fever;
  final bool isDaily;
  final Color feverColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              if (isDaily)
                const Text(
                  'TÄGLICHE CHALLENGE',
                  style: TextStyle(
                    color: GridColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              const Spacer(),
              // Live coin balance — updates as you clear lines.
              _CoinChip(coins: coins),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.home_outlined,
                      color: GridColors.textMuted,
                    ),
                    tooltip: 'Hauptmenü',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  _stat('PUNKTE', '$score'),
                ],
              ),
              if (combo > 1)
                _ComboBadge(
                  combo: combo,
                  color: feverColor,
                  endsAt: comboEndsAt,
                ),
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

/// Combo indicator that pulses on each combo step and shows the time window
/// draining away — when the bar empties, the combo is gone.
class _ComboBadge extends StatelessWidget {
  const _ComboBadge({
    required this.combo,
    required this.color,
    required this.endsAt,
  });

  final int combo;
  final Color color;
  final DateTime? endsAt;

  @override
  Widget build(BuildContext context) {
    final label = TweenAnimationBuilder<double>(
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

    final ends = endsAt;
    if (ends == null) return label;
    final remaining = ends.difference(DateTime.now());
    if (remaining.isNegative) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      // Restart the countdown whenever a new clear extends the window.
      key: ValueKey(ends),
      tween: Tween(begin: 1.0, end: 0.0),
      duration: remaining,
      builder: (context, t, child) {
        if (t <= 0) return const SizedBox.shrink();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child!,
            const SizedBox(height: 3),
            SizedBox(
              width: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: t,
                  minHeight: 4,
                  backgroundColor: GridColors.emptyCell,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ],
        );
      },
      child: label,
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
            if (snap.levelsGainedThisRun > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _LevelUpCard(
                  level: snap.playerLevel,
                  levelsGained: snap.levelsGainedThisRun,
                  rewards: snap.rewardsUnlockedThisRun,
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
            for (final a in snap.achievementsUnlockedThisRun)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '🏅 Erfolg: ${a.title}',
                  style: const TextStyle(
                    color: GridColors.fever,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (snap.starterOfferActive) ...[
              const SizedBox(height: 20),
              _StarterCard(hoursLeft: snap.starterHoursLeft),
            ],
            if (snap.playerName.isNotEmpty &&
                snap.score > snap.lastSubmittedScore) ...[
              const SizedBox(height: 20),
              _LeaderboardSubmitButton(
                name: snap.playerName,
                score: snap.score,
              ),
            ],
            const SizedBox(height: 28),
            // "Nochmal" is the primary, always-free action. Qubble shows no
            // forced ads — restarting is instant. The revive below costs
            // coins; ads are never required to keep playing.
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () => controller.newGame(),
              child: const Text('Nochmal spielen'),
            ),
            const SizedBox(height: 8),
            if (!snap.reviveUsed)
              TextButton.icon(
                onPressed: snap.coins >= BoosterCosts.revive
                    ? () => controller.reviveWithCoins()
                    : null,
                icon: const Icon(Icons.favorite_outline, size: 18),
                label: Text('Weiterspielen (🪙 ${BoosterCosts.revive})'),
                style: TextButton.styleFrom(foregroundColor: GridColors.fever),
              ),
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

/// "Submit to leaderboard" button shown on game-over for a new best. Writes
/// straight to the shared Firestore leaderboard under the player's silent
/// anonymous identity — no account, no browser hop.
class _LeaderboardSubmitButton extends ConsumerWidget {
  const _LeaderboardSubmitButton({required this.name, required this.score});

  final String name;
  final int score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: GridColors.placed,
        foregroundColor: GridColors.background,
      ),
      icon: const Icon(Icons.emoji_events),
      label: const Text('In Bestenliste eintragen'),
      onPressed: () async {
        final ok = await ref
            .read(leaderboardServiceProvider)
            .submit(name: name, score: score);
        if (ok) {
          await ref
              .read(gameControllerProvider.notifier)
              .markScoreSubmitted(score);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok
                    ? 'Score steht in der Bestenliste! 🏆'
                    : 'Gerade nicht erreichbar — versuch es später erneut.',
              ),
            ),
          );
        }
      },
    );
  }
}

/// Animated level-up celebration on the game-over screen: a badge that pops
/// and glows, plus any cosmetics the new level(s) unlocked.
class _LevelUpCard extends StatefulWidget {
  const _LevelUpCard({
    required this.level,
    required this.levelsGained,
    required this.rewards,
  });

  final int level;
  final int levelsGained;
  final List<LevelReward> rewards;

  @override
  State<_LevelUpCard> createState() => _LevelUpCardState();
}

class _LevelUpCardState extends State<_LevelUpCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.levelsGained == 1
        ? 'Level ${widget.level} erreicht!'
        : '${widget.levelsGained} Level aufgestiegen — Level ${widget.level}!';

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Pop in with an overshoot, then settle; the glow pulses once.
        final pop = Curves.elasticOut.transform(_c.value.clamp(0.0, 1.0));
        final glow = (1.0 - (_c.value - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.6 + 0.4 * pop,
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB03A), Color(0xFFFF7A59)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB03A).withValues(alpha: glow * 0.7),
                  blurRadius: 26 * glow,
                  spreadRadius: 2 * glow,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.rewards.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final r in widget.rewards)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${r.kind == LevelRewardKind.theme ? '🎨' : '🧊'} '
                  'Freigeschaltet: ${r.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// One-time starter pack card on the game-over screen (C.6).
class _StarterCard extends ConsumerWidget {
  const _StarterCard({required this.hoursLeft});

  final int hoursLeft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C6BFF), Color(0xFF4ECDC4)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '🎁 Starter-Paket',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '1200 Münzen + Wood-Theme',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            'Nur noch $hoursLeft h — einmalig!',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: GridColors.background,
              minimumSize: const Size.fromHeight(44),
            ),
            onPressed: () =>
                ref.read(iapServiceProvider).buy(IapProducts.starter),
            child: const Text(
              'Für 1,99 € holen',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
