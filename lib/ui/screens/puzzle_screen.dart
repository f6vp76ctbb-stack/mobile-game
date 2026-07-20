/// Plays a single puzzle level: drag the current piece onto the board, empty it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/board.dart';
import '../../game/piece.dart';
import '../state/game_controller.dart';
import '../state/puzzle_controller.dart';
import '../state/theme_controller.dart';
import '../theme.dart';
import '../widgets/board_view.dart' show boardOriginForDrag, kFingerLiftCells;
import '../widgets/piece_view.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, required this.level});

  final int level;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  final GlobalKey _boardKey = GlobalKey();
  Cell? _preview;
  bool _valid = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(puzzleControllerProvider.notifier).loadLevel(widget.level);
    });
  }

  Cell? _originFor(Offset feedbackTopLeft) {
    final piece = ref.read(puzzleControllerProvider).currentPiece;
    if (piece == null) return null;
    return boardOriginForDrag(
      boardKey: _boardKey,
      piece: piece,
      feedbackTopLeft: feedbackTopLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(puzzleControllerProvider);
    final theme = ref.watch(activeThemeProvider);
    final controller = ref.read(puzzleControllerProvider.notifier);

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        title: Text('Rätsel ${state.level + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.restart,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Züge: ${state.moves}   •   Ziel: ${state.minMoves} für ⭐⭐⭐',
                    style: const TextStyle(color: GridColors.textMuted),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const trayHeight = 92.0;
                      const gap = 16.0;
                      final boardSize = (constraints.maxWidth - 24)
                          .clamp(0.0, constraints.maxHeight - trayHeight - gap);
                      // Like the main game, the DragTarget spans board AND
                      // tray so the bottom rows stay reachable despite the
                      // finger-lift.
                      return DragTarget<int>(
                        onMove: (d) {
                          final origin = _originFor(d.offset);
                          setState(() {
                            _preview = origin;
                            _valid =
                                origin != null && controller.canPlace(origin);
                          });
                        },
                        onLeave: (_) => setState(() => _preview = null),
                        onAcceptWithDetails: (d) {
                          final origin = _originFor(d.offset);
                          if (origin != null) controller.place(origin);
                          setState(() => _preview = null);
                        },
                        builder: (context, _, _) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PuzzleBoard(
                              size: boardSize,
                              boardKey: _boardKey,
                              preview: _preview,
                              valid: _valid,
                            ),
                            const SizedBox(height: gap),
                            _PuzzleTray(
                                boardCell: boardSize / 8, height: trayHeight),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (state.solved) _WinOverlay(state: state),
            if (state.failed) _FailOverlay(state: state),
          ],
        ),
      ),
    );
  }
}

class _PuzzleBoard extends ConsumerWidget {
  const _PuzzleBoard({
    required this.size,
    required this.boardKey,
    required this.preview,
    required this.valid,
  });

  final double size;
  final GlobalKey boardKey;
  final Cell? preview;
  final bool valid;

  double get _cell => size / Board.size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(puzzleControllerProvider);
    final theme = ref.watch(activeThemeProvider);

    return Container(
      key: boardKey,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.boardBackground,
        borderRadius: BorderRadius.circular(_cell * 0.25),
      ),
      child: CustomPaint(
        painter: _PuzzlePainter(
          board: state.board,
          cell: _cell,
          piece: state.currentPiece,
          origin: preview,
          valid: valid,
          filled: theme.placed,
          empty: theme.emptyCell,
          validColor: theme.validPreview,
          invalidColor: theme.invalidPreview,
        ),
      ),
    );
  }
}

class _PuzzlePainter extends CustomPainter {
  _PuzzlePainter({
    required this.board,
    required this.cell,
    required this.piece,
    required this.origin,
    required this.valid,
    required this.filled,
    required this.empty,
    required this.validColor,
    required this.invalidColor,
  });

  final Board board;
  final double cell;
  final Piece? piece;
  final Cell? origin;
  final bool valid;
  final Color filled;
  final Color empty;
  final Color validColor;
  final Color invalidColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.22);
    const inset = 1.5;
    void draw(int r, int c, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c * cell + inset,
            r * cell + inset,
            cell - inset * 2,
            cell - inset * 2,
          ),
          radius,
        ),
        Paint()..color = color,
      );
    }

    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        draw(r, c, board.filledAt(r, c) ? filled : empty);
      }
    }
    final p = piece;
    final o = origin;
    if (p != null && o != null) {
      final color = valid ? validColor : invalidColor;
      for (final cellOffset in p.cells) {
        final r = o.row + cellOffset.row;
        final c = o.col + cellOffset.col;
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          draw(r, c, color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PuzzlePainter old) =>
      old.board != board || old.origin != origin || old.valid != valid;
}

class _PuzzleTray extends ConsumerWidget {
  const _PuzzleTray({required this.boardCell, required this.height});

  final double boardCell;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(puzzleControllerProvider);
    final theme = ref.watch(activeThemeProvider);
    final current = state.currentPiece;
    final next = state.pieceIndex + 1 < state.pieces.length
        ? state.pieces[state.pieceIndex + 1]
        : null;

    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (current != null)
            Draggable<int>(
              data: 0,
              dragAnchorStrategy: (draggable, context, position) => Offset(
                current.width * boardCell / 2,
                current.height * boardCell / 2 + kFingerLiftCells * boardCell,
              ),
              feedback: PieceView(
                piece: current,
                cellSize: boardCell,
                color: theme.placed,
              ),
              childWhenDragging: Opacity(
                opacity: 0.25,
                child: PieceView(
                  piece: current,
                  cellSize: height / 5,
                  color: theme.placed,
                ),
              ),
              child: PieceView(
                piece: current,
                cellSize: height / 5,
                color: theme.traySlots[0],
              ),
            ),
          if (next != null) ...[
            const SizedBox(width: 28),
            Opacity(
              opacity: 0.5,
              child: PieceView(
                piece: next,
                cellSize: height / 7,
                color: GridColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WinOverlay extends ConsumerWidget {
  const _WinOverlay({required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(puzzleControllerProvider.notifier);
    return _Overlay(
      children: [
        const Text(
          'Gelöst! 🎉',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '⭐' * state.stars + '☆' * (3 - state.stars),
          style: const TextStyle(fontSize: 34),
        ),
        if (state.coinsAwarded > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '🪙 +${state.coinsAwarded} Münzen',
              style: const TextStyle(color: GridColors.textPrimary, fontSize: 16),
            ),
          ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: () => controller.loadLevel(state.level + 1),
          child: const Text('Nächstes Level'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Zur Übersicht'),
        ),
      ],
    );
  }
}

class _FailOverlay extends ConsumerWidget {
  const _FailOverlay({required this.state});

  final PuzzleState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(puzzleControllerProvider.notifier);
    return _Overlay(
      children: [
        const Text(
          'Festgefahren',
          style: TextStyle(
            color: GridColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'So lässt sich das Board nicht mehr leeren.',
          textAlign: TextAlign.center,
          style: TextStyle(color: GridColors.textMuted),
        ),
        const SizedBox(height: 24),
        if (state.canExtraMove)
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: GridColors.fever,
              foregroundColor: GridColors.background,
            ),
            onPressed: () async {
              final ok = await ref.read(adServiceProvider).showRewarded();
              if (ok) controller.applyExtraMove();
            },
            child: const Text('▶  Extra-Zug (Video)'),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: controller.restart,
          child: const Text('Neustart'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Zur Übersicht'),
        ),
      ],
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      alignment: Alignment.center,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
