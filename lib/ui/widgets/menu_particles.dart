/// Subtle drifting particles for the home-screen background. Purely
/// decorative and cheap: a handful of soft, low-opacity dots that slowly rise
/// and wrap around, tinted with the active theme's tray colours.
library;

import 'dart:math';

import 'package:flutter/material.dart';

class MenuParticles extends StatefulWidget {
  const MenuParticles({super.key, required this.colors, this.count = 16});

  /// Palette to tint particles with (e.g. the theme's tray-slot colours).
  final List<Color> colors;
  final int count;

  @override
  State<MenuParticles> createState() => _MenuParticlesState();
}

class _MenuParticlesState extends State<MenuParticles>
    with SingleTickerProviderStateMixin {
  // One long loop; particle positions are derived from the elapsed fraction,
  // so a single controller drives everything.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 60),
  )..repeat();

  late final List<_Particle> _particles = _build();

  List<_Particle> _build() {
    final rng = Random(42); // fixed layout so it doesn't reshuffle on rebuild
    return [
      for (var i = 0; i < widget.count; i++)
        _Particle(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 2.0 + rng.nextDouble() * 5.0,
          speed: 0.02 + rng.nextDouble() * 0.05,
          sway: rng.nextDouble() * 0.04,
          phase: rng.nextDouble() * 2 * pi,
          alpha: 0.05 + rng.nextDouble() * 0.07,
          color: widget.colors[i % widget.colors.length],
        ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ParticlePainter(
              particles: _particles,
              t: _controller.value * 60, // elapsed seconds
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.sway,
    required this.phase,
    required this.alpha,
    required this.color,
  });

  /// Base position as a fraction of the canvas (0..1).
  final double x;
  final double y;
  final double radius;

  /// Upward drift in fractions of height per second.
  final double speed;

  /// Horizontal sway amplitude (fraction of width).
  final double sway;
  final double phase;
  final double alpha;
  final Color color;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Rise and wrap around vertically; gentle horizontal sway.
      final dy = (p.y - p.speed * t) % 1.0;
      final y = (dy < 0 ? dy + 1.0 : dy) * size.height;
      final x = (p.x + p.sway * sin(t * 0.5 + p.phase)) * size.width;
      canvas.drawCircle(
        Offset(x, y),
        p.radius,
        Paint()..color = p.color.withValues(alpha: p.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
