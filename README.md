# Qubble — Block Puzzle (Flutter, iOS + Android)

Qubble ist ein Block-Puzzle im Stil von Block Blast! / Woodoku: Blockformen
auf ein 8×8-Raster ziehen, volle Reihen und Spalten abräumen, Highscores jagen.
Eine Codebase (Flutter) für iOS, Android und Web. Monetarisierung über AdMob
(Interstitial + Rewarded) und In-App-Käufe. **Komplett offline** — kein Backend,
kein Server.

Produkt- und Phasenplan mit aktuellen Checkboxen: siehe **`MASTERPLAN.md`**.
Entwicklungs-Konventionen: **`CLAUDE.md`**.

## Features

**Gameplay**
- 8×8-Board, Drag & Drop mit Platzierungs-Vorschau, seed-barer Fair-Generator
- Scoring mit Combos und Fieber-Meter, All-Clear-Bonus
- Endlos-Modus + tägliche Challenge (seed-basiert, für alle gleich)
- **Rätsel-Modus**: seed-generierte, per Bitboard-Solver validierte Level mit
  3-Sterne-Wertung (unendlicher Content ohne Content-Kosten)

**Retention**
- Daily-Streak mit Streak-Schutz (1 verpasster Tag heilbar)
- Missionen, Spieler-Level (XP), Statistik-Screen
- Lokale Benachrichtigungen (offline): Daily-Reminder, Streak-Warnung, Comeback
- In-Game-Booster: Undo, Teil-Tausch, Board-Bombe

**Game Feel**
- Partikel beim Clearen, Score-Popups, Screen-Shake, All-Clear-Feier
- Haptik, selbst erzeugte Sound-Effekte, Combo-Sound-Eskalation
- Themes (4) und Block-Skins (4), per Münzen freischaltbar

**Monetarisierung**
- AdMob Interstitial (Frequency Capping) + Rewarded (Revive, Lucky Block,
  Münzen verdoppeln, Extra-Zug), UMP/DSGVO-Consent
- IAP: Werbefrei, Münzpakete, Sparschwein, Starter-Paket
- Wochenend-Event (doppelte Münzen), Münz-Ökonomie mit Boostern/Kosmetik

## Architektur

Spiellogik strikt von der UI getrennt und vollständig unit-getestet:

```
lib/
  game/           # Pure Dart, KEINE Flutter-Imports (board, piece, generator,
                  # scoring, session, daily, streak, missions, leveling, stats,
                  # puzzle+solver, piggy_bank, starter_offer, weekend_event,
                  # block_skin)
  ui/             # Screens, Widgets, Riverpod-Controller
  monetization/   # ad_gate (Capping), ads, iap, ad_config
  services/       # storage, audio, haptics, notifications, analytics
test/             # spiegelt lib/ — 194 Tests
```

State: Riverpod. Persistenz: `shared_preferences` (lokal). Ads:
`google_mobile_ads`. IAP: `in_app_purchase`. Benachrichtigungen:
`flutter_local_notifications`.

## Entwickeln & Testen

Flutter (stable) vorausgesetzt. In frischen Cloud-Umgebungen: `scripts/setup.sh`.

```bash
flutter pub get
flutter analyze     # muss sauber sein
flutter test        # 194 Tests, müssen grün sein
flutter run         # Emulator/Gerät
flutter run -d chrome   # Web (lokales Testen, siehe docs/LOCAL-TESTING.md)
```

## Weiterführende Docs

| Datei | Inhalt |
|---|---|
| `MASTERPLAN.md` | Produkt-/Phasenplan, Spiel-Spezifikation (Anhang A–C) |
| `docs/LOCAL-TESTING.md` | Lokal auf PC + iPhone testen (Web-Version) |
| `docs/SETUP-ACCOUNTS.md` | Store-/AdMob-/Firebase-Konten (die 👤-Schritte) |
| `docs/RELEASE.md` | Build & Signing (Play-Store-first) |
| `docs/STORE-LISTING.md` | ASO-Texte (DE + EN), Screenshot-Plan |
| `docs/PRIVACY-POLICY.md`, `docs/IMPRESSUM.md` | Rechtstexte (Vorlagen) |
| `docs/NOTIFICATIONS.md` | Benachrichtigungen: Setup + Geräte-Verifikation |

## Status

Phasen 0–3 (spielbarer MVP, Game Feel, Monetarisierung) und Phase 6 (Tiefe &
Profit) sind **code-seitig abgeschlossen**; Debug-Builds laufen mit AdMob-Test-
IDs. Offen sind die menschlichen Schritte (👤): Entwickler-Konten, echte
AdMob-/IAP-IDs, Firebase-Config, Store-Upload — dokumentiert in `docs/`.

Assets: App-Icon und Sound-Effekte sind selbst erstellt (CC0-äquivalent), siehe
`assets/CREDITS.md`.
