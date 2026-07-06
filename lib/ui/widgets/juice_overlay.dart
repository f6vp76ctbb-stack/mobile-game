/// Floating score popups and the All-Clear celebration banner. Decorative,
/// pointer-transparent; keyed off the controller's clear-event id.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../state/theme_controller.dart';

class JuiceOverlay extends ConsumerStatefulWidget {
  const JuiceOverlay({super.key, required this.size, required this.cellSize});

  final double size;
  final double cellSize;

  @override
  ConsumerState<JuiceOverlay> createState() => _JuiceOverlayState();
}

class _JuiceOverlayState extends ConsumerState<JuiceOverlay>
    with TickerProviderStateMixin {
  final List<_Popup> _popups = [];
  _Banner? _banner;

  Offset _centroid(List cells) {
    if (cells.isEmpty) {
      return Offset(widget.size / 2, widget.size / 2);
    }
    var r = 0.0;
    var c = 0.0;
    for (final cell in cells) {
      r += cell.row;
      c += cell.col;
    }
    return Offset(
      (c / cells.length + 0.5) * widget.cellSize,
      (r / cells.length + 0.5) * widget.cellSize,
    );
  }

  void _spawnPopup(String text, Offset at, Color color) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final popup = _Popup(controller: controller, text: text, at: at, color: color);
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _popups.remove(popup));
        controller.dispose();
      }
    });
    setState(() => _popups.add(popup));
    controller.forward();
  }

  void _showBanner(Color color) {
    _banner?.controller.dispose();
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    final banner = _Banner(controller: controller, color: color);
    controller.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _banner = null);
        controller.dispose();
      }
    });
    setState(() => _banner = banner);
    controller.forward();
  }

  @override
  void dispose() {
    for (final p in _popups) {
      p.controller.dispose();
    }
    _banner?.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(activeThemeProvider);
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.clearEventId == (prev?.clearEventId ?? 0)) return;
      if (next.lastGained > 0) {
        _spawnPopup(
          '+${next.lastGained}',
          _centroid(next.clearedCells),
          theme.placed,
        );
      }
      if (next.lastWasAllClear) _showBanner(theme.fever);
    });

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          for (final p in _popups)
            AnimatedBuilder(
              animation: p.controller,
              builder: (context, _) {
                final t = p.controller.value;
                return Positioned(
                  left: p.at.dx - 40,
                  top: p.at.dy - 20 - t * widget.cellSize * 1.6,
                  child: Opacity(
                    opacity: (1.0 - t).clamp(0.0, 1.0),
                    child: SizedBox(
                      width: 80,
                      child: Text(
                        p.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: p.color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 4, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          if (_banner != null)
            AnimatedBuilder(
              animation: _banner!.controller,
              builder: (context, _) {
                final t = _banner!.controller.value;
                final scale = 0.6 + (t < 0.3 ? t / 0.3 : 1.0) * 0.4;
                return Center(
                  child: Opacity(
                    opacity: (t < 0.7 ? 1.0 : (1.0 - t) / 0.3).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: scale,
                      child: Text(
                        'BLITZBLANK!\n+300',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _banner!.color,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(blurRadius: 8, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Popup {
  _Popup({
    required this.controller,
    required this.text,
    required this.at,
    required this.color,
  });

  final AnimationController controller;
  final String text;
  final Offset at;
  final Color color;
}

class _Banner {
  _Banner({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;
}
