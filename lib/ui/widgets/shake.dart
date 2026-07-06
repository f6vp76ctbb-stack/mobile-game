/// Briefly shakes its child when [trigger] changes while [enabled] is true.
/// Used for the 3+-line-clear screen shake (MASTERPLAN.md C.8).
library;

import 'dart:math';

import 'package:flutter/material.dart';

class Shake extends StatefulWidget {
  const Shake({
    super.key,
    required this.trigger,
    required this.enabled,
    required this.child,
  });

  /// Change this value to start a shake (e.g. the clear-event id).
  final int trigger;
  final bool enabled;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // Decaying horizontal wobble.
        final dx = t == 0 ? 0.0 : sin(t * pi * 4) * 6 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
