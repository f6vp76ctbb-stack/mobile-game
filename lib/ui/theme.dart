/// Visual constants for GridPop's calm "Zen" look. Kept in one place so the
/// theme system in Phase 2 can swap palettes.
library;

import 'package:flutter/material.dart';

class GridColors {
  const GridColors._();

  static const background = Color(0xFF0F1030);
  static const boardBackground = Color(0xFF191B40);
  static const emptyCell = Color(0xFF23254E);
  static const gridLine = Color(0xFF2E3068);

  /// Uniform colour for cells that are locked onto the board.
  static const placed = Color(0xFF4FE0C6);

  /// Per-slot accent colours for tray pieces (purely cosmetic).
  static const traySlots = <Color>[
    Color(0xFF7C6BFF), // indigo
    Color(0xFF4FE0C6), // teal
    Color(0xFFFF6FB0), // pink
  ];

  static const validPreview = Color(0x664FE0C6);
  static const invalidPreview = Color(0x66FF5D5D);

  /// Gold accent — matched to the coin so highlights read as one system.
  static const fever = Color(0xFFFFC24B);
  static const textPrimary = Color(0xFFF4F4FF);
  static const textMuted = Color(0xFF9B9BC7);
}

ThemeData buildGridTheme() {
  return ThemeData(
    useMaterial3: true,
    // Nunito everywhere — rounded and friendly, the app's premium voice.
    fontFamily: 'Nunito',
    scaffoldBackgroundColor: GridColors.background,
    colorScheme: const ColorScheme.dark(
      primary: GridColors.placed,
      surface: GridColors.boardBackground,
    ),
    textTheme: const TextTheme().apply(
      bodyColor: GridColors.textPrimary,
      displayColor: GridColors.textPrimary,
      fontFamily: 'Nunito',
    ),
    // The default Material "zoom" page transition composites shadows/clips
    // every frame and janks badly on Flutter web. A plain cross-fade is cheap
    // and smooth on every platform.
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values)
          platform: const _FadePageTransitionsBuilder(),
      },
    ),
  );
}

/// A lightweight fade page transition used on all platforms (see
/// [buildGridTheme]).
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// A swappable board palette. Chrome text stays on [GridColors] (all themes
/// use dark backgrounds, so light text is always readable).
class GameTheme {
  const GameTheme({
    required this.background,
    required this.boardBackground,
    required this.emptyCell,
    required this.placed,
    required this.traySlots,
    required this.validPreview,
    required this.invalidPreview,
    required this.fever,
  });

  final Color background;
  final Color boardBackground;
  final Color emptyCell;
  final Color placed;
  final List<Color> traySlots;
  final Color validPreview;
  final Color invalidPreview;
  final Color fever;
}

/// A theme plus its store metadata.
class ThemeEntry {
  const ThemeEntry({
    required this.id,
    required this.name,
    required this.cost,
    required this.theme,
    this.supporterOnly = false,
  });

  final String id;
  final String name;

  /// Coin cost to unlock (0 = free / always owned; ignored if [supporterOnly]).
  final int cost;
  final GameTheme theme;

  /// Exclusive to the supporter pack — never purchasable with coins.
  final bool supporterOnly;
}

const String kDefaultThemeId = 'classic';

/// All available themes (classic is free; others cost coins per Anhang A.3).
const List<ThemeEntry> kThemeCatalog = [
  ThemeEntry(
    id: kDefaultThemeId,
    name: 'Classic',
    cost: 0,
    theme: GameTheme(
      background: Color(0xFF0F1030),
      boardBackground: Color(0xFF191B40),
      emptyCell: Color(0xFF23254E),
      placed: Color(0xFF4FE0C6),
      traySlots: [Color(0xFF7C6BFF), Color(0xFF4FE0C6), Color(0xFFFF6FB0)],
      validPreview: Color(0x664FE0C6),
      invalidPreview: Color(0x66FF5D5D),
      fever: Color(0xFFFFC24B),
    ),
  ),
  ThemeEntry(
    id: 'fade',
    name: 'Fade',
    cost: 350,
    theme: GameTheme(
      background: Color(0xFF171A2D),
      boardBackground: Color(0xFF242842),
      emptyCell: Color(0xFF303651),
      placed: Color(0xFF9EA8FF),
      traySlots: [Color(0xFF9EA8FF), Color(0xFFC4A7FF), Color(0xFF8AD9D0)],
      validPreview: Color(0x669EA8FF),
      invalidPreview: Color(0x66FF7A9B),
      fever: Color(0xFFFFCE72),
    ),
  ),
  ThemeEntry(
    id: 'neon',
    name: 'Neon',
    cost: 250,
    theme: GameTheme(
      background: Color(0xFF07070C),
      boardBackground: Color(0xFF12121C),
      emptyCell: Color(0xFF1B1B28),
      placed: Color(0xFF39FF14),
      traySlots: [Color(0xFF00E5FF), Color(0xFF39FF14), Color(0xFFFF2D95)],
      validPreview: Color(0x6639FF14),
      invalidPreview: Color(0x66FF2D95),
      fever: Color(0xFFFFE600),
    ),
  ),
  ThemeEntry(
    id: 'ocean',
    name: 'Ocean',
    cost: 500,
    theme: GameTheme(
      background: Color(0xFF06263A),
      boardBackground: Color(0xFF0B3450),
      emptyCell: Color(0xFF124765),
      placed: Color(0xFF35D0BA),
      traySlots: [Color(0xFF35D0BA), Color(0xFF4AA8FF), Color(0xFF8CE0FF)],
      validPreview: Color(0x6635D0BA),
      invalidPreview: Color(0x66FF6B6B),
      fever: Color(0xFFFFC24B),
    ),
  ),
  ThemeEntry(
    id: 'wood',
    name: 'Wood',
    cost: 700,
    theme: GameTheme(
      background: Color(0xFF241811),
      boardBackground: Color(0xFF33251A),
      emptyCell: Color(0xFF43301F),
      placed: Color(0xFFD9A05B),
      traySlots: [Color(0xFFD9A05B), Color(0xFFB5763C), Color(0xFFE8C79A)],
      validPreview: Color(0x66D9A05B),
      invalidPreview: Color(0x66C1502F),
      fever: Color(0xFFFFD27F),
    ),
  ),
  ThemeEntry(
    id: 'sunset',
    name: 'Sunset',
    cost: 800,
    theme: GameTheme(
      background: Color(0xFF1E1030),
      boardBackground: Color(0xFF2A1743),
      emptyCell: Color(0xFF3A2158),
      placed: Color(0xFFFF7E5F),
      traySlots: [Color(0xFFFF7E5F), Color(0xFFFEB47B), Color(0xFFFF5E9C)],
      validPreview: Color(0x66FF7E5F),
      invalidPreview: Color(0x66FF5D5D),
      fever: Color(0xFFFFD166),
    ),
  ),
  ThemeEntry(
    id: 'forest',
    name: 'Forest',
    cost: 800,
    theme: GameTheme(
      background: Color(0xFF0C1F14),
      boardBackground: Color(0xFF12301F),
      emptyCell: Color(0xFF1B4029),
      placed: Color(0xFF7BE382),
      traySlots: [Color(0xFF7BE382), Color(0xFF4FB477), Color(0xFFB8F2A0)],
      validPreview: Color(0x667BE382),
      invalidPreview: Color(0x66FF6B6B),
      fever: Color(0xFFFFD166),
    ),
  ),
  // Supporter-pack exclusive (polar-lights palette) — never sold for coins.
  ThemeEntry(
    id: 'aurora',
    name: 'Aurora',
    cost: 0,
    supporterOnly: true,
    theme: GameTheme(
      background: Color(0xFF0B1026),
      boardBackground: Color(0xFF131A3C),
      emptyCell: Color(0xFF1C2450),
      placed: Color(0xFF6BF0C8),
      traySlots: [Color(0xFF6BF0C8), Color(0xFF7C9BFF), Color(0xFFC77CFF)],
      validPreview: Color(0x666BF0C8),
      invalidPreview: Color(0x66FF6B8A),
      fever: Color(0xFFFFD166),
    ),
  ),
];

GameTheme themeById(String id) {
  return kThemeCatalog
      .firstWhere((e) => e.id == id, orElse: () => kThemeCatalog.first)
      .theme;
}
