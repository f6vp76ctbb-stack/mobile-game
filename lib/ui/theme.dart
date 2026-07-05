/// Visual constants for GridPop's calm "Zen" look. Kept in one place so the
/// theme system in Phase 2 can swap palettes.
library;

import 'package:flutter/material.dart';

class GridColors {
  const GridColors._();

  static const background = Color(0xFF12122A);
  static const boardBackground = Color(0xFF1B1B3A);
  static const emptyCell = Color(0xFF23234A);
  static const gridLine = Color(0xFF2C2C57);

  /// Uniform colour for cells that are locked onto the board.
  static const placed = Color(0xFF4ECDC4);

  /// Per-slot accent colours for tray pieces (purely cosmetic).
  static const traySlots = <Color>[
    Color(0xFF7C6BFF), // indigo
    Color(0xFF4ECDC4), // teal
    Color(0xFFFF6BAA), // pink
  ];

  static const validPreview = Color(0x664ECDC4);
  static const invalidPreview = Color(0x66FF5D5D);

  static const fever = Color(0xFFFFB020);
  static const textPrimary = Color(0xFFF4F4FF);
  static const textMuted = Color(0xFF9B9BC7);
}

ThemeData buildGridTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: GridColors.background,
    colorScheme: const ColorScheme.dark(
      primary: GridColors.placed,
      surface: GridColors.boardBackground,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: GridColors.textPrimary,
      displayColor: GridColors.textPrimary,
    ),
  );
}
