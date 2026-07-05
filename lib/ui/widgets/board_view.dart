/// The interactive 8x8 board: renders cells and accepts dragged tray pieces.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/board.dart';
import '../../game/piece.dart';
import '../state/game_controller.dart';
import '../theme.dart';

/// How far above the finger the piece is anchored while dragging (in cells).
const double kFingerLiftCells = 1.2;

class BoardView extends ConsumerStatefulWidget {
  const BoardView({super.key, required this.size});

  /// Side length of the (square) board in logical pixels.
  final double size;

  @override
  ConsumerState<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends ConsumerState<BoardView> {
  final GlobalKey _boardKey = GlobalKey();
  Piece? _previewPiece;
  Cell? _previewOrigin;
  bool _previewValid = false;

  double get _cell => widget.size / Board.size;

  /// Maps a global pointer position + dragged slot to a candidate origin.
  Cell? _originFor(int slot, Offset globalPos) {
    final piece = ref.read(gameControllerProvider).tray[slot];
    if (piece == null) return null;
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;

    final local = box.globalToLocal(globalPos);
    final liftedY = local.dy - kFingerLiftCells * _cell;
    final topLeftX = local.dx - piece.width * _cell / 2;
    final topLeftY = liftedY - piece.height * _cell / 2;

    var col = (topLeftX / _cell).round();
    var row = (topLeftY / _cell).round();
    col = col.clamp(0, Board.size - piece.width);
    row = row.clamp(0, Board.size - piece.height);
    return Cell(row, col);
  }

  void _updatePreview(int slot, Offset globalPos) {
    final origin = _originFor(slot, globalPos);
    final piece = ref.read(gameControllerProvider).tray[slot];
    final valid = origin != null &&
        ref.read(gameControllerProvider.notifier).canPlace(slot, origin);
    setState(() {
      _previewPiece = piece;
      _previewOrigin = origin;
      _previewValid = valid;
    });
  }

  void _clearPreview() {
    setState(() {
      _previewPiece = null;
      _previewOrigin = null;
      _previewValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final board = ref.watch(gameControllerProvider).board;

    return DragTarget<int>(
      onMove: (details) => _updatePreview(details.data, details.offset),
      onLeave: (_) => _clearPreview(),
      onAcceptWithDetails: (details) {
        final slot = details.data;
        final origin = _originFor(slot, details.offset);
        if (origin != null) {
          ref.read(gameControllerProvider.notifier).place(slot, origin);
        }
        _clearPreview();
      },
      builder: (context, _, _) {
        return Container(
          key: _boardKey,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: GridColors.boardBackground,
            borderRadius: BorderRadius.circular(_cell * 0.25),
          ),
          child: CustomPaint(
            painter: _BoardPainter(
              board: board,
              cell: _cell,
              previewPiece: _previewPiece,
              previewOrigin: _previewOrigin,
              previewValid: _previewValid,
            ),
          ),
        );
      },
    );
  }
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.cell,
    required this.previewPiece,
    required this.previewOrigin,
    required this.previewValid,
  });

  final Board board;
  final double cell;
  final Piece? previewPiece;
  final Cell? previewOrigin;
  final bool previewValid;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(cell * 0.22);
    const inset = 1.5;

    void drawCell(int row, int col, Color color) {
      final rect = Rect.fromLTWH(
        col * cell + inset,
        row * cell + inset,
        cell - inset * 2,
        cell - inset * 2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, radius),
        Paint()..color = color,
      );
    }

    // Empty grid + locked cells.
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        drawCell(
          r,
          c,
          board.filledAt(r, c) ? GridColors.placed : GridColors.emptyCell,
        );
      }
    }

    // Drag preview.
    final piece = previewPiece;
    final origin = previewOrigin;
    if (piece != null && origin != null) {
      final color =
          previewValid ? GridColors.validPreview : GridColors.invalidPreview;
      for (final offset in piece.cells) {
        final r = origin.row + offset.row;
        final c = origin.col + offset.col;
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          drawCell(r, c, color);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.board != board ||
      old.previewPiece != previewPiece ||
      old.previewOrigin != previewOrigin ||
      old.previewValid != previewValid;
}
