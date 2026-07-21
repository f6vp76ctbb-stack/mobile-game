import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/block_skin.dart';
import 'package:gridpop/game/leveling.dart';
import 'package:gridpop/ui/theme.dart';

void main() {
  group('reward track integrity', () {
    test('every reward id exists in the theme or skin catalog', () {
      final themeIds = kThemeCatalog.map((e) => e.id).toSet();
      final skinIds = kSkinCatalog.map((s) => s.id).toSet();
      for (final r in LevelSystem.rewardTrack) {
        if (r.kind == LevelRewardKind.theme) {
          expect(themeIds, contains(r.id),
              reason: 'theme reward ${r.id} @L${r.level} not in catalog');
        } else {
          expect(skinIds, contains(r.id),
              reason: 'skin reward ${r.id} @L${r.level} not in catalog');
        }
      }
    });

    test('reward levels are strictly increasing', () {
      final levels = [for (final r in LevelSystem.rewardTrack) r.level];
      for (var i = 1; i < levels.length; i++) {
        expect(levels[i], greaterThan(levels[i - 1]));
      }
    });

    test('new themes unlock via the extended track', () {
      final ids = LevelSystem.rewardTrack.map((r) => r.id).toSet();
      expect(ids, containsAll(['sunset', 'forest']));
      expect(LevelSystem.nextReward(20)!.id, 'sunset');
      expect(LevelSystem.nextReward(40), isNull);
    });
  });
}
