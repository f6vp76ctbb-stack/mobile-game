# Entwicklungs-Umgebung

## Flutter in Cloud-Sessions

Flutter ist in frischen Cloud-Umgebungen **nicht** vorinstalliert. Das Skript
`scripts/setup.sh` installiert das Flutter SDK (stable) nach `~/.flutter-sdk`,
precached die Build-Artefakte und führt `flutter pub get` aus. Es ist idempotent.

Manuell ausführen:

```bash
bash scripts/setup.sh
export PATH="$HOME/.flutter-sdk/bin:$PATH"   # in neuen Shells
```

## SessionStart-Hook (empfohlen, einmalige Freigabe nötig)

Damit jede neue Claude-Session automatisch testfähig ist, kann `setup.sh` als
SessionStart-Hook registriert werden. Aus Sicherheitsgründen schreibt Claude
Hooks **nicht** selbstständig — lege die Datei `.claude/settings.json` mit
diesem Inhalt selbst an (oder gib Claude die Freigabe dafür):

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash scripts/setup.sh" } ] }
    ]
  }
}
```

## Lokale Entwicklung (Mac/Linux/Windows)

Reguläre Flutter-Installation gemäß https://docs.flutter.dev/get-started/install.
Danach `flutter pub get`, `flutter test`, `flutter run`.

## Hinweis „running as root"

In der Cloud-Umgebung läuft `flutter` als root und warnt davor. Für
`flutter analyze`/`flutter test` (reine Dart-Logik) ist das unkritisch.
