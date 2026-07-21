import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/block_skin.dart';

void main() {
  test('catalog has unique ids and a free default', () {
    final ids = kSkinCatalog.map((s) => s.id).toSet();
    expect(ids.length, kSkinCatalog.length);
    final classic = kSkinCatalog.firstWhere((s) => s.id == kDefaultSkinId);
    expect(classic.cost, 0);
  });

  test('paid skins have positive costs; supporter skins are never sold', () {
    for (final s in kSkinCatalog.where(
      (s) => s.id != kDefaultSkinId && !s.supporterOnly,
    )) {
      expect(s.cost, greaterThan(0));
    }
    // Supporter-only skins exist and carry no coin price.
    final crystal = kSkinCatalog.singleWhere((s) => s.id == 'crystal');
    expect(crystal.supporterOnly, isTrue);
    expect(crystal.cost, 0);
  });

  test('skinStyleById resolves known ids and falls back for unknown', () {
    expect(skinStyleById('gradient'), BlockSkinStyle.gradient);
    expect(skinStyleById('nope'), BlockSkinStyle.solid); // default
  });
}
