/// Currency economy constants + pure conversion logic. No Flutter imports.
///
/// Clean split (Juli 2026): **gold** is the play currency (earned by playing,
/// spent on boosters + entry-level gold skins). **Diamonds** are the premium
/// cosmetic currency (fancy skins). You can buy diamonds with gold, but the
/// rate is deliberately steep so it takes real playtime.
class Economy {
  const Economy._();

  /// Gold needed for one diamond via the in-game exchange.
  static const int goldPerDiamond = 100;

  /// Total gold cost for [diamonds] diamonds (non-negative).
  static int goldCostForDiamonds(int diamonds) =>
      diamonds <= 0 ? 0 : diamonds * goldPerDiamond;
}
