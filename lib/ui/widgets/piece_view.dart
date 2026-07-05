/// Renders a single [Piece] as coloured rounded cells.
library;

import 'package:flutter/material.dart';

import '../../game/piece.dart';

class PieceView extends StatelessWidget {
  const PieceView({
    super.key,
    required this.piece,
    required this.cellSize,
    required this.color,
    this.opacity = 1.0,
  });

  final Piece piece;
  final double cellSize;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: piece.width * cellSize,
      height: piece.height * cellSize,
      child: CustomPaint(
        painter: _PiecePainter(piece, cellSize, color, opacity),
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter(this.piece, this.cellSize, this.color, this.opacity);

  final Piece piece;
  final double cellSize;
  final Color color;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: opacity);
    const inset = 1.5;
    final radius = Radius.circular(cellSize * 0.22);
    for (final cell in piece.cells) {
      final rect = Rect.fromLTWH(
        cell.col * cellSize + inset,
        cell.row * cellSize + inset,
        cellSize - inset * 2,
        cellSize - inset * 2,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  @override
  bool shouldRepaint(_PiecePainter old) =>
      old.piece != piece ||
      old.cellSize != cellSize ||
      old.color != color ||
      old.opacity != opacity;
}
