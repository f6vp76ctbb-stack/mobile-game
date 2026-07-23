import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/game_controller.dart';
import 'package:gridpop/ui/state/theme_controller.dart';
import 'package:gridpop/ui/theme.dart';
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

ThemeEntry _entry(String id) => kThemeCatalog.firstWhere((e) => e.id == id);

void main() {
  test('classic is active and owned by default', () async {
    final c = await _container({});
    final state = c.read(themeControllerProvider);
    expect(state.activeId, 'classic');
    expect(state.isUnlocked('classic'), isTrue);
    expect(state.isUnlocked('fade'), isFalse);
  });

  test('unlocking a theme spends coins and equips it', () async {
    final c = await _container({'coins': 600});
    final ok = await c
        .read(themeControllerProvider.notifier)
        .selectOrUnlock(_entry('fade'));
    expect(ok, isTrue);
    expect(c.read(themeControllerProvider).activeId, 'fade');
    expect(c.read(themeControllerProvider).isUnlocked('fade'), isTrue);
    expect(c.read(storageProvider).coins, 250); // 600 - 350
  });

  test('cannot unlock without enough coins', () async {
    final c = await _container({'coins': 100});
    final ok = await c
        .read(themeControllerProvider.notifier)
        .selectOrUnlock(_entry('fade'));
    expect(ok, isFalse);
    expect(c.read(themeControllerProvider).activeId, 'classic');
    expect(c.read(storageProvider).coins, 100); // unchanged
  });

  test('re-selecting an owned theme is free', () async {
    final c = await _container({'coins': 600});
    final notifier = c.read(themeControllerProvider.notifier);
    await notifier.selectOrUnlock(_entry('fade')); // buy -> 100 left
    await notifier.selectOrUnlock(_entry('classic')); // switch back, free
    await notifier.selectOrUnlock(_entry('fade')); // owned, free
    expect(c.read(themeControllerProvider).activeId, 'fade');
    expect(c.read(storageProvider).coins, 250);
  });
}
