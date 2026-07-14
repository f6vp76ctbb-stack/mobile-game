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

  void _spawn(List<Offset> centers, Color color) {
    final particles = <_Particle>[];
    for (final c in centers) {
      final count = 3 + _rng.nextInt(2);
      for (var i = 0; i < count; i++) {
        final angle = _rng.nextDouble() * 2 * pi;
        final speed = widget.cellSize * (0.8 + _rng.nextDouble() * 1.8);
        particles.add(_Particle(
          origin: c,
          velocity: Offset(cos(angle), sin(angle)) * speed,
        ));
      }
    }
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
  _Particle({required this.origin, required this.velocity});

  final Offset origin;
  final Offset velocity;
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
    final paint = Paint()..color = burst.color.withValues(alpha: 1.0 - t);
    final radius = cellSize * 0.18 * (1.0 - t);
    if (radius <= 0) return;
    for (final p in burst.particles) {
      final pos = p.origin + p.velocity * eased;
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
