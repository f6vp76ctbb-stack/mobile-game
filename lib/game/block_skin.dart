/// Pure-Dart block skin catalog (MASTERPLAN.md C, Tier 3). No Flutter imports.
///
/// A block skin changes how filled cells and tray pieces are drawn (on top of
/// the active theme's colour). Cosmetic only; unlockable with coins.
library;

enum BlockSkinStyle { solid, gradient, glossy, outline }

class BlockSkin {
  const BlockSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.style,
  });

  final String id;
  final String name;

  /// Coin cost to unlock (0 = free / always owned).
  final int cost;
  final BlockSkinStyle style;
}

const String kDefaultSkinId = 'classic';

const List<BlockSkin> kSkinCatalog = [
  BlockSkin(
    id: kDefaultSkinId,
    name: 'Classic',
    cost: 0,
    style: BlockSkinStyle.solid,
  ),
  BlockSkin(
    id: 'gradient',
    name: 'Verlauf',
    cost: 300,
    style: BlockSkinStyle.gradient,
  ),
  BlockSkin(
    id: 'glossy',
    name: 'Glanz',
    cost: 400,
    style: BlockSkinStyle.glossy,
  ),
  BlockSkin(
    id: 'outline',
    name: 'Kontur',
    cost: 500,
    style: BlockSkinStyle.outline,
  ),
];

BlockSkinStyle skinStyleById(String id) {
  return kSkinCatalog
      .firstWhere((s) => s.id == id, orElse: () => kSkinCatalog.first)
      .style;
}
