/// Shared cell rendering for block skins, used by the board and tray painters.
library;

import 'package:flutter/material.dart';

import '../../game/block_skin.dart';

Color _darken(Color c, double amount) =>
    Color.lerp(c, Colors.black, amount) ?? c;

/// Paints a single filled cell in [rect] using [color] and the given [style].
void paintCell(
  Canvas canvas,
  Rect rect,
  double radius,
  Color color,
  BlockSkinStyle style,
) {
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  switch (style) {
    case BlockSkinStyle.solid:
      canvas.drawRRect(rrect, Paint()..color = color);
    case BlockSkinStyle.gradient:
      final shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, _darken(color, 0.30)],
      ).createShader(rect);
      canvas.drawRRect(rrect, Paint()..shader = shader);
    case BlockSkinStyle.glossy:
      canvas.drawRRect(rrect, Paint()..color = color);
      final highlight = Rect.fromLTWH(
        rect.left,
        rect.top,
        rect.width,
        rect.height * 0.42,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(highlight, Radius.circular(radius)),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    case BlockSkinStyle.outline:
      canvas.drawRRect(rrect, Paint()..color = _darken(color, 0.55));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
  }
}
