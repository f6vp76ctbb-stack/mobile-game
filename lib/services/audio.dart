/// Sound effect abstraction for GridPop.
///
/// The interface and call sites are wired now; the concrete, `audioplayers`-
/// backed implementation lands once CC0 sound assets are added under
/// `assets/audio/` (Phase 2 asset task). Until then [SilentAudio] keeps the
/// game fully playable without shipping placeholder sounds.
library;

enum Sfx { place, clear, combo, feverBurst, gameOver }

abstract class AudioService {
  void play(Sfx sfx);
  set enabled(bool value);
  bool get enabled;
}

/// No-op implementation used until real assets exist.
class SilentAudio implements AudioService {
  @override
  bool enabled = true;

  @override
  void play(Sfx sfx) {}
}
