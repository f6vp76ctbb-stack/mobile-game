import 'package:flutter_test/flutter_test.dart';
import 'package:gridpop/services/audio.dart';
import 'package:gridpop/services/haptics.dart';
import 'package:gridpop/services/storage.dart';
import 'package:gridpop/ui/state/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(SettingsController, Haptics, SilentAudio, SilentMusic, Storage)> _make(
  Map<String, Object> prefs,
) async {
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await Storage.create();
  final haptics = Haptics();
  final audio = SilentAudio();
  final music = SilentMusic();
  final controller = SettingsController(storage, haptics, audio, music);
  return (controller, haptics, audio, music, storage);
}

void main() {
  test('defaults to sound + music + haptics on and applies them', () async {
    final (controller, haptics, audio, music, _) = await _make({});
    expect(controller.state.sound, isTrue);
    expect(controller.state.music, isTrue);
    expect(controller.state.haptics, isTrue);
    expect(haptics.enabled, isTrue);
    expect(audio.enabled, isTrue);
    expect(music.enabled, isTrue);
  });

  test('turning sound off applies to audio and persists', () async {
    final (controller, _, audio, _, storage) = await _make({});
    await controller.setSound(false);
    expect(controller.state.sound, isFalse);
    expect(audio.enabled, isFalse);
    expect(storage.soundEnabled, isFalse);
  });

  test('turning music off applies to the music service and persists', () async {
    final (controller, _, _, music, storage) = await _make({});
    await controller.setMusic(false);
    expect(controller.state.music, isFalse);
    expect(music.enabled, isFalse);
    expect(storage.musicEnabled, isFalse);
  });

  test('turning haptics off applies to haptics and persists', () async {
    final (controller, haptics, _, _, storage) = await _make({});
    await controller.setHaptics(false);
    expect(controller.state.haptics, isFalse);
    expect(haptics.enabled, isFalse);
    expect(storage.hapticsEnabled, isFalse);
  });

  test('restores persisted settings on construction', () async {
    final (controller, haptics, audio, music, _) = await _make({
      'settings.sound': false,
      'settings.music': false,
      'settings.haptics': false,
    });
    expect(controller.state.sound, isFalse);
    expect(controller.state.music, isFalse);
    expect(controller.state.haptics, isFalse);
    expect(haptics.enabled, isFalse);
    expect(audio.enabled, isFalse);
    expect(music.enabled, isFalse);
  });
}
