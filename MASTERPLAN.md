# Masterplan: „GridPop" — Block-Puzzle für App Store & Play Store

> Arbeitstitel: **GridPop** (finaler Name wird vor Launch per ASO-Recherche festgelegt)

---

## 1. Die Idee (und warum genau diese)

**GridPop ist ein Block-Puzzle im Stil von Block Blast! / Woodoku:**
Der Spieler zieht Blockformen (Tetromino-artige Teile) auf ein 8×8-Raster. Volle Reihen
und Spalten werden abgeräumt und geben Punkte. Das Spiel endet, wenn kein Teil mehr
passt. Endlos-Highscore + tägliche Challenge.

### Warum dieses Genre die richtige Wahl ist

| Kriterium | Bewertung |
|---|---|
| Marktnachweis | Block Blast! ist seit Jahren dauerhaft in den Top 5 der Free-Charts (iOS & Android), Woodoku/Blockudoku ebenso in den Top 100 — das Genre ist **bewiesen**, kein Experiment |
| Komplexität | Sehr gering: keine Physik, kein Multiplayer, kein Server nötig. Reine Logik + Animationen |
| Content-Kosten | Null laufender Content: Levels werden prozedural generiert, kein Level-Design-Team nötig |
| Grafik-Aufwand | Minimal: farbige Blöcke, Partikel-Effekte, ein Hintergrund. Kein Artist nötig |
| Monetarisierung | Genre hat nachweislich hohe Ad-Verträglichkeit (Interstitials zwischen Runden) + Rewarded Ads passen organisch rein (Revive, Booster) |
| Retention | Block-Puzzles haben die höchsten D30-Retention-Werte im Casual-Segment („nur noch eine Runde"-Effekt) |
| Rechtlich | Das Genre ist etabliert und frei — 1010!, Woodoku, Blockudoku, Block Blast koexistieren. Wichtig: eigene Grafiken, eigener Name, kein Kopieren von Assets |

### Ehrliche Einordnung

Kein Plan garantiert Erfolg — der Casual-Markt ist umkämpft. Aber diese Idee maximiert
die Wahrscheinlichkeit, weil sie **das nachweislich erfolgreichste Simple-Game-Genre**
mit **minimalen Kosten** und **null laufendem Content-Aufwand** kombiniert. Selbst ein
Mittelfeld-Ergebnis generiert bei diesem Genre passives Werbe-Einkommen. Der größte
Hebel ist nicht die Idee, sondern **Polish (Game Feel) + ASO + Retention-Tuning** —
genau dafür ist dieser Plan da.

### Unser Differenzierungs-Hook (nicht nur ein Klon)

1. **Daily Challenge mit Streak-System** — jeden Tag ein festes, für alle gleiches
   Puzzle (seed-basiert). Streaks treiben tägliche Wiederkehr (D1/D7-Retention).
2. **Combo-Fieber** — Mehrfach-Clears in Folge bauen ein „Fieber"-Meter auf:
   Bildschirm glüht, Punkte-Multiplikator, satte Effekte. Maximaler Dopamin-Loop.
3. **Lucky Block** — 1× pro Runde kann der Spieler per Rewarded Ad ein Wunsch-Teil
   ziehen. Organische, nicht nervige Ad-Integration.
4. **Zen-Polish** — beruhigende Farbwelt, haptisches Feedback, perfekte Animationen.
   Im Genre gewinnt, wer sich am besten *anfühlt*.

---

## 2. Monetarisierung

**Ziel-Mix: ~80 % Werbung, ~20 % In-App-Käufe** (genre-typisch).

### Werbung (AdMob, später ggf. Mediation)

| Format | Platzierung | Regel |
|---|---|---|
| Interstitial | Nach Game Over, vor neuer Runde | Frühestens ab Runde 3, max. 1 pro 90 Sekunden — nicht die Retention töten |
| Rewarded Video | „Revive" nach Game Over (Board wird teilweise geleert) | Kernstück — höchste eCPMs, freiwillig |
| Rewarded Video | „Lucky Block" (Wunsch-Teil ziehen) | 1× pro Runde |
| Banner | Optional, nur im Hauptmenü | Erst nach Launch testen, im Spiel selbst NIE |

### In-App-Käufe

| Produkt | Preis | Typ |
|---|---|---|
| **Werbefrei** (behält Rewarded-Optionen!) | 4,99 € | Non-Consumable — der wichtigste IAP im Genre |
| Münzpaket S/M/L | 0,99 / 2,99 / 7,99 € | Consumable |
| Starter-Paket (einmalig, ab Runde 5) | 1,99 € | Consumable — 1200 Münzen + Wood-Theme (Anhang C.6) |
| Sparschwein öffnen | 2,99 € | Consumable — füllt sich beim Spielen (Anhang C.5) |
| Münzen kaufen: Revive, Undo, Teil-Tausch, Board-Bombe | — | Booster-Ökonomie |
| Themes (Holz, Neon, Pastell, Dark) | via Münzen | Kosmetik, treibt Münz-Nachfrage |

---

## 3. Technik-Stack (auf minimale Kosten optimiert)

| Baustein | Wahl | Begründung |
|---|---|---|
| Framework | **Flutter** (eine Codebase für iOS + Android) | Kostenlos, perfekt für Grid-basierte 2D-Games, kein Unity-Splash/Lizenz-Thema, hervorragend automatisiert testbar |
| Sprache | Dart | — |
| Werbung | `google_mobile_ads` (AdMob) | Kostenlos, Standard |
| IAP | `in_app_purchase` (offizielles Plugin) | Beide Stores mit einer API |
| Speicherung | `shared_preferences` (lokal) | **Kein Server = keine laufenden Kosten** |
| Analytics | Firebase Analytics + Crashlytics (Gratis-Tier) | Retention/Funnel messen, Abstürze sehen |
| Audio | `audioplayers` + haptisches Feedback | Game Feel |
| Sounds/Grafik | Eigene generierte Assets + CC0-Quellen (Kenney.nl, freesound.org) | 0 € |
| State | Riverpod oder simples ChangeNotifier | Klein halten |

### Fixkosten (einmalig/jährlich)

| Posten | Kosten |
|---|---|
| Apple Developer Program | 99 €/Jahr |
| Google Play Console | 25 € einmalig |
| Server/Backend | **0 €** (alles lokal + Firebase-Gratis-Tier) |
| Assets | **0 €** (CC0 + selbst generiert) |
| **Summe Jahr 1** | **~125 €** |

Optional später: ~50–200 € für Icon-Design/ASO-Screenshots (Fiverr), kleine UA-Tests.

---

## 4. Spieldesign im Detail

### Core Loop
1. 3 zufällige Teile erscheinen unten
2. Spieler zieht sie aufs 8×8-Board
3. Volle Reihen/Spalten poppen (Punkte, Partikel, Sound, Haptik)
4. Neue 3 Teile — bis nichts mehr passt
5. Game Over → Highscore → Revive-Angebot (Rewarded) → neue Runde (Interstitial)

### Scoring
- Platzieren: 1 Punkt pro Zelle
- Clear: 10 Punkte pro Zelle, ×2/×3/×4 bei Mehrfach-Reihen
- Combo (Clears in aufeinanderfolgenden Zügen): steigender Multiplikator + Fieber-Meter
- „All Clear" (Board leer): +300 Bonus

### Fairness-Tuning (der geheime Erfolgsfaktor)
Reines Zufalls-Spawning frustriert. Wie die Top-Titel nutzen wir **gewichtetes
Spawning**: Der Generator prüft, ob mindestens eine der 3 Figuren platzierbar ist,
und erhöht in Frühphasen einer Runde die Chance auf „gut passende" Teile. Spät in
der Runde wird es ehrlich-schwer. Dieses Tuning wird per Analytics iteriert
(Ziel: durchschnittliche Session ≥ 8 Minuten).

### Progression & Retention
- Tages-Challenge (seed-basiert, für alle gleich) + Streak-Kalender
- Bestenliste: Game Center / Google Play Games (kostenlos, kein eigener Server)
- Themes als Sammel-/Spar-Ziel
- Sanfte Missionen („Räume 20 Reihen ab") für Münzen

---

## 5. Phasenplan

**Legende:** Punkte ohne Markierung erledigt Claude selbstständig.
Punkte mit **👤 DU** kann nur der Mensch erledigen (Accounts, Zahlungen, Store-Konsolen) —
Claude bereitet dafür alles vor und schreibt Schritt-für-Schritt-Anleitungen.
Claude arbeitet die Phasen strikt der Reihe nach ab und überspringt 👤-Punkte,
bis der Mensch sie als erledigt markiert.

### Phase 0 — Projekt-Bootstrap (einmalig)
- [x] Setup-Skript `scripts/setup.sh` erstellen, das Flutter SDK (stable) in der
      Cloud-Umgebung installiert und `flutter pub get` ausführt
      (SessionStart-Hook-Registrierung: siehe `docs/DEV-ENVIRONMENT.md`, braucht
      einmalige Nutzer-Freigabe)
- [x] Flutter-Projekt anlegen (`flutter create`, Org-Platzhalter `com.gridpopgame`,
      Projektname `gridpop`), Verzeichnisstruktur aus `CLAUDE.md`, strikte Lints
- [x] CI-Workflow (GitHub Actions): `flutter analyze` + `flutter test` bei jedem Push
- [ ] 👤 DU: Finalen App-Namen und Bundle-ID/Org festlegen (Claude macht ASO-Namensvorschläge)

### Phase 1 — MVP (Woche 1–2)
- [x] Game-Engine (pure Dart): Board + Clear-Logik, Teile-Katalog, Generator, Scoring
- [x] Unit-Tests für die komplette Spiellogik (Board, Piece, Generator, Scoring, Daily, Session)
- [x] Drag & Drop (UI-Anbindung der Engine, mit Vorschau-Highlight)
- [x] Scoring-Anbindung + Game Over + Highscore (lokal, `shared_preferences`)
- [x] Basis-UI: Menü, Spiel, Game-Over-Screen (Riverpod)
- [x] Widget-Smoke-Tests (Navigation + Rendering) — insgesamt 56 Tests grün

**Hinweis:** „Weiterspielen" ist seit Phase 3 eine echte Rewarded-Ad (Revive).

### Phase 2 — Game Feel & Retention (Woche 3–4)
- [x] Haptik (`services/haptics.dart`, an Platzieren/Clear/Fieber/Game-Over gekoppelt)
- [x] Combo-Fieber sichtbar: Fieber-Glow ums Board, Combo-Puls-Animation, Fieber-Bar
- [x] Daily Challenge + Streak (`streak.dart`, seed-basiert, mit Münz-Belohnung) — getestet
- [x] Missionen (`missions.dart`, 5 Karriere-Missionen, Fortschritt persistiert) — getestet
- [x] Münz-Ökonomie: Belohnungen für Daily + Missionen, Münz-Anzeige, Persistenz
- [x] Missions-Screen + Home-Screen mit Münzen und Daily-Karte
- [x] Themes (Classic/Neon/Ocean/Wood) — swap-bares Farbsystem, per Münzen freischaltbar,
      Theme-Screen mit Vorschau; Board/Tray/Fieber ziehen die aktive Palette — getestet
- [x] Onboarding: 3 geführte Züge mit kurzen, an Aktionen gekoppelten Coach-Hinweisen
      (kein Text-Wand-Tutorial); nur beim allerersten Endless-Run — getestet
- [x] Partikel-Effekte beim Clearen (Partikel-Burst aus geräumten Zellen, Theme-Farbe)
- [x] Sounds: selbst synthetisierte WAV-SFX (place/clear/combo/fever/gameover),
      `audioplayers`-Backend an das `AudioService`-Interface angebunden; in Tests
      bleibt `SilentAudio` aktiv. Lizenz in `assets/CREDITS.md` (Eigenwerk)

**Phase 2 abgeschlossen.**

### Phase 3 — Monetarisierung & Stores (Woche 5–6)
- [x] Anleitung für alle 👤-Schritte geschrieben (`docs/SETUP-ACCOUNTS.md`)
- [x] AdMob-Integration (Interstitial + Rewarded) mit zentralem Frequency Capping
      (`ad_gate.dart`, ab Runde 3 / max 1 pro 90 s) — Debug nutzt Test-IDs; getestet
- [x] Rewarded-Flows: „Revive" (Board-Mitte) und „Lucky Block" (neue Teile) als
      echte Rewarded-Ads; Belohnung immer freiwillig + garantiert — getestet
- [x] UMP/DSGVO-Consent-Flow vor dem ersten Ad-Request (`GoogleAdService`)
- [x] IAP-Code (Werbefrei non-consumable + Münzpakete consumable), Restore,
      Shop-Screen, Delivery-Handler; „Werbefrei" behält Rewarded — getestet
- [x] Analytics-Funnel-Events (game_start, round_complete, reach_round_3,
      daily_played, rewarded_watched, interstitial_shown, purchase) an
      `Analytics`-Interface angebunden (`DebugAnalytics` aktiv)
- [x] Native Config: AdMob-App-ID (Test) in AndroidManifest + Info.plist,
      INTERNET-Permission
- [ ] 👤 DU: Accounts anlegen — Apple Developer, Google Play, AdMob, Firebase (Anleitung s. o.)
- [ ] 👤 DU: Echte Ad-Unit-IDs + App-IDs eintragen (`ad_config.dart`, Manifest, Info.plist)
- [ ] 👤 DU: IAP-Produkte in beiden Konsolen anlegen (IDs aus `iap.dart` / Anhang A.5)
- [ ] 👤 DU: Firebase-Config-Dateien einchecken → dann bindet Claude das Firebase-Backend an
- [x] Eigenes App-Icon (Android-Mipmaps + iOS-Set via `flutter_launcher_icons`)
- [x] ASO-Texte DE + EN (`docs/STORE-LISTING.md`: Titel, Keywords, Beschreibungen)
- [x] Datenschutzerklärungs-Text (`docs/PRIVACY-POLICY.md`, hostbar)
- [x] Impressum-Vorlage (`docs/IMPRESSUM.md`) + In-App-Punkt (Einstellungen → Impressum)
- [ ] Screenshots: Aufnahme am Gerät/Emulator in Phase 4 (Plan + Captions liegen im Listing)
- [ ] 👤 DU: Datenschutzerklärung + Impressum hosten, Play-Datensicherheit + COPPA ausfüllen

### Phase 4 — Soft Launch (Woche 7–8)

**Strategie: Play Store zuerst** (Kosten: Google 25 € einmalig vs. Apple 99 €/Jahr).
iOS-/App-Store-Schritte kommen erst in Phase 5. Der Code läuft unverändert für beide.

- [x] Android-Signing-Config (liest `key.properties`, fällt ohne Keystore auf
      Debug-Keys zurück → baut immer), R8-Keep-Regeln bereit, Anzeigename „GridPop"
- [x] Release-/Build-Checkliste (`docs/RELEASE.md`, Play-first) inkl. Keystore,
      appbundle, Screenshots, Steuer-Vorbereitung, Soft-Launch-Schritte
- [ ] 👤 DU: Signing-Key erzeugen (`docs/RELEASE.md`), `flutter build appbundle`,
      App in Play Console hochladen, Soft Launch in 1–2 kleinen Märkten freischalten
- [ ] 👤 DU (erst bei Einnahmen): Gewerbe + Kleinunternehmer anmelden, Steuerdaten
      ins Google-Zahlungsprofil (`docs/SETUP-ACCOUNTS.md` §0 — Hobby-Test vorab ok)
- [ ] 👤 DU: Screenshots am Gerät/Emulator aufnehmen (Plan in `docs/STORE-LISTING.md`)
- [ ] KPIs messen (siehe unten), Fairness-Tuning & Ad-Frequenz iterieren
- [ ] Crashfrei-Rate > 99,5 %

### Phase 5 — Global Launch & Growth (ab Woche 9)
- [ ] iOS-Build (`flutter build ipa`); 👤 DU: Upload via App Store Connect, Review einreichen
- [ ] 👤 DU: Beide Stores weltweit freischalten
- [ ] ASO-Iteration (Keywords, Screenshot-A/B im Play Store)
- [ ] Organik pushen: TikTok/Shorts mit „satisfying"-Clips (Combo-Fieber ist genau dafür gebaut)
- [ ] Erst wenn LTV > CPI messbar: kleine Paid-UA-Tests

### Phase 6 — Tiefe & Profit: „Warum ich morgen wiederkomme" (parallel zu Soft Launch startbar)

Alles hier ist **offline-fähig** (keine Server-Regel bleibt) und pure-Dart-testbar.
Verbindliche Zahlen/Specs: **Anhang C**. Reihenfolge = Priorität (Impact ÷ Aufwand).

**Tier 1 — Retention-Kern (zuerst bauen)**
- [x] Booster im Spiel: Undo (50), Teil-Tausch (75), Board-Bombe (150) als
      Münz-Senken (C.1) — Engine (`undo()`/`bombAt()` mit Memento) + Booster-Leiste
      + Bomben-Ziel-Modus, getestet
- [x] Lokale Benachrichtigungen ohne Server (`flutter_local_notifications`):
      Daily-Reminder 19:00 + Streak-Warnung 21:30 + Comeback (72h) + Comeback-
      Geschenk; Opt-in beim 2. Start, Settings-Schalter (C.2). Planungs-Logik
      pure + getestet; native Zustellung auf Gerät verifizieren (`docs/NOTIFICATIONS.md`)
- [x] Streak-Schutz: 1 verpasster Tag heilbar (150 Münzen oder Rewarded Ad),
      max. 1×/7 Tage (C.2) — pure Logik + Home-Banner, getestet
- [x] „Münzen verdoppeln"-Rewarded auf dem Game-Over-Screen (C.7) — einmal pro
      Runde, getestet
- [ ] Juice-Pass II: Score-Popups am Clear-Ort, Screen-Shake bei 3+ Linien,
      All-Clear-Konfetti-Feier, Squash-Animation beim Landen (C.8)

**Tier 2 — Progression-Meta (macht aus Runden eine Reise)**
- [ ] Spieler-Level (XP) mit Level-Up-Belohnungen auf dem Home-Screen (C.3)
- [ ] Rätsel-Modus: seed-generierte, per Solver validierte Puzzle-Level mit
      3-Sterne-Wertung — endloser Content ohne Content-Kosten (C.4)
- [ ] Statistik-Screen: Bestwerte, Ø-Score, größte Combo, Gesamt-Linien
- [ ] Achievements + Bestenlisten via Google Play Games Services (kostenlos,
      kein Server); 👤 DU: in Play Console anlegen (C.9)

**Tier 3 — Monetarisierungs-Vertiefung (erst nach Retention-Daten)**
- [ ] Sparschwein: füllt sich beim Spielen, Öffnen per IAP (C.5)
- [ ] Starter-Paket: einmaliges Angebot ab Runde 5 (C.6)
- [ ] Wochenend-Event: Sa/So doppelte Missions-Münzen + Bonus-Daily (C.7)
- [ ] Block-Skins zusätzlich zu Themes (weitere Münz-Senke)

**Bewusst NICHT geplant** (Begründung festhalten, um Feature-Creep zu vermeiden):
Energie-System (killt die „entspannt"-Positionierung), Multiplayer/Clans
(bräuchte Server), Season Pass (zu früh — erst ab stabiler D30-Basis), Lootboxen
(Review-/Rechtsrisiko).

### KPI-Ziele (Soft Launch)

| Metrik | Minimalziel | Gut |
|---|---|---|
| D1-Retention | 30 % | 40 %+ |
| D7-Retention | 10 % | 15 %+ |
| Session-Länge | 6 min | 10 min+ |
| Sessions/Tag | 2 | 3+ |
| Rewarded-Engagement | 20 % der Spieler/Tag | 35 %+ |

Werden die Minimalziele verfehlt → erst Game Feel/Fairness tunen, nicht mehr Ads einbauen.

---

## 6. Risiken & Gegenmaßnahmen

| Risiko | Gegenmaßnahme |
|---|---|
| Sichtbarkeit im übersättigten Genre | ASO von Tag 1, Daily-Challenge-Hook, „satisfying"-Content für TikTok/Shorts, Soft Launch zum Lernen bevor Budget fließt |
| Zu aggressive Ads töten Retention | Frequency Capping ab Tag 1, Rewarded-first-Philosophie, Ad-Frequenz nur datengetrieben erhöhen |
| Store-Ablehnung | UMP-Consent, Privacy Labels, keine Tracking-Überraschungen; Checkliste in Phase 3 |
| „Nur ein Klon"-Wahrnehmung | Eigener Look, Combo-Fieber, Daily Streak — und kompromissloser Polish |

---

## 7. Nächster Schritt

Phase 0 starten: Setup-Skript + Flutter-Projekt aufsetzen, danach Phase 1
(Spiellogik test-getrieben bauen). Die Entwicklungs-Konventionen stehen in `CLAUDE.md`.

---

## Anhang A — Spiel-Spezifikation (verbindlich, keine freien Design-Entscheidungen)

### A.1 Teile-Set (Spawning-Gewichte)

| Teil | Formen | Basis-Gewicht |
|---|---|---|
| Einzelblock | 1×1 | 4 |
| Linien | 1×2, 1×3, 1×4, 1×5 (je horizontal + vertikal) | je 6 / 6 / 5 / 3 |
| Quadrate | 2×2, 3×3 | 6 / 3 |
| Rechtecke | 2×3, 3×2 | je 4 |
| L klein (4 Rotationen) | 3 Zellen im Winkel | je 5 |
| L groß (4 Rotationen) | 3×3-L (5 Zellen) | je 3 |
| S/Z (je 2 Rotationen) | 4 Zellen | je 3 |
| T (4 Rotationen) | 4 Zellen | je 4 |

Teile werden **nicht** vom Spieler rotiert (genre-üblich) — Rotationen sind eigene Teile.

### A.2 Generator-Regeln (Fairness)

1. Es spawnen immer 3 Teile gleichzeitig; neue erst, wenn alle 3 platziert sind.
2. **Rettungsregel:** Passt keines der 3 gewürfelten Teile aufs Board, wird das letzte
   durch das größte noch platzierbare Teil ersetzt. Existiert gar keins → Game Over ist legitim.
3. **Frühphase** (Züge 1–10 einer Runde): Gewichte von Teilen, die aktuell platzierbar
   sind, ×1,5. Danach reine Basis-Gewichte.
4. Der Generator ist vollständig durch `Random(seed)` bestimmt (Daily Challenge, Tests).

### A.3 Münz-Ökonomie (Startwerte, per Analytics tunen)

| Posten | Wert |
|---|---|
| Startguthaben | 100 Münzen |
| Revive (Board-Mitte 4×4 wird geleert, 1× pro Runde) | Rewarded Ad ODER 200 Münzen |
| Undo (letzter Zug) | 50 Münzen |
| Teil-Tausch (3 neue Teile) | 75 Münzen |
| Lucky Block (Wunsch-Teil) | Rewarded Ad, 1× pro Runde |
| Mission abgeschlossen | 20–50 Münzen |
| Daily Challenge geschafft | 50 Münzen (+10 pro Streak-Tag, max. +100) |
| Theme freischalten | 500–1000 Münzen |

### A.4 Screens (MVP)

1. **Home:** Play, Daily Challenge (mit Streak-Anzeige), Highscore, Themes, Settings-Zahnrad
2. **Game:** 8×8-Board, 3 Teile-Slots unten, Score oben, Combo-/Fieber-Meter, Pause
3. **Game Over:** Score, Bestwert, Revive-Angebot (einmalig), „Nochmal", Home
4. **Settings:** Sound, Musik, Haptik, Werbefrei-Kauf, Käufe wiederherstellen, Datenschutz/Impressum

### A.5 Technische Festlegungen

- Dart-Klassen: `Board` (immutable, `place()` gibt neues Board + `ClearResult` zurück),
  `Piece` (Liste von Zell-Offsets), `PieceGenerator`, `ScoreKeeper`, `DailyChallenge`
- Persistenz-Keys: `highscore`, `coins`, `streak`, `lastDailyDate`, `adFree`,
  `activeTheme`, `settings.*` — zentral in `lib/services/storage.dart`
- AdMob-Test-IDs im Debug-Build hart verdrahtet; echte IDs via `lib/monetization/ad_config.dart`
- IAP-Produkt-IDs: `gridpop_remove_ads`, `gridpop_coins_s`, `gridpop_coins_m`,
  `gridpop_coins_l`; ab Phase 6: `gridpop_starter`, `gridpop_piggy` (Anhang C)

## Anhang B — Was nur DU erledigen kannst (Übersicht)

Claude kann programmieren, testen, Texte/Anleitungen/Assets erstellen — aber **nicht**:
Accounts anlegen, Zahlungen tätigen, Verträge akzeptieren, Apps in den Konsolen hochladen.
Diese Punkte (alle im Phasenplan mit 👤 markiert):

1. Apple Developer Program beitreten (99 €/Jahr) + Google Play Console (25 €)
2. AdMob-Konto + App + Ad-Units anlegen; UMP-Consent-Meldung in AdMob konfigurieren
3. Firebase-Projekt anlegen, Config-Dateien herunterladen und ins Repo geben
4. IAP-Produkte in beiden Store-Konsolen anlegen (IDs aus Anhang A.5)
5. Datenschutzerklärung hosten; Privacy-/Datensicherheits-Formulare ausfüllen
6. Signing-Key erzeugen und sicher verwahren; Builds hochladen und Releases freischalten
7. Steuer-/Bankdaten in beiden Konsolen hinterlegen (sonst kein Payout!)

Für jeden dieser Punkte legt Claude in Phase 3 eine Klick-für-Klick-Anleitung
unter `docs/` ab.

---

## Anhang C — Spezifikation Phase 6 (verbindlich)

### C.1 Booster im Spiel (Münz-Senken)

UI: Booster-Leiste unter dem Tray (3 Buttons mit Münzpreis-Badge).

| Booster | Kosten | Wirkung | Regeln |
|---|---|---|---|
| Undo | 50 | Macht genau den letzten Zug rückgängig (Board, Tray, Score, Combo, Fieber) | Max. 1× in Folge; nicht nach Clear-Animation-Start eines neuen Zugs |
| Teil-Tausch | 75 | Ersetzt die aktuellen Tray-Teile durch 3 neue | Beliebig oft; nutzt den normalen Generator (kein Wunschteil — das bleibt Lucky Block/Rewarded) |
| Board-Bombe | 150 | Spieler wählt eine Zelle; 3×3 darum wird geleert | Gibt keine Punkte; bricht die Combo nicht; max. 1× pro Zug |

Engine-Anforderung: `GameSession` bekommt `undo()` (ein Schritt Historie),
`bombAt(Cell)` — beides pure Dart + Tests.

### C.2 Lokale Benachrichtigungen & Streak-Schutz (kein Server!)

Paket: `flutter_local_notifications`. Opt-in-Dialog erst beim **zweiten**
App-Start (nicht beim ersten). In Einstellungen abschaltbar.

| Notification | Zeitpunkt | Bedingung | Text-Idee |
|---|---|---|---|
| Daily-Reminder | 19:00 lokal | Daily heute nicht gespielt | „Dein Puzzle des Tages wartet 🧩" |
| Streak-Warnung | 21:30 lokal | Streak ≥ 3 UND Daily offen | „🔥 {n}-Tage-Streak in Gefahr!" |
| Comeback | einmalig nach 72 h Inaktivität | — | „Wir haben 100 Münzen für dich 🪙" (beim Öffnen gutschreiben) |

**Streak-Schutz:** Genau 1 verpasster Tag kann geheilt werden — beim nächsten
Öffnen Angebot: Rewarded Ad ODER 150 Münzen. 2+ Tage verpasst → Streak bricht
normal. Max. 1 Heilung pro 7 Tage (sonst verliert der Streak seine Bedeutung).

### C.3 Spieler-Level (XP)

- XP pro Runde: `score / 100` (abgerundet), Daily-Abschluss: +50 XP extra.
- Level-Kurve: Level *n* → *n+1* braucht `100 + 50·n` XP.
- Level-Up-Belohnung: `20 + 5·n` Münzen; jedes 5. Level schaltet einen
  Block-Skin frei (C-Tier-3).
- Anzeige: Home-Screen (Level-Ring um den Titel oder Badge), Level-Up-Feier
  auf dem Game-Over-Screen.
- Persistenz-Keys: `xp`, `playerLevel`.

### C.4 Rätsel-Modus (seed-generiert, Solver-validiert)

- Level *k* wird deterministisch aus Seed `0xR47SEL + k` generiert:
  vorgefülltes Board (30–60 % Füllung, steigend) + feste Teilfolge.
- Ziel: „Board komplett leeren" in ≤ M Zügen. Sterne: 3 = optimal
  (Solver-Minimum), 2 = +2 Züge, 1 = geschafft.
- **Generator-Regel:** Ein Level wird nur akzeptiert, wenn der eingebaute
  Solver (Brute-Force über Teilfolge, pure Dart) es in ≤ M Zügen löst —
  unlösbare Level sind damit ausgeschlossen. Tests decken die ersten 50 Level ab.
- Belohnung: 10 Münzen pro Level, +25 Bonus alle 10 Level. Rewarded Ad:
  „Extra-Zug" (einmal pro Level).
- Kein Content-Aufwand: unendlich viele Level aus dem Generator.

### C.5 Sparschwein

- Füllung: +1 Münze pro geräumter Linie (zusätzlich zur normalen Ökonomie,
  landet **nur** im Schwein).
- Kapazität: 500 (Stufe 1) → nach jedem Öffnen +500, max. 3000.
- Öffnen: IAP `gridpop_piggy` (2,99 €) — schüttet den Inhalt aus.
- UI: dezentes Icon auf Home mit Füllstand; Hinweis-Badge erst ab 80 % Füllung.
  **Nie** blockierend/Popup-Spam — Positionierung „entspannt" schützen.

### C.6 Starter-Paket

- Trigger: einmalig nach Runde 5 (genug Bindung, früh genug für Conversion).
- Inhalt: 1200 Münzen + Wood-Theme. Preis 1,99 € (`gridpop_starter`).
- Anzeige: eine Karte auf dem Game-Over-Screen + Eintrag im Shop, 48 h gültig
  (lokaler Timer), danach dauerhaft weg — echte Knappheit, kein Fake-Countdown-Reset.

### C.7 Zusätzliche Rewarded-Platzierungen & Events

- **Münzen verdoppeln:** Game-Over-Screen, wenn `coinsEarnedThisRun > 0`:
  „Video ansehen → {n}×2 Münzen". Erwartbar höchstes Engagement.
- **Wochenend-Event (lokal, uhrbasiert):** Sa+So: Missions-Münzen ×2 und
  Daily-Belohnung ×2. Banner auf Home. Kein Server nötig — Gerätezeit reicht,
  Manipulation ist bei reinen Soft-Currency-Boni verschmerzbar.

### C.8 Juice-Pass II (Game Feel)

- Score-Popup am Clear-Ort („+120", floatet hoch, Theme-Farbe).
- Screen-Shake (subtil, 150 ms) ab 3 gleichzeitigen Linien.
- All-Clear: Konfetti-Partikel über das ganze Board + eigener Sound + Banner
  („BLITZBLANK! +300").
- Landen eines Teils: 80-ms-Squash (Scale 1.0→0.9→1.0).
- Combo-Sound-Eskalation: Tonhöhe steigt pro Combo-Stufe (bestehende SFX
  pitchen statt neue Assets).

### C.9 Achievements & Bestenlisten (Google Play Games)

- Kostenlos, kein eigener Server. Bestenlisten: „Endless-Highscore",
  „Längster Daily-Streak". ~12 Achievements (erste Runde, 10 Missionen,
  Level 10, 50er-Combo-Summe, All Clear, 7-Tage-Streak, …).
- 👤 DU: In der Play Console anlegen (IDs liefert Claude als Liste).
- iOS-Pendant (Game Center) erst beim App-Store-Gang.

### C.10 KPI-Ziele Phase 6 (zusätzlich zu Soft-Launch-KPIs)

| Metrik | Ziel |
|---|---|
| D30-Retention | ≥ 8 % |
| Notification-Opt-in | ≥ 45 % |
| Rewarded/DAU („verdoppeln" + Revive + Lucky) | ≥ 1,2 Views |
| Anteil Spieler mit ≥ 1 Booster-Einsatz/Woche | ≥ 25 % |
| Starter-Pack-Conversion (von Sehern) | ≥ 2 % |
