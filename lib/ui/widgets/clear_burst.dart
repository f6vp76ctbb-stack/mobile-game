/// Particle burst that pops out of cleared cells. Purely decorative; it sits
/// over the board and never intercepts pointer events.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../state/theme_controller.dart';

class ClearBurst extends ConsumerStatefulWidget {
  const ClearBurst({super.key, required this.size, required this.cellSize});

  final double size;
  final double cellSize;

  @override
  ConsumerState<ClearBurst> createState() => _ClearBurstState();
}

class _ClearBurstState extends ConsumerState<ClearBurst>
    with TickerProviderStateMixin {
  final List<_Burst> _bursts = [];
  final Random _rng = Random();

  void _spawn(List<Offset> centers, Color color, {int lineCount = 1}) {
    // More lines → a much bigger celebration: more, faster, longer-lived
    // particles per cleared cell. Total is capped so multi-line clears stay
    // smooth on weaker devices (web canvas jank at 400+ circles).
    const maxParticles = 220;
    final intensity = 1.0 + (lineCount - 1) * 0.7;
    var perCell = (7 * intensity).round();
    if (centers.isNotEmpty && perCell * centers.length > maxParticles) {
      perCell = (maxParticles / centers.length).ceil();
    }
    final particles = <_Particle>[];
    for (final c in centers) {
      for (var i = 0; i < perCell; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed =
            widget.cellSize * (1.0 + _rng.nextDouble() * 2.6) * intensity;
        particles.add(_Particle(
          origin: c,
          velocity: Offset(cos(angle), sin(angle)) * speed,
          sizeFactor: 0.10 + _rng.nextDouble() * 0.16,
          sparkle: _rng.nextDouble() < 0.25,
        ));
      }
    }
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (650 * intensity).clamp(650, 1100).round()),
    );
    final burst = _Burst(controller: controller, particles: particles, color: color);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _bursts.remove(burst));
        controller.dispose();
      }
    });
    setState(() => _bursts.add(burst));
    controller.forward();
  }

  Offset _cellCenter(int row, int col) => Offset(
        (col + 0.5) * widget.cellSize,
        (row + 0.5) * widget.cellSize,
      );

  @override
  void dispose() {
    for (final b in _bursts) {
      b.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = ref.watch(activeThemeProvider).placed;
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.clearEventId != (prev?.clearEventId ?? 0) &&
          next.clearedCells.isNotEmpty) {
        _spawn(
          [for (final c in next.clearedCells) _cellCenter(c.row, c.col)],
          color,
          lineCount: next.lastClearedLineCount.clamp(1, 5),
        );
      }
    });

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          for (final burst in _bursts)
            AnimatedBuilder(
              animation: burst.controller,
              builder: (context, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _ParticlePainter(
                  burst: burst,
                  t: burst.controller.value,
                  cellSize: widget.cellSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Burst {
  _Burst({
    required this.controller,
    required this.particles,
    required this.color,
  });

  final AnimationController controller;
  final List<_Particle> particles;
  final Color color;
}

class _Particle {
  _Particle({
    required this.origin,
    required this.velocity,
    this.sizeFactor = 0.18,
    this.sparkle = false,
  });

  final Offset origin;
  final Offset velocity;

  /// Particle radius as a fraction of the cell size (varied for depth).
  final double sizeFactor;

  /// Sparkles render white-hot instead of theme-colored.
  final bool sparkle;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.burst,
    required this.t,
    required this.cellSize,
  });

  final _Burst burst;
  final double t;
  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(t);
    final alpha = 1.0 - t;
    if (alpha <= 0) return;
    final paint = Paint()..color = burst.color.withValues(alpha: alpha);
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: alpha);
    // Light gravity so the burst falls like confetti instead of just fading.
    final gravity = cellSize * 1.6 * t * t;
    for (final p in burst.particles) {
      final radius = cellSize * p.sizeFactor * (1.0 - t);
      if (radius <= 0) continue;
      final pos = p.origin + p.velocity * eased + Offset(0, gravity);
      canvas.drawCircle(pos, radius, p.sparkle ? sparklePaint : paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
