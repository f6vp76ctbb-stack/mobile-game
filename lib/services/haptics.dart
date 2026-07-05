/// Thin wrapper around Flutter's haptic feedback, gated by a user setting.
library;

import 'package:flutter/services.dart';

class Haptics {
  Haptics({this.enabled = true});

  bool enabled;

  /// Light tick when a piece locks onto the board.
  void place() {
    if (enabled) HapticFeedback.selectionClick();
  }

  /// Medium bump when one or more lines clear.
  void clear() {
    if (enabled) HapticFeedback.lightImpact();
  }

  /// Stronger feedback for a fever burst.
  void feverBurst() {
    if (enabled) HapticFeedback.heavyImpact();
  }

  /// Feedback on game over.
  void gameOver() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
