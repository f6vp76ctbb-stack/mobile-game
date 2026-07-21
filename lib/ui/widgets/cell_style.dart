/// Shared cell rendering for block skins, used by the board and tray painters.
library;

import 'package:flutter/material.dart';

import '../../game/block_skin.dart';

Color _darken(Color c, double amount) =>
    Color.lerp(c, Colors.black, amount) ?? c;

Color _lighten(Color c, double amount) =>
    Color.lerp(c, Colors.white, amount) ?? c;

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
    case BlockSkinStyle.bevel:
      // Raised 3D tile: dark base, lighter inset face, top highlight strip.
      canvas.drawRRect(rrect, Paint()..color = _darken(color, 0.35));
      final inset = rect.deflate(rect.width * 0.14);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inset, Radius.circular(radius * 0.7)),
        Paint()..color = color,
      );
      final topHi = Rect.fromLTWH(
          inset.left, inset.top, inset.width, inset.height * 0.28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(topHi, Radius.circular(radius * 0.7)),
        Paint()..color = _lighten(color, 0.28),
      );
    case BlockSkinStyle.glow:
      // Dark core with a bright, blurred neon border.
      canvas.drawRRect(rrect, Paint()..color = _darken(color, 0.62));
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _lighten(color, 0.3),
      );
    case BlockSkinStyle.stripe:
      canvas.drawRRect(rrect, Paint()..color = color);
      canvas.save();
      canvas.clipRRect(rrect);
      final stripe = Paint()
        ..color = _darken(color, 0.22)
        ..strokeWidth = rect.width * 0.16
        ..style = PaintingStyle.stroke;
      for (var d = -rect.height; d < rect.width; d += rect.width * 0.34) {
        canvas.drawLine(
          Offset(rect.left + d, rect.bottom),
          Offset(rect.left + d + rect.height, rect.top),
          stripe,
        );
      }
      canvas.restore();
    case BlockSkinStyle.crystal:
      // Faceted gem: diagonal gradient base, a bright triangular facet in the
      // upper-left, and a fine light border.
      final shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_lighten(color, 0.18), _darken(color, 0.35)],
      ).createShader(rect);
      canvas.drawRRect(rrect, Paint()..shader = shader);
      canvas.save();
      canvas.clipRRect(rrect);
      final facet = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.left, rect.bottom)
        ..close();
      canvas.drawPath(
        facet,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
      canvas.restore();
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _lighten(color, 0.4),
      );
  }
}
