# CLAUDE.md — Qubble (Block-Puzzle, iOS + Android)

> **Neue Session? Zuerst `HANDOVER.md` lesen** — vollständige Übergabe mit
> Projektstand, Architektur-Entscheidungen, Web/PWA-Fallstricken, Pipelines
> (Feedback/Bestenliste), offenen Punkten und Nutzer-Feedback-Historie.

## Projekt

Qubble ist ein Block-Puzzle-Spiel (Genre: Block Blast!/Woodoku) für App Store und
Play Store. Monetarisierung über AdMob (Interstitial + Rewarded) und In-App-Käufe.
Vollständiger Produkt- und Phasenplan: siehe `MASTERPLAN.md` — dort steht auch die
aktuelle Phase mit Checkliste. Vor jeder Arbeitssession dort den Stand prüfen und
Checkboxen aktuell halten.

## Stack

- **Flutter** (stable channel), Sprache Dart — eine Codebase für iOS + Android
- State Management: Riverpod
- Ads: `google_mobile_ads` (+ UMP SDK für DSGVO-Consent)
- IAP: `in_app_purchase`
- Persistenz: `shared_preferences` (kein Backend/Server!)
- Analytics/Crashes: Firebase Analytics + Crashlytics
- Audio: `audioplayers`; Haptik: `HapticFeedback` aus flutter/services

## Architektur-Regeln

- **Spiellogik strikt von UI trennen.** Alles unter `lib/game/` (Board, Pieces,
  Generator, Scoring, DailyChallenge) ist pures Dart ohne Flutter-Imports —
  vollständig unit-testbar.
- UI unter `lib/ui/`, Monetarisierung unter `lib/monetization/`,
  Services (Storage, Analytics, Audio) unter `lib/services/`.
- Der Teile-Generator ist seed-bar (`Random(seed)`) — Grundlage für die Daily
  Challenge und für deterministische Tests.
- Keine Netzwerk-Abhängigkeit im Gameplay: Das Spiel muss komplett offline laufen.

## Verzeichnisstruktur (Ziel)

```
lib/
  game/           # Pure-Dart-Spiellogik (KEINE Flutter-Imports)
    board.dart        # 8x8-Grid, Platzierung, Reihen-/Spalten-Clear
    piece.dart        # Blockformen-Definitionen
    generator.dart    # Gewichtetes, seed-bares Spawning (Fairness-Tuning)
    scoring.dart      # Punkte, Combos, Fieber-Meter
    daily.dart        # Seed aus Datum für Daily Challenge
  ui/             # Screens & Widgets
  monetization/   # Ads (Frequency Capping!), IAP
  services/       # Storage, Analytics, Audio, Haptik
test/             # Spiegelt lib/game/ — Logik hat Vorrang bei Testabdeckung
```

## Entwicklungs-Konventionen

- **Test-first für `lib/game/`**: Jede Logik-Änderung braucht Unit-Tests.
  Board-Zustände in Tests als ASCII-Strings notieren (lesbar!).
- `flutter analyze` und `flutter test` müssen vor jedem Commit grün sein.
- Deutsch für Nutzer-Texte (mit `intl`-Vorbereitung für EN), Englisch für Code,
  Kommentare und Commit-Messages.
- Keine Assets mit unklarer Lizenz — nur selbst erstellt oder CC0 (Kenney.nl,
  freesound.org); Quelle in `assets/CREDITS.md` festhalten.

## Monetarisierungs-Regeln (nicht verhandelbar; Stand Juli 2026)

- **Keine erzwungene Werbung.** Keine Interstitials, keine Banner — nirgends.
  Spielen (auch Neustart und Weiterspielen) erfordert NIE ein Video.
- **Rewarded Ads nur als freiwilliger Bonus** (Münzen verdoppeln, Lucky Block,
  Streak-Reparatur, Sparschwein früher öffnen, Rätsel-Extra-Zug). Immer
  optional, geben immer die versprochene Belohnung.
- Revive („Weiterspielen") kostet Münzen (`BoosterCosts.revive`), nie Werbung.
- Das Sparschwein ist eine Belohnung: voll = gratis ausschütten; vorzeitig
  öffnen optional per Bonus-Video. Es ist KEIN Kaufprodukt.
- IAP: Unterstützer-Paket (`qubble_supporter`, non-consumable: exklusives
  Theme + Skin + Münzen + ❤️), Münzpakete, Starter-Paket. Exklusive Kosmetik
  (`supporterOnly`) ist nie für Münzen erhältlich.
- Vor dem ersten Ad-Request: UMP-Consent-Flow (DSGVO) durchlaufen.
- In Debug-Builds ausschließlich AdMob-Test-Ad-Unit-IDs verwenden.
- **Spieler bekommen NIE Cheat-/Admin-Zugriff:** Admin-/Test-Funktionen
  (Münz-Cheats etc.) sind doppelt mit `kDebugMode`/`kReleaseMode` verriegelt
  (UI + Controller). Der öffentliche Web-Build nutzt `LockedIap` — er darf
  niemals Käufe/Münzen gratis ausliefern (Bestenlisten-Fairness). Diese
  Riegel dürfen nicht entfernt oder aufgeweicht werden.

## Umgebung (Cloud-Sessions)

Flutter ist in frischen Cloud-Umgebungen NICHT vorinstalliert. Falls `flutter`
fehlt: zuerst `scripts/setup.sh` ausführen (wird in Phase 0 erstellt und als
SessionStart-Hook registriert). Ohne lauffähiges `flutter test` keine
Logik-Änderungen committen.

## Befehle

```bash
flutter pub get          # Dependencies
flutter test             # Alle Tests (müssen grün sein)
flutter analyze          # Linting
flutter run              # Lokal starten (Emulator/Device)
flutter build appbundle  # Android-Release (Play Store)
flutter build ipa        # iOS-Release (App Store)
```

## Was Claude bei jeder Session tun soll

1. `MASTERPLAN.md` lesen → aktuelle Phase und offene Checkboxen identifizieren
2. Am nächsten offenen Punkt der Phase arbeiten (nicht Phasen überspringen)
3. Tests schreiben/aktualisieren, `flutter analyze` + `flutter test` grün halten
4. Erledigte Checkboxen in `MASTERPLAN.md` abhaken, committen, pushen
