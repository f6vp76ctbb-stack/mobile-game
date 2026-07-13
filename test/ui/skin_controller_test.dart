import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/game/block_skin.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/state/skin_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.create();
  final container = ProviderContainer(
    overrides: [
      storageProvider.overrideWithValue(storage),
      hapticsProvider.overrideWithValue(Haptics(enabled: false)),
      audioProvider.overrideWithValue(SilentAudio()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

BlockSkin _skin(String id) => kSkinCatalog.firstWhere((s) => s.id == id);

void main() {
  test('classic is active and owned by default', () async {
    final c = await _container({});
    final state = c.read(skinControllerProvider);
    expect(state.activeId, 'classic');
    expect(state.isUnlocked('gradient'), isFalse);
    expect(c.read(activeSkinProvider), BlockSkinStyle.solid);
  });

  test('unlocking a skin spends coins and equips it', () async {
    final c = await _container({'coins': 500});
    final ok = await c
        .read(skinControllerProvider.notifier)
        .selectOrUnlock(_skin('gradient'));
    expect(ok, isTrue);
    expect(c.read(skinControllerProvider).activeId, 'gradient');
    expect(c.read(activeSkinProvider), BlockSkinStyle.gradient);
    expect(c.read(storageProvider).coins, 200); // 500 - 300
  });

  test('cannot unlock without enough coins', () async {
    final c = await _container({'coins': 100});
    final ok = await c
        .read(skinControllerProvider.notifier)
        .selectOrUnlock(_skin('gradient'));
    expect(ok, isFalse);
    expect(c.read(skinControllerProvider).activeId, 'classic');
  });

  test('re-selecting an owned skin is free', () async {
    final c = await _container({'coins': 500});
    final notifier = c.read(skinControllerProvider.notifier);
    await notifier.selectOrUnlock(_skin('gradient')); // 200 left
    await notifier.selectOrUnlock(_skin('classic'));
    await notifier.selectOrUnlock(_skin('gradient')); // owned, free
    expect(c.read(skinControllerProvider).activeId, 'gradient');
    expect(c.read(storageProvider).coins, 200);
  });
}
