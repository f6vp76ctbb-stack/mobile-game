# HANDOVER — Projektstand Qubble (Übergabeblatt für neue Sessions)

> **Für Claude:** Dieses Dokument ist die vollständige Übergabe aus der
> bisherigen Entwicklungs-Session (Juli 2026). Zuerst lesen, dann
> `CLAUDE.md` + `MASTERPLAN.md`. Der Nutzer spricht Deutsch; Antworten auf
> Deutsch, Code/Kommentare/Commits auf Englisch.

---

## 1. Was das Projekt ist

**Qubble** — Block-Puzzle (Genre Block Blast!/Woodoku) für App Store + Play
Store, gebaut mit **Flutter** (eine Codebase für iOS/Android/Web).
Monetarisierung: AdMob (Interstitial + Rewarded) + IAP. Ziel: profitabel bei
minimalen Kosten.

| Feld | Wert |
|---|---|
| App-Name | **Qubble** (vorher „GridPop" — umbenannt, da Name vergeben) |
| Publisher/Entwicklername | **Thinkube** |
| Bundle-/Application-ID | `com.thinkube.qubble` |
| Interner Dart-Paketname | `gridpop` (**absichtlich** nicht umbenannt — unsichtbar für Nutzer, Imports heißen `package:gridpop/...`) |
| Repo | `f6vp76ctbb-stack/mobile-game` (öffentlich!) |
| Arbeitsbranch | `claude/handover-continuation-ir2f40` (vorher `claude/app-store-game-idea-jn0blw`) |
| Live-URL (PWA) | https://f6vp76ctbb-stack.github.io/mobile-game/ |

**Namens-Check (👤 offen):** „Qubble"/„Thinkube" wirkten bei Recherche frei;
finale Store-/Markenprüfung liegt beim Nutzer. Fallback: „Qubble Blocks".

## 2. Workflow & Umgebung (so wird hier gearbeitet)

- **Flutter** liegt in Cloud-Sessions unter `$HOME/.flutter-sdk/bin` →
  `export PATH="$HOME/.flutter-sdk/bin:$PATH"`. Falls es fehlt:
  `scripts/setup.sh`.
- Vor jedem Commit: `flutter analyze` (0 issues) + `flutter test` (aktuell
  **245 Tests grün**). Web-Check: `flutter build web --release
  --no-web-resources-cdn`, optional Headless-Boot via `playwright-core`
  (Chromium unter `/opt/pw-browsers/chromium`, `--no-sandbox`).
- **Deploy-Pipeline:** Arbeit auf dem Arbeitsbranch → Commit → Push → PR
  nach `main` → **sofort selbst mergen** (vom Nutzer etabliert, PRs #3–#15
  liefen so). Push auf `main` triggert `deploy-web.yaml` → GitHub Pages
  (Source: GitHub Actions). PWA ist in ~3 Min. live.
- `deploy-web.yaml` hat `paths-ignore` für `leaderboard.json`, `FEEDBACK.md`,
  `**/*.md` (Action-Commits lösen keinen Redeploy aus) und **patcht den
  Service Worker** (SKIP_WAITING-Handler) für PWA-Auto-Update.
- `ci.yaml`: analyze + test bei jedem Push.
- **Sicherheitsregel (dauerhaft):** Vor jedem Commit gestagte Dateien prüfen —
  niemals Keystores (`*.jks`/`*.keystore`), `key.properties`,
  `google-services.json`, `GoogleService-Info.plist`, `.env` committen.
  Repo ist öffentlich!
- Test-Konventionen: Board-Zustände als ASCII-Strings; Fakes:
  `FakeAdService`, `SilentAudio`, `SilentMusic`, `Haptics(enabled:false)`,
  `NoopAnalytics`, `SharedPreferences.setMockInitialValues`.

## 3. Architektur (Kurzfassung; Details in CLAUDE.md)

- `lib/game/` = **pures Dart, keine Flutter-Imports**, voll unit-getestet:
  `board.dart` (8x8), `piece.dart` (+ `rotatedCw()`), `generator.dart`
  (seedbar), `scoring.dart` (zeitbasierte Combo), `game_session.dart`
  (Undo/Bombe/Rotation), `daily.dart`, `streak.dart`, `missions.dart`,
  `leveling.dart` (XP + Belohnungsspur), `stats.dart`, `puzzle.dart`
  (Generator + budgetierter Solver), `piggy_bank.dart`, `starter_offer.dart`,
  `weekend_event.dart`, `block_skin.dart`, `achievements.dart`.
- `lib/ui/state/` = Riverpod-Controller. Zentral: `game_controller.dart`
  (großer `GameSnapshot` mit ~35 Feldern, `GameController`).
  Provider-Overrides in `main.dart`.
- `lib/ui/screens/` = home, game, puzzle(+levels), themes, skins, missions,
  stats, achievements, shop, settings, leaderboard, feedback, name_entry.
- `lib/monetization/` = `ads.dart` (NUR Rewarded — **keine Interstitials,
  keine Banner**; Juli-2026-Rework auf Nutzerwunsch), `iap.dart` (Produkt-IDs
  `qubble_supporter`, `qubble_coins_s/m/l`, `qubble_starter`).
  `ad_gate.dart` wurde ersatzlos gelöscht.
- `lib/services/` = storage (shared_preferences), audio (SFX + Musik),
  haptics, analytics (Debug), notifications, feedback, leaderboard.

## 4. Spiel-Features (alle implementiert & getestet)

- **Endlos-Modus** + **Daily Challenge** (Datum-Seed, Streak + Streak-Reparatur)
- **Zeitbasierte Combo**: bricht NICHT mehr durch Nicht-Clear-Züge, sondern
  läuft **10 s** nach dem letzten Clear ab; UI-Countdown-Balken unter dem
  Combo-Badge. Fieber-Meter unverändert.
- **Rotation**: Tipp auf Tray-Teil dreht 90°. Frei bis Spielerlevel ≤ 2
  (nur Endlos; Daily immer mit Ladungen). Sonst Ladungen: Start 2, Max 3,
  +1 pro Clear-Zug. Undo stellt Ladungen wieder her.
- **Booster**: Undo 50 / Tausch 75 / Bombe 150 Münzen (zentral in
  `BoosterCosts`). Bombe = 3x3, mit Partikeln/Sound; Buttons ausgegraut ohne
  Guthaben.
- **Währungen (Juli 2026, sauber getrennt):** **Gold** = Spiel (Booster,
  Revive, Gold-Skins 1.200–2.200). **Diamanten** 💎 = Premium-Kosmetik (edle
  Skins, Relief 30/Glow 50); Bezug über Gold→Diamant-Tausch (100:1,
  `economy.dart`) — später Diamant-IAP. `storage.diamonds`,
  `trySpendDiamonds`/`exchangeGoldForDiamonds`; Skin trägt `SkinCurrency`.
  Diamant-Chip auf Home + Tausch-Karte im Skins-Screen. `DiamondIcon`/
  `DiamondAmount` in `app_icons.dart`.
- **Live-Münzen beim Spielen**: `kCoinsPerLine = 3` pro geräumter Reihe,
  + Combo-Bonus (+combo), + `kAllClearCoins = 25`. Sichtbar als
  „+N 🪙"-Popup überm Board (`coin_popup.dart`) + Live-Münzchip im Header.
  Zählt ins Runden-Ergebnis (`coinsEarnedThisRun`).
- **Level/XP** (`LevelSystem`): XP = score/100 (+50 Daily). Belohnungsspur
  (Cosmetics gratis durch Spielen): L3 Neon, L5 Verlauf, L8 Ocean,
  L12 Glanz, L16 Wood, L20 Kontur, L24 Sunset, L28 Forest, L32 Relief,
  L36 Glow, L40 Streifen. Level-Up: animierte Karte (Game-Over) + Chime
  (`levelup.wav`) + Haptik. Home zeigt nächstes Belohnungsziel.
- **7 Themes** (classic, neon, ocean, wood, sunset, forest + Aurora exklusiv
  im Unterstützer-Paket) / **8 Skins** (solid, gradient, glossy, outline,
  bevel, glow, stripe + Kristall exklusiv — Rendering in `cell_style.dart`).
- **Erfolge**: 17 Stück, lokal, `achievements.dart` (Metrik ≥ Schwelle);
  Screen über Statistik → „Erfolge"; frisch freigeschaltete am Game-Over.
- **Rätsel-Modus**: Level konstruktiv generiert (Bänder + ausgestanzte
  Löcher, ab Level 5 zwei Löcher/Band, mehr Teile mit steigendem Level).
  `minMoves == pieces.length` per Konstruktion; **Lösung wird mitgeliefert**
  (`Puzzle.solution`) und per billigem Replay verifiziert. Solver hat
  **Node-Budget** (hängt nie); Fehlschlag-Erkennung wertet Budget-Überlauf
  NICHT als „failed". Sterne: 3=optimal, 2=+2 Züge, 1=gelöst.
- **Sparschwein** (füllt sich pro Reihe; **voll = gratis ausschütten**,
  vorzeitig optional per Bonus-Video — seit Juli 2026 KEIN IAP mehr),
  **Starter-Paket** (48h-Angebot nach 5. Runde), **Wochenend-Event**
  (doppelte Münzen), **Missionen** (Fortschritt persistiert).
- **Unterstützer-Paket** (`qubble_supporter`, 4,99 €): exklusives
  Aurora-Theme + Kristall-Skin (`supporterOnly`, nie für Münzen) + 1.500
  Münzen + ❤️ neben dem Spielernamen. Ersetzt das frühere „Werbefrei"
  (überflüssig, da keine erzwungene Werbung mehr existiert).
- **Musik**: 42s-Lo-Fi-Loop, ruhig/leise (Volume 0.24), generiert via
  `scripts/gen_music.py` (pures Python, CC0/Eigenwerk — bei Änderungen neu
  generieren). SFX ebenfalls selbst synthetisiert (`assets/CREDITS.md`).
  Musik-Schalter in Einstellungen; Start nur nach User-Geste (Autoplay).
- **Menü-Partikel**: dezente Punkte im Home-Hintergrund
  (`menu_particles.dart`), themenfarben.
- **Onboarding**: Pflicht-**Namenseingabe** beim ersten Start
  (`NameEntryScreen` → `storage.playerName`, geräteweit, 2–14 Zeichen).
  Name ist danach **fix** — kein Gratis-Ändern (Nutzer-Entscheidung Juli
  2026). Umbenennen nur per Kauf: IAP `qubble_rename` (consumable, ~1,49 €)
  schreibt ein „Rename-Guthaben" gut (`storage.renameCredits`); Antippen des
  Namens öffnet den Kauf- bzw. mit Guthaben den Umbenennen-Dialog
  (`renameWithCredit`). 3 Coach-Hints in der ersten Runde.
- **Game-Over**: „Nochmal spielen" = Hauptaktion (immer gratis, ohne Werbung);
  Revive = kleiner Link für **200 Münzen** (1×/Runde) — NIE per Video.
  **Monetarisierungs-Grundsatz (Nutzer-Entscheidung Juli 2026): keine
  erzwungene Werbung; Videos nur als freiwilliger Bonus** (Münzen verdoppeln,
  Lucky Block, Streak-Reparatur, Sparschwein, Rätsel-Extra-Zug).
  Home-Button im Spiel-Header; laufende Runde → Home zeigt „Weiterspielen".

## 5. GitHub-Pipelines (kein Backend! Secrets-frei)

- **Feedback**: Einstellungen → „Feedback geben" → vorbefülltes GitHub-Issue
  (Label `feedback`) → `.github/workflows/feedback.yaml` hängt es an
  **`FEEDBACK.md`** an (nur Issues vom Repo-Owner; Text nur als Daten).
  `FEEDBACK.md` = Ideensammlung für spätere Umsetzung.
- **Bestenliste (seit 22.07.2026: Firestore, kontofrei!):**
  `LeaderboardService` spricht Firestore **per REST** (pure Dart + http,
  kein SDK — läuft identisch auf Native und Web-PWA, voll testbar):
  Lesen via runQuery (öffentlich), Eintragen unter **stiller anonymer
  Firebase-Identität** (Identity-Toolkit signUp beim ersten Submit,
  Refresh-Token in storage; Spieler sehen NIE einen Login). Server-Gate:
  `firebase/firestore.rules` (eigenes Dokument je uid, Name/Score validiert,
  Score nie senkbar). Firebase-Projekt „qubble", Konstanten in
  `lib/services/firebase_config.dart` (bewusst committet — keine Secrets).
  Analytics + Crashlytics: `firebase_boot.dart` (Conditional Import; Web =
  Stub ohne Firebase-SDK). Die alte GitHub-Issue-Pipeline ist entfernt
  (`leaderboard.yaml` gelöscht; `leaderboard.json` nur noch Archiv).
- **Admin-Modus (Test)**: In Einstellungen 7× auf die Fußzeile
  („Qubble • Offline Block Puzzle") tippen → Münzen +1.000/+10.000/auf 0.
  **Nur in Debug-Builds** (doppelt verriegelt: `kDebugMode` in der UI +
  `kReleaseMode`-No-op im Controller) — Spieler dürfen NIE Cheats bekommen.
  Ebenso: öffentlicher Web-Build nutzt `LockedIap` (keine Gratis-Käufe).

## 6. Web/PWA-Besonderheiten (wichtig!)

- **`kIsWeb` in `main.dart`**: Web nutzt `FakeAdService`, `FakeIap`, keine
  LocalNotifications (die echten Plugins werfen im Browser → hatte
  „Nochmal spielen" gebrochen). `newGameWithInterstitial` fängt Ad-Fehler ab.
  Native Builds nutzen die echten Services unverändert.
- **PWA-Auto-Update**: `web/index.html` pollt den Service Worker, sendet
  `SKIP_WAITING`, lädt bei `controllerchange` neu (+ Update-Check bei
  `visibilitychange`). Der Deploy-Workflow hängt den SKIP_WAITING-Handler an
  `flutter_service_worker.js` an. Nutzer wurde instruiert, das Home-Icon
  EINMAL neu anzulegen; seitdem kommen Updates automatisch.
- **Weißer Rand oben (iPhone)** gefixt: `theme-color` #12122A, dunkler
  body-Background, `viewport-fit=cover`, Status-Bar `black-translucent`.
- **Seitenübergänge**: eigener Fade (`_FadePageTransitionsBuilder` in
  `theme.dart`) — Material-„Zoom" ruckelte auf Web.
- **Drag&Drop (kritisches Wissen!)**: `DragTargetDetails.offset` ist die
  **linke obere Ecke des Feedback-Widgets**, nicht der Finger.
  `boardOriginForDrag()` in `board_view.dart` mappt direkt (Vorschau =
  Platzierung). Das `DragTarget` umfasst **Board + Booster + Tray**, weil das
  Teil `kFingerLiftCells = 1.2` Zellen über dem Finger schwebt (sonst wären
  untere Reihen unerreichbar). Gleiche Logik im Puzzle-Screen.
  Preview-State via `dragPreviewProvider`.
- **Partikel-Deckel**: Clear-Bursts max ~220 Partikel (Web-Canvas-Jank).
- **JS-Zahlen**: keine 64-Bit-Literale! Bitboards als `Mask(lo,hi)` mit
  2×32 Bit (`puzzle.dart`) — dart2js-kompatibel.

## 7. Nutzer-Feedback-Historie (alles umgesetzt)

Nutzer + ein Freund haben auf dem iPhone getestet. Behoben/gebaut u. a.:
Drag-Versatz & untere Reihen (Doppel-Offset-Bug), Bombe ohne Feedback,
Zurück-Button, Combo-Timer, mehr Partikel (+ Deckel nach Lag-Report),
Rotation, Musik (erst eintönig → neuer ruhigerer Loop), Textumbruch der
Menü-Buttons, Home-Hierarchie (BESTWERT + Play prominent, Logo/Profil
dezent), Statistik als visuelles Dashboard, Rätsel zu leicht → schwerer,
„Video-Zwang"-Eindruck entfernt, weißer iPhone-Rand, Menü-Partikel,
Live-Münzen, „Nochmal spielen"-Bug (Web). **Profile-Feature wurde gebaut und
auf Nutzerwunsch wieder ENTFERNT** (ein Name pro Gerät statt Multi-Profil).

## 8. Offene Punkte

**Entscheidungen des Nutzers:**
- **Firebase: ENTSCHIEDEN (22.07.2026)** — Analytics + Crashlytics +
  kontofreie Firestore-Bestenliste mit anonymer Auth (nie ein sichtbarer
  Login, kein E-Mail/Passwort). Umsetzung = Phase 7 Block 7 (D.7), wartet
  nur noch auf die `google-services.json` aus der Konsole (Play-Konto und
  AdMob hat der Nutzer bereits angelegt; Firebase-Projekt in Arbeit).
- Finaler **Marken-/Store-Namenscheck** Qubble/Thinkube (👤, offen)

**👤-Aufgaben (nur Nutzer kann sie; Anleitungen in `docs/`):**
- Apple-/Google-Developer-Konten, AdMob-Konto + echte Ad-Unit-IDs
  (`ad_config.dart`, Manifest, Info.plist), IAP-Produkte anlegen
  (`qubble_remove_ads`, `qubble_coins_s/m/l`, `qubble_piggy`,
  `qubble_starter`), Firebase-Config-Dateien, Datenschutz/Impressum hosten
  (Vorlagen in `docs/`), Screenshots, Signing-Key, Store-Uploads.
  iOS-Build braucht einen Mac.

**Nächste Code-Schritte (BEAUFTRAGT, Juli 2026):** `MASTERPLAN.md`
**Phase 7 — Release-Politur** abarbeiten (Blöcke 1–6 strikt der Reihe nach,
ein Block pro PR-Zyklus; verbindliche Specs in Anhang D). Vom Nutzer
ausdrücklich gewünscht: „komplett überprüfen, was wir grundlegend verbessern
können, damit das Spiel zum Release richtig gut wird."
- ~~Shop-Vorschau verbessern (Mini-Board-Preview für Themes/Skins)~~ ✅ PR #17
- `FEEDBACK.md` regelmäßig prüfen (Feedback-Issues des Nutzers)

## 9. Wichtige Dateien-Landkarte

- `MASTERPLAN.md` — Phasenplan (code-seitig KOMPLETT; nur 👤-Punkte offen)
  + verbindliche Specs (Anhang A/B/C)
- `CLAUDE.md` — Arbeitsregeln (Test-first für `lib/game/`, analyze+test grün,
  deutsche Nutzertexte, CC0-Assets, Ad-Regeln)
- `docs/` — SETUP-ACCOUNTS, RELEASE, STORE-LISTING (ASO-Texte DE/EN),
  PRIVACY-POLICY, IMPRESSUM, NOTIFICATIONS, LOCAL-TESTING, DEV-ENVIRONMENT
- `FEEDBACK.md` / `leaderboard.json` — von Actions gepflegt
- `.github/workflows/` — ci, deploy-web, feedback, leaderboard
- `scripts/` — setup.sh, gen_music.py
- `assets/CREDITS.md` — alle Assets Eigenwerk/CC0 (Pflicht bei neuen Assets)

## 10. Zahlen zum Stand

- **245 Tests grün**, `flutter analyze` sauber (Stand: letzter Merge PR #17)
- Merged PRs dieser Session: #3 Rename+Deploy, #4 Playtest-Fixes/Features,
  #5 Admin+Partikel-Cap, #6 (Profile, später entfernt), #7 Belohnungsspur,
  #8 Feedback+Fade, #9 Name+Leaderboard+PWA-Update, #10 Freund-Feedback,
  #11 Menü-Partikel, #12 Level-Up-Sound+2 Themes, #13 Erfolge,
  #14 3 Skins, #15 Web-Restart+Live-Münzen+Musik
- Folge-Session (Juli 2026): #17 Mini-Board-Previews für Theme-/Skin-Shop
  (gemeinsames `MiniBoardPreview`-Widget, `test/widget/store_preview_test.dart`);
  Monetarisierungs-Rework „fair & werbearm" (Interstitials raus, Revive per
  Münzen, Sparschwein gratis, Unterstützer-Paket statt Werbefrei; Play-Konto +
  AdMob vom Nutzer angelegt, Firebase noch offen; geschlossener Test mit
  12 Testern/14 Tagen nötig → `docs/SETUP-ACCOUNTS.md` §7)
- Flutter stable 3.44.x / Dart 3.12.x; Riverpod 2.x (immutable Snapshots)
