/// Cohesive icon language for Qubble — replaces ad-hoc emoji (🪙 🏆 🔥 …),
/// which render differently on every device and read as amateur. The currency
/// is a custom-painted coin used everywhere; the rest are consistent rounded
/// Material symbols surfaced through [AppIcons] so every screen speaks the same
/// visual language.
library;

import 'package:flutter/material.dart';

/// One place for every non-currency icon, so usage stays consistent.
class AppIcons {
  const AppIcons._();

  static const trophy = Icons.emoji_events_rounded;
  static const streak = Icons.local_fire_department_rounded;
  static const level = Icons.military_tech_rounded;
  static const play = Icons.play_arrow_rounded;
  static const shop = Icons.storefront_rounded;
  static const themes = Icons.palette_rounded;
  static const skins = Icons.grid_view_rounded;
  static const stats = Icons.insights_rounded;
  static const settings = Icons.settings_rounded;
  static const missions = Icons.flag_rounded;
  static const puzzle = Icons.extension_rounded;
  static const leaderboard = Icons.leaderboard_rounded;
  static const undo = Icons.undo_rounded;
  static const swap = Icons.swap_horiz_rounded;
  static const bomb = Icons.bubble_chart_rounded;
  static const sparkle = Icons.auto_awesome_rounded;
  static const celebrate = Icons.celebration_rounded;
}

/// The Qubble coin — a small gold token with a gem mark. Consistent everywhere
/// the game shows currency, so "money" always looks the same.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CoinPainter()),
    );
  }
}

class _CoinPainter extends CustomPainter {
  // Warm gold, tuned to sit on the dark Aurora ground.
  static const _light = Color(0xFFFFE7A3);
  static const _mid = Color(0xFFFFC24B);
  static const _deep = Color(0xFFE8992E);
  static const _rim = Color(0xFFC77E1F);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Rim.
    canvas.drawCircle(c, r, Paint()..color = _rim);

    // Coin face: warm radial gradient, light from the upper-left.
    final face = Rect.fromCircle(center: c, radius: r * 0.9);
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: const [_light, _mid, _deep],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(face),
    );

    // Centre gem: a slim 4-point diamond that ties into the Aurora blocks.
    final gem = Path();
    final g = r * 0.42;
    gem
      ..moveTo(c.dx, c.dy - g)
      ..lineTo(c.dx + g * 0.62, c.dy)
      ..lineTo(c.dx, c.dy + g)
      ..lineTo(c.dx - g * 0.62, c.dy)
      ..close();
    canvas.drawPath(
      gem,
      Paint()..color = _rim.withValues(alpha: 0.55),
    );

    // Top-left glint.
    canvas.drawCircle(
      Offset(c.dx - r * 0.34, c.dy - r * 0.36),
      r * 0.16,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_CoinPainter oldDelegate) => false;
}

/// The premium diamond — a cut blue gem. Consistent everywhere diamonds are
/// shown, and clearly distinct from the gold coin.
class DiamondIcon extends StatelessWidget {
  const DiamondIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DiamondPainter()),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.30; // girdle line

    // Gem body: crown point up top, wide girdle, tapering to a bottom point.
    final gem = Path()
      ..moveTo(w * 0.5, h * 0.04)
      ..lineTo(w * 0.90, top)
      ..lineTo(w * 0.5, h * 0.97)
      ..lineTo(w * 0.10, top)
      ..close();
    canvas.drawPath(
      gem,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB6F0FF), Color(0xFF48C6F5), Color(0xFF2A8FE0)],
        ).createShader(Offset.zero & size),
    );

    // Bright table facet at the top.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.04)
        ..lineTo(w * 0.72, top)
        ..lineTo(w * 0.5, h * 0.52)
        ..lineTo(w * 0.28, top)
        ..close(),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    // Crisp outline.
    canvas.drawPath(
      gem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..color = const Color(0xFF1C6FB8),
    );
  }

  @override
  bool shouldRepaint(_DiamondPainter oldDelegate) => false;
}

/// Diamond icon + amount, for premium (skin) prices and the diamond balance.
class DiamondAmount extends StatelessWidget {
  const DiamondAmount({
    super.key,
    required this.amount,
    this.size = 18,
    this.color,
    this.fontWeight = FontWeight.w700,
  });

  final int amount;
  final double size;
  final Color? color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DiamondIcon(size: size),
        SizedBox(width: size * 0.3),
        Text(
          '$amount',
          style: TextStyle(
            color: color,
            fontSize: size * 0.92,
            fontWeight: fontWeight,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Coin icon + amount, the standard way to show a currency value inline.
class CoinAmount extends StatelessWidget {
  const CoinAmount({
    super.key,
    required this.amount,
    this.size = 18,
    this.color,
    this.fontWeight = FontWeight.w700,
    this.prefix = '',
  });

  final int amount;
  final double size;
  final Color? color;
  final FontWeight fontWeight;

  /// Optional leading text such as '+' for reward popups.
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinIcon(size: size),
        SizedBox(width: size * 0.3),
        Text(
          '$prefix$amount',
          style: TextStyle(
            color: color,
            fontSize: size * 0.92,
            fontWeight: fontWeight,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
