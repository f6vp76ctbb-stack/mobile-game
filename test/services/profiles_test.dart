import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Storage> _storage([Map<String, Object> prefs = const {}]) async {
  SharedPreferences.setMockInitialValues(prefs);
  return Storage.create();
}

void main() {
  group('local profiles', () {
    test('a fresh install has one default profile that is active', () async {
      final s = await _storage();
      expect(s.profiles, hasLength(1));
      expect(s.activeProfileId, 0);
      expect(s.activeProfile.name, Storage.defaultProfileName);
    });

    test('legacy progress belongs to the default profile (no migration)',
        () async {
      // Pre-profile installs stored coins under the bare 'coins' key.
      final s = await _storage({'coins': 4242});
      expect(s.activeProfileId, 0);
      expect(s.coins, 4242);
    });

    test('a new profile starts with fresh, isolated progress', () async {
      final s = await _storage({'coins': 4242});
      await s.addCoins(0); // ensure default profile persisted at 4242
      expect(s.coins, 4242);

      final p = await s.addProfile('Zweiter');
      expect(p.id, 1);
      await s.setActiveProfile(p.id);

      // Brand-new profile → starting coins, not the default profile's 4242.
      expect(s.coins, Storage.startingCoins);

      await s.addCoins(500);
      expect(s.coins, Storage.startingCoins + 500);

      // Switching back leaves the first profile untouched.
      await s.setActiveProfile(0);
      expect(s.coins, 4242);
    });

    test('progress keys are fully isolated between profiles', () async {
      final s = await _storage();
      await s.setHighscore(1000);
      await s.setPlayerLevel(7);
      await s.setActiveTheme('neon');

      final p = await s.addProfile('B');
      await s.setActiveProfile(p.id);
      expect(s.highscore, 0);
      expect(s.playerLevel, 1);
      expect(s.activeTheme, 'classic');

      await s.setHighscore(50);
      await s.setActiveProfile(0);
      expect(s.highscore, 1000);
      expect(s.playerLevel, 7);
      expect(s.activeTheme, 'neon');
    });

    test('renaming keeps id and progress', () async {
      final s = await _storage();
      await s.setCoins(999);
      await s.renameProfile(0, 'Umbenannt');
      expect(s.activeProfile.name, 'Umbenannt');
      expect(s.coins, 999);
    });

    test('deleting a profile wipes its data and switches away if active',
        () async {
      final s = await _storage();
      final p = await s.addProfile('Wegwerf');
      await s.setActiveProfile(p.id);
      await s.setCoins(777);

      final deleted = await s.deleteProfile(p.id);
      expect(deleted, isTrue);
      expect(s.profiles, hasLength(1));
      expect(s.activeProfileId, 0);

      // Recreating reuses the next id and starts clean (no leaked 777).
      final again = await s.addProfile('Neu');
      await s.setActiveProfile(again.id);
      expect(s.coins, Storage.startingCoins);
    });

    test('the last remaining profile cannot be deleted', () async {
      final s = await _storage();
      expect(await s.deleteProfile(0), isFalse);
      expect(s.profiles, hasLength(1));
    });

    test('settings and ad-free are device-global, shared across profiles',
        () async {
      final s = await _storage();
      await s.setAdFree(true);
      await s.setSoundEnabled(false);

      final p = await s.addProfile('B');
      await s.setActiveProfile(p.id);
      expect(s.adFree, isTrue, reason: 'purchases belong to the device');
      expect(s.soundEnabled, isFalse, reason: 'settings are device-wide');
    });
  });
}
