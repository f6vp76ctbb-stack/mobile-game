import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(SettingsController, Haptics, SilentAudio, Storage)> _make(
  Map<String, Object> prefs,
) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.create();
  final haptics = Haptics();
  final audio = SilentAudio();
  final controller = SettingsController(storage, haptics, audio);
  return (controller, haptics, audio, storage);
}

void main() {
  test('defaults to sound + haptics on and applies them to the services',
      () async {
    final (controller, haptics, audio, _) = await _make({});
    expect(controller.state.sound, isTrue);
    expect(controller.state.haptics, isTrue);
    expect(haptics.enabled, isTrue);
    expect(audio.enabled, isTrue);
  });

  test('turning sound off applies to audio and persists', () async {
    final (controller, _, audio, storage) = await _make({});
    await controller.setSound(false);
    expect(controller.state.sound, isFalse);
    expect(audio.enabled, isFalse);
    expect(storage.soundEnabled, isFalse);
  });

  test('turning haptics off applies to haptics and persists', () async {
    final (controller, haptics, _, storage) = await _make({});
    await controller.setHaptics(false);
    expect(controller.state.haptics, isFalse);
    expect(haptics.enabled, isFalse);
    expect(storage.hapticsEnabled, isFalse);
  });

  test('restores persisted settings on construction', () async {
    final (controller, haptics, audio, _) = await _make({
      'settings.sound': false,
      'settings.haptics': false,
    });
    expect(controller.state.sound, isFalse);
    expect(controller.state.haptics, isFalse);
    expect(haptics.enabled, isFalse);
    expect(audio.enabled, isFalse);
  });
}
