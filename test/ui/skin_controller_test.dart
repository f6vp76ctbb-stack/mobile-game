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

  test('unlocking a gold skin spends coins and equips it', () async {
    final gradient = _skin('gradient');
    final c = await _container({'coins': 2000});
    final ok = await c
        .read(skinControllerProvider.notifier)
        .selectOrUnlock(gradient);
    expect(ok, isTrue);
    expect(gradient.currency, SkinCurrency.gold);
    expect(c.read(skinControllerProvider).activeId, 'gradient');
    expect(c.read(activeSkinProvider), BlockSkinStyle.gradient);
    expect(c.read(storageProvider).coins, 2000 - gradient.cost);
  });

  test('cannot unlock without enough coins', () async {
    final c = await _container({'coins': 100});
    final ok = await c
        .read(skinControllerProvider.notifier)
        .selectOrUnlock(_skin('gradient'));
    expect(ok, isFalse);
    expect(c.read(skinControllerProvider).activeId, 'classic');
  });

  test('diamond skins cost diamonds, not coins', () async {
    final glow = _skin('glow');
    expect(glow.currency, SkinCurrency.diamond);

    // Plenty of coins but no diamonds → cannot unlock.
    final poor = await _container({'coins': 999999});
    expect(
      await poor.read(skinControllerProvider.notifier).selectOrUnlock(glow),
      isFalse,
    );

    // Enough diamonds → unlocks and spends diamonds (coins untouched).
    final rich = await _container({'coins': 0, 'diamonds': glow.cost});
    expect(
      await rich.read(skinControllerProvider.notifier).selectOrUnlock(glow),
      isTrue,
    );
    expect(rich.read(skinControllerProvider).activeId, 'glow');
    expect(rich.read(storageProvider).diamonds, 0);
  });

  test('re-selecting an owned skin is free', () async {
    final c = await _container({'coins': 5000});
    final notifier = c.read(skinControllerProvider.notifier);
    final left = 5000 - _skin('gradient').cost;
    await notifier.selectOrUnlock(_skin('gradient'));
    await notifier.selectOrUnlock(_skin('classic'));
    await notifier.selectOrUnlock(_skin('gradient')); // owned, free
    expect(c.read(skinControllerProvider).activeId, 'gradient');
    expect(c.read(storageProvider).coins, left);
  });
}
