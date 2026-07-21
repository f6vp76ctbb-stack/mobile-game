/// Pure-Dart block skin catalog (MASTERPLAN.md C, Tier 3). No Flutter imports.
///
/// A block skin changes how filled cells and tray pieces are drawn (on top of
/// the active theme's colour). Cosmetic only; unlockable with coins — except
/// supporter-only skins, which come exclusively with the supporter pack.
library;

enum BlockSkinStyle { solid, gradient, glossy, outline, bevel, glow, stripe, crystal }

class BlockSkin {
  const BlockSkin({
    required this.id,
    required this.name,
    required this.cost,
    required this.style,
    this.supporterOnly = false,
  });

  final String id;
  final String name;

  /// Coin cost to unlock (0 = free / always owned; ignored if [supporterOnly]).
  final int cost;
  final BlockSkinStyle style;

  /// Exclusive to the supporter pack — never purchasable with coins.
  final bool supporterOnly;
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
  BlockSkin(
    id: 'bevel',
    name: 'Relief',
    cost: 600,
    style: BlockSkinStyle.bevel,
  ),
  BlockSkin(
    id: 'glow',
    name: 'Glow',
    cost: 700,
    style: BlockSkinStyle.glow,
  ),
  BlockSkin(
    id: 'stripe',
    name: 'Streifen',
    cost: 600,
    style: BlockSkinStyle.stripe,
  ),
  BlockSkin(
    id: 'crystal',
    name: 'Kristall',
    cost: 0,
    style: BlockSkinStyle.crystal,
    supporterOnly: true,
  ),
];

BlockSkinStyle skinStyleById(String id) {
  return kSkinCatalog
      .firstWhere((s) => s.id == id, orElse: () => kSkinCatalog.first)
      .style;
}
