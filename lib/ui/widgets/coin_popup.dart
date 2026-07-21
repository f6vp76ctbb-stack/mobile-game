/// A floating "+N 🪙" that rises and fades over the board whenever a clearing
/// move earns coins, so the player sees the reward while playing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/game_controller.dart';
import '../theme.dart';

class CoinPopup extends ConsumerStatefulWidget {
  const CoinPopup({super.key, required this.size});

  final double size;

  @override
  ConsumerState<CoinPopup> createState() => _CoinPopupState();
}

class _CoinPopupState extends ConsumerState<CoinPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int _amount = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show(int amount) {
    setState(() => _amount = amount);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(gameControllerProvider, (prev, next) {
      if (next.clearEventId != (prev?.clearEventId ?? 0) &&
          next.lastCoinGain > 0) {
        _show(next.lastCoinGain);
      }
    });

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          if (t == 0 || t == 1 || _amount == 0) {
            return const SizedBox.shrink();
          }
          final rise = 26 * Curves.easeOut.transform(t);
          final opacity = t < 0.15 ? t / 0.15 : (1 - (t - 0.15) / 0.85);
          return Positioned(
            top: widget.size * 0.18 - rise,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+$_amount 🪙',
                    style: const TextStyle(
                      color: GridColors.fever,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
