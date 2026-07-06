/// Sound effect abstraction for GridPop.
///
/// [SilentAudio] keeps tests and headless contexts sound-free; [Audioplayers
/// Audio] plays the self-made WAV assets in `assets/audio/` (see
/// assets/CREDITS.md). Wire the real one only where a Flutter plugin binding
/// exists (i.e. the running app, not unit tests).
library;

import 'package:audioplayers/audioplayers.dart';

enum Sfx { place, clear, combo, feverBurst, gameOver }

abstract class AudioService {
  /// Plays [sfx]. [pitch] scales the playback rate (>1 = higher) for the combo
  /// escalation effect.
  void play(Sfx sfx, {double pitch});
  set enabled(bool value);
  bool get enabled;
}

/// No-op implementation used in tests and until assets exist.
class SilentAudio implements AudioService {
  @override
  bool enabled = true;

  @override
  void play(Sfx sfx, {double pitch = 1.0}) {}
}

/// Plays short SFX via a small pool of [AudioPlayer]s so rapid effects (e.g.
/// combos) can overlap without cutting each other off.
class AudioplayersAudio implements AudioService {
  AudioplayersAudio({int poolSize = 4})
      : _pool = List.generate(
          poolSize,
          (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
        );

  final List<AudioPlayer> _pool;
  int _next = 0;

  @override
  bool enabled = true;

  static const _assets = {
    Sfx.place: 'audio/place.wav',
    Sfx.clear: 'audio/clear.wav',
    Sfx.combo: 'audio/combo.wav',
    Sfx.feverBurst: 'audio/fever.wav',
    Sfx.gameOver: 'audio/gameover.wav',
  };

  @override
  void play(Sfx sfx, {double pitch = 1.0}) {
    if (!enabled) return;
    final asset = _assets[sfx];
    if (asset == null) return;
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    if (pitch != 1.0) player.setPlaybackRate(pitch);
    // Fire-and-forget; low latency matters more than awaiting completion.
    player.play(AssetSource(asset), volume: 0.6);
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
  }
}
