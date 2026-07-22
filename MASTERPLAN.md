# Masterplan: „Qubble" — Block-Puzzle für App Store & Play Store

> Arbeitstitel: **Qubble** (finaler Name wird vor Launch per ASO-Recherche festgelegt)

---

## 1. Die Idee (und warum genau diese)

**Qubble ist ein Block-Puzzle im Stil von Block Blast! / Woodoku:**
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

## 2. Monetarisierung (überarbeitet Juli 2026: „fair & werbearm")

**Bewusste Positionierung gegen den Genre-Standard:** Block Blast & Co.
verdienen fast alles über erzwungene Interstitials. Qubble macht das Gegenteil
— **keine erzwungene Werbung, nie**. Werbung ist immer ein freiwilliger Bonus.
Das kostet kurzfristig Werbe-Umsatz, ist aber unser Alleinstellungsmerkmal
(Reviews, Retention, Weiterempfehlung) und die explizite Produktentscheidung
des Eigentümers.

### Werbung (AdMob — NUR Rewarded, alle freiwillig)

| Platzierung | Wann | Regel |
|---|---|---|
| „Münzen verdoppeln" | Game-Over, wenn Münzen verdient | 1× pro Runde |
| „Lucky Block" (neue Teile) | Im Spiel | freiwillig |
| Streak-Reparatur | Alternative zu 150 Münzen | max. 1×/7 Tage |
| Sparschwein früher öffnen | Alternative zum Gratis-Öffnen bei voll | freiwillig |
| Rätsel-Extra-Zug | Im Rätsel-Modus | 1× pro Level |

**Verboten:** Interstitials, Banner, „Video um weiterzuspielen". Revive kostet
Münzen (200), nie Werbung.

### In-App-Käufe

| Produkt | Preis | Typ |
|---|---|---|
| **Unterstützer-Paket** (Aurora-Theme + Kristall-Skin + 1.500 Münzen + ❤️-Abzeichen) | 4,99 € | Non-Consumable — ehrliches „Ich mag das Spiel"-Angebot |
| Münzpaket S/M/L | 0,99 / 2,99 / 7,99 € | Consumable |
| Starter-Paket (einmalig, ab Runde 5, 48h) | 1,99 € | Consumable — 1200 Münzen + Wood-Theme (Anhang C.6) |
| Münzen kaufen: Revive, Undo, Teil-Tausch, Board-Bombe | — | Booster-Ökonomie |
| Themes/Skins | via Münzen | Kosmetik, treibt Münz-Nachfrage |

Das Sparschwein ist seit Juli 2026 **kein IAP mehr**, sondern eine Belohnung
(voll = gratis ausschütten, optional per Bonus-Video früher; Anhang C.5).

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
- [x] Flutter-Projekt anlegen (`flutter create`, Org-Platzhalter `com.thinkube`,
      Projektname `gridpop`), Verzeichnisstruktur aus `CLAUDE.md`, strikte Lints
- [x] CI-Workflow (GitHub Actions): `flutter analyze` + `flutter test` bei jedem Push
- [x] Finalen App-Namen und Bundle-ID/Org festlegen: App **Qubble**, Publisher
      **Thinkube**, Bundle-ID `com.thinkube.qubble` (👤 finalen Marken-/Store-Check vor Launch)

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
- [x] AdMob-Integration — Debug nutzt Test-IDs; getestet.
      *(Juli 2026 überarbeitet: Interstitials + `ad_gate.dart` komplett
      entfernt — nur noch freiwillige Rewarded-Videos, siehe Abschnitt 2)*
- [x] Rewarded-Flows („Lucky Block", Münzen verdoppeln, Streak-Reparatur,
      Sparschwein, Rätsel-Extra-Zug); Belohnung immer freiwillig + garantiert
      — getestet. *(Revive kostet seit Juli 2026 Münzen statt Video)*
- [x] UMP/DSGVO-Consent-Flow vor dem ersten Ad-Request (`GoogleAdService`)
- [x] IAP-Code (Unterstützer-Paket non-consumable + Münzpakete consumable),
      Restore, Shop-Screen, Delivery-Handler — getestet.
      *(Juli 2026: „Werbefrei" durch Unterstützer-Paket ersetzt — es gibt
      keine erzwungene Werbung mehr, die man entfernen müsste)*
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
      Debug-Keys zurück → baut immer), R8-Keep-Regeln bereit, Anzeigename „Qubble"
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
- [x] Juice-Pass II: schwebende Score-Popups am Clear-Ort, Screen-Shake bei
      3+ Linien, All-Clear-Banner „BLITZBLANK!", Combo-Sound-Pitch-Eskalation (C.8)
      (Squash-Animation beim Landen bewusst weggelassen — Pulsen bei jedem Zug
      wirkt schnell nervig; die vier Effekte oben liefern den „Juice")

**Tier 2 — Progression-Meta (macht aus Runden eine Reise)**
- [x] Spieler-Level (XP): Score/100 +50 fürs Daily, Kurve 100+50·n, Münz-Belohnung
      pro Level, Home-Badge mit XP-Balken, Level-Up-Feier im Game-Over (C.3) — getestet
- [x] Rätsel-Modus: seed-generierte, Solver-validierte Level, 3-Sterne-Wertung,
      Level-Auswahl mit Fortschritt, Münz-Belohnung (10/Level, +25 alle 10),
      „Extra-Zug"-Rewarded, Bitboard-Solver erkennt Sackgassen (C.4) — getestet
- [x] Statistik-Screen: Bestwert, Level, Runden, Ø-Score, größte Combo, Gesamt-
      Linien/-Teile, Rätsel gelöst/Sterne, Münzen (Lifetime-Stats getestet)
- [ ] Achievements + Bestenlisten via Google Play Games Services (kostenlos,
      kein Server); 👤 DU: in Play Console anlegen (C.9)

**Tier 3 — Monetarisierungs-Vertiefung (erst nach Retention-Daten)**
- [x] Sparschwein: füllt sich (+1/Reihe) beim Spielen, Kapazität wächst pro
      Öffnung (max 3000), Öffnen per IAP `qubble_piggy`, Home-Chip mit
      Füll-Hinweis ab 80 % (C.5) — getestet
- [x] Wochenend-Event: Sa/So verdoppelt Missions- + Daily-Münzen (uhrbasiert,
      offline), Home-Banner (C.7) — getestet
- [x] Starter-Paket: einmaliges Angebot ab Runde 5, echtes 48-h-Fenster (kein
      Fake-Reset), 1200 Münzen + Wood-Theme für 1,99 € (`qubble_starter`),
      Game-Over-Karte (C.6) — getestet
- [x] Block-Skins (Classic/Verlauf/Glanz/Kontur), per Münzen freischaltbar,
      Skins-Screen mit Vorschau; Board + Tray rendern den aktiven Skin — getestet

**Phase 6 code-seitig abgeschlossen.** Offen nur noch 👤-Punkte:
Play-Games-Bestenlisten/Achievements, echte AdMob-/IAP-IDs, Firebase-Backend.

**Bewusst NICHT geplant** (Begründung festhalten, um Feature-Creep zu vermeiden):
Energie-System (killt die „entspannt"-Positionierung), Multiplayer/Clans
(bräuchte Server), Season Pass (zu früh — erst ab stabiler D30-Basis), Lootboxen
(Review-/Rechtsrisiko).

### Phase 7 — Release-Politur (geplant Juli 2026; für autonome Sessions)

Ziel: Das Spiel zum Release **richtig gut** machen (Nutzer-Auftrag). Jeder
Punkt ist eigenständig und ohne Nutzer-Input umsetzbar (offline, testbar);
verbindliche Detail-Specs stehen in **Anhang D**. Reihenfolge = Priorität —
Sessions arbeiten Blöcke strikt von oben nach unten ab, ein Block pro
PR-Zyklus (Commit → PR → Merge, wie etabliert). Vor jedem Commit:
`flutter analyze` + `flutter test` grün; neue Logik test-first.

**Block 0 — Release-Härtung ✅ (Juli 2026 erledigt)**
- [x] Admin-Modus (7-Tap, Münz-Cheats) debug-only: `kDebugMode`-Riegel im
      Settings-Screen + hartes No-op von `setCoinsForTest` im Release-Build
- [x] Öffentliche Web-PWA: `LockedIap` statt `FakeIap` — keine Produkte,
      keine Gratis-Lieferung (Bestenlisten-Fairness); Shop erklärt
      „Käufe nur in der App". Debug-Web behält `FakeIap` fürs Entwickeln
- [x] Release-Countdown-Tabelle (Code- + 👤-Spur verzahnt) in `docs/RELEASE.md`

**Block 1 — Onboarding & erste Runde (D.1)**
- [ ] Kontextuelle Coach-Hints: einmalige Hinweise beim ersten Combo
      (Countdown erklären), ersten Fieber, erster Rotation (Ladungen) und
      beim ersten leistbaren Booster — je einmal pro Gerät, persistiert
- [ ] „Wie spielt man?"-Screen: kompakte Regel-Übersicht (Platzieren, Clears,
      Combo-Timer, Fieber, Booster, Daily) aus reinen Widgets; erreichbar
      über Einstellungen UND ?-Icon auf dem Home-Screen
- [ ] Sanfte erste Runde: verlängerte Generator-Frühphase für die allererste
      Endlos-Runde (D.1.3) — seed-bar, pure Dart, getestet

**Block 2 — Englische Lokalisierung (D.2)**
- [ ] `intl`/ARB-Infrastruktur: `flutter_localizations` + `l10n.yaml`,
      `app_de.arb` als Quelle, ALLE Nutzer-Strings extrahieren
- [ ] `app_en.arb` vollständig übersetzen (Ton: freundlich-knapp wie DE)
- [ ] Sprachwahl: System-Locale als Default + manueller Schalter (System/DE/EN)
      in den Einstellungen, persistiert

**Block 3 — Daily-Challenge-Politur (D.3)**
- [ ] Gespielte Daily-Tage persistieren (`dailyDatesPlayed`, gekappt) und
      Daily-Bereich zum eigenen Screen ausbauen: Monats-Kalender mit
      Häkchen-Tagen, Streak, Daily-Bestwert
- [ ] Teilen-Button am Daily-Game-Over: Emoji-Ergebnis-Text (D.3.2) via
      `share_plus` — viraler Loop ohne Server
- [ ] Home: Countdown „Nächstes Daily in HH:MM" wenn heute schon gespielt

**Block 4 — Ökonomie- & Fairness-Absicherung (D.4)**
- [ ] Ökonomie-Simulationstest: Greedy-Bot über ≥ 50 Seeds misst Ø
      Münzen/Runde; Test erzwingt den Zielkorridor aus D.4.1 (bei Verstoß
      Konstanten bewusst nachziehen, nicht den Test aufweichen)
- [ ] Fairness-Report-Test: Ø Züge bis Game Over über ≥ 100 Seeds mit
      Untergrenze (D.4.2) — schützt vor Generator-Regressionen

**Block 5 — Komfort & Zugänglichkeit (D.5)**
- [ ] „Reduzierte Effekte"-Schalter in den Einstellungen: weniger Partikel,
      kein Screen-Shake, kein Glow-Blur (ältere Geräte + Reizempfindlichkeit)
- [ ] Theme-Kontrast-Test: automatischer Test prüft Mindestkontraste aller
      Themes (D.5.2) — Werte bei Verstoß anpassen
- [ ] Haptik-Intensität wählbar: Aus / Leicht / Stark (D.5.3)

**Block 6 — Technik-Härtung (D.6)**
- [ ] Widget-Tests für die Monetarisierungs-Flows: Game-Over (Revive-Button
      aktiv/ausgegraut/verbraucht), Shop (Supporter owned), Sparschwein-Dialoge
      (leer/teils/voll)
- [ ] Web-Performance-Pass: `RepaintBoundary` um Board/Partikel/Tray,
      const-Audit der heißen Widgets; Ergebnis im PR dokumentieren
- [ ] Landscape-/Tablet-Check: Board-MaxWidth, Game-/Home-Layout ab 600 dp
      Breite; Widget-Tests mit großer Surface

**Block 7 — Firebase-Backend (D.7; startbar SOBALD `google-services.json`
im Chat geliefert wurde — Nutzer-Entscheidung vom 22.07.2026: Analytics +
Crashlytics + kontofreie Firestore-Bestenliste mit ANONYMER Auth. NIE ein
sichtbarer Login, KEIN E-Mail/Passwort):**
- [ ] `firebase_core` + `firebase_analytics` + `firebase_crashlytics`
      anbinden: `firebase_options.dart` aus den JSON-Werten generieren,
      `FirebaseAnalyticsBackend` hinter das bestehende `Analytics`-Interface,
      Crashlytics-Fehler-Weiterleitung; Web + Tests behalten die Fakes
- [ ] Kontofreie Bestenliste: anonyme Auth + Firestore (`leaderboard`-
      Collection, bester Score pro Spieler), Security-Rules im Repo
      (`firebase/firestore.rules`, Nutzer fügt sie in der Konsole ein),
      `LeaderboardService` auf Firestore umstellen, GitHub-Issue-Pipeline
      danach stilllegen
- [ ] Offline-Regel bleibt: Gameplay läuft ohne Netz; Bestenliste/Analytics
      degradieren still (kein Fehler-Popup)

**👤-gebunden (NICHT von autonomen Sessions startbar):**
Play-Games-Achievements, Screenshots/Signing/Upload, geschlossener Test
(12 Tester / 14 Tage — `docs/SETUP-ACCOUNTS.md` §7).

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
| Revive (Board-Mitte 4×4 wird geleert, 1× pro Runde) | 200 Münzen (nie Werbung) |
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
  (nur EIN Format: Rewarded)
- IAP-Produkt-IDs: `qubble_supporter`, `qubble_coins_s`, `qubble_coins_m`,
  `qubble_coins_l`, `qubble_starter` (Anhang C; `qubble_remove_ads` und
  `qubble_piggy` wurden im Juli-2026-Rework ersatzlos gestrichen)

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

### C.5 Sparschwein (überarbeitet Juli 2026: Belohnung statt Kauf)

- Füllung: +1 Münze pro geräumter Linie (zusätzlich zur normalen Ökonomie,
  landet **nur** im Schwein).
- Kapazität: 500 (Stufe 1) → nach jedem Öffnen +500, max. 3000.
- Öffnen: **voll = gratis ausschütten** (Antippen). Nicht voll = optional per
  Bonus-Video vorzeitig öffnen. Kein IAP.
- UI: dezentes Icon auf Home mit Füllstand; Hinweis-Badge erst ab 80 % Füllung.
  **Nie** blockierend/Popup-Spam — Positionierung „entspannt" schützen.

### C.6 Starter-Paket

- Trigger: einmalig nach Runde 5 (genug Bindung, früh genug für Conversion).
- Inhalt: 1200 Münzen + Wood-Theme. Preis 1,99 € (`qubble_starter`).
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

---

## Anhang D — Spezifikation Phase 7 (verbindlich)

### D.1 Onboarding & erste Runde

**D.1.1 Kontextuelle Coach-Hints.** Einmalige, dezente Hinweis-Banner
(gleicher Stil wie die bestehenden Onboarding-Hints), ausgelöst durch das
erste Auftreten des jeweiligen Moments; danach nie wieder:

| Storage-Key | Auslöser | Text (DE) |
|---|---|---|
| `hint.combo` | erste aktive Combo | „Combo! Räume innerhalb von 10 s weiter, sonst läuft sie ab ⏱" |
| `hint.fever` | Fieber-Meter erstmals voll | „FIEBER! Doppelte Punkte, solange es glüht 🔥" |
| `hint.rotation` | erste Rotation per Tipp | „Drehen kostet eine Ladung — Clears füllen sie wieder auf" |
| `hint.booster` | erster Moment mit Guthaben ≥ Undo-Preis im Spiel | „Tipp: Unten kannst du Booster einsetzen 🪙" |

Logik (welcher Hint fällig ist) als pure-Dart-Helfer + Unit-Tests; die Keys
zentral in `storage.dart`.

**D.1.2 „Wie spielt man?"-Screen.** Statischer Screen, Abschnitte mit
Icon + 2–3 Zeilen: Platzieren, Reihen/Spalten räumen, Combo-Timer, Fieber,
Booster (Preise aus `BoosterCosts` referenzieren, nicht hartkodieren), Daily
& Streak, Sparschwein. Keine Bilder-Assets (nur Icons/eigene Painter) —
lokalisierbar halten (Block 2).

**D.1.3 Sanfte erste Runde.** `GameSession` erhält Parameter
`earlyPhaseMoves` (Default 10 = Status quo, Anhang A.2 Regel 3). Beim
allerersten Endlos-Run (`lifetimeStats.games == 0`) übergibt der Controller
20. Daily bleibt IMMER Standard (kompetitiv, gleiche Bedingungen). Tests:
Gewichtung greift in Zug 11–20 nur im Erste-Runde-Modus.

### D.2 Lokalisierung

- Standard-Flutter-Weg: `l10n.yaml`, ARB im `lib/l10n/`, generierte
  `AppLocalizations`. `app_de.arb` ist die Quelle der Wahrheit.
- ALLE nutzersichtbaren Strings (Screens, Dialoge, Snackbars, Buttons,
  Notification-Texte) — Grep-Abnahme: kein deutsches Literal mehr in
  `lib/ui/` außerhalb der ARB-Dateien.
- Spielernamen, Zahlen, Emojis bleiben unübersetzt; Datumsformate via
  `intl` (`DateFormat.yMMMd(locale)`).
- Sprachwahl: `settings.locale` ∈ {`system`, `de`, `en`}; Default `system`.
- Store-Texte EN existieren bereits (`docs/STORE-LISTING.md`) — Wortlaut
  für App-Strings daran anlehnen.

### D.3 Daily-Politur

**D.3.1 Kalender.** Persistenz: `dailyDatesPlayed` als String-Liste von
Date-Keys (`YYYY-MM-DD`), beim Daily-Abschluss ergänzt, auf die letzten
**70 Einträge** gekappt (Anzeige braucht max. laufenden + Vormonat).
Screen: Monatsraster (Mo–So), gespielte Tage = Häkchen in Theme-Farbe,
heute umrandet; darunter Streak (🔥 n) und Daily-Bestwert (neuer
Storage-Key `dailyHighscore`). Kalender-Logik (Wochen eines Monats,
Markierungen) pure Dart + getestet.

**D.3.2 Teilen.** Button „Ergebnis teilen" am Daily-Game-Over (nur Daily).
Text-Format (kein Bild, kein Server):

```
Qubble Daily 21.07.2026
🧩 1.234 Punkte · 🔥 5 Tage
🟩🟩🟩⬜⬜
qubble.app → https://f6vp76ctbb-stack.github.io/mobile-game/
```

Die 5 Quadrate = Score-Stufen (je 500 Punkte ein 🟩, max 5). Formatierung
pure Dart (`daily_share.dart`) + Tests; Versand via `share_plus` (BSD-3,
in `assets/CREDITS.md` NICHT nötig — kein Asset). Auf Web: Fallback
Zwischenablage + Snackbar.

**D.3.3 Countdown.** Auf der Daily-Karte, wenn heute gespielt:
„Nächstes Daily in HH:MM" (Mitternacht lokal; tickt minütlich nur bei
sichtbarem Home).

### D.4 Ökonomie- & Fairness-Absicherung

**D.4.1 Ökonomie-Korridor.** Testbot (immer erster legaler Zug, wie in
`monetization_test.dart`) über ≥ 50 Seeds im Endlos-Modus. Gemessen wird
der Durchschnitt der pro Runde verdienten Münzen (Live-Münzen inkl.
All-Clear-Bonus, OHNE Missionen/Daily/Level-Up). Verbindlicher Korridor:
**15–60 Münzen/Runde** (Booster-Preise 50–200 sollen nach 2–5 Runden
erreichbar sein, aber nicht geschenkt). Liegt der Wert außerhalb →
`kCoinsPerLine`/`kAllClearCoins`/Booster-Preise anpassen und die Änderung
im MASTERPLAN (A.3/C.1) nachziehen. Der Test dokumentiert den Messwert in
der Ausgabe.

**D.4.2 Fairness-Untergrenze.** Gleicher Bot, ≥ 100 Seeds: Ø Züge bis
Game Over **≥ 15** und 10.-Perzentil **≥ 8**. Schützt Rettungsregel &
Frühphasen-Gewichtung gegen Regressionen.

### D.5 Komfort & Zugänglichkeit

**D.5.1 Reduzierte Effekte.** `settings.reducedEffects` (Default false).
Wirkung: Partikelzahl ×0,4 (Clear-Bursts, Menü-Partikel, Konfetti), kein
Screen-Shake, Glow-/Blur-Effekte durch einfache Strokes ersetzt.
Zentral als Getter am Settings-Controller, Painter fragen ihn ab.

**D.5.2 Kontrast-Test.** Für jedes Theme in `kThemeCatalog` (per
`computeLuminance`): Kontrastverhältnis `textPrimary` vs. `background`
≥ 4,5:1; `placed` vs. `emptyCell` ≥ 2,0:1; `fever` vs. `boardBackground`
≥ 2,0:1. Verstöße → Farbwerte des Themes anpassen (nicht den Test).

**D.5.3 Haptik-Intensität.** `settings.hapticsLevel` ∈ {off, light,
strong}; ersetzt den Bool (Migration: true→strong, false→off). „Leicht"
mappt schwere Impacts auf leichte. `Haptics` bleibt einzige Anlaufstelle.

### D.6 Technik-Härtung

- Widget-Tests (Block 6) nutzen die bestehenden Fakes; Sparschwein-Dialoge
  über `SharedPreferences.setMockInitialValues` in die drei Zustände setzen.
- Performance: `RepaintBoundary` um `BoardView`, Partikel-Layer und Tray;
  danach `flutter build web --release` + Headless-Boot als Smoke-Check.
- Landscape/Tablet: Breakpoint 600 dp; Board zentriert mit
  `maxWidth = min(Breite, 480)`; Widget-Test mit `tester.view.physicalSize`
  in Portrait + Landscape ohne Overflow-Exceptions.

### D.7 Firebase-Backend (Nutzer-Entscheidung 22.07.2026)

**Grundsätze:** Nie ein sichtbarer Login (nur `signInAnonymously`, lazy beim
ersten Bestenlisten-Eintrag). Gameplay bleibt 100 % offline-fähig; Netz-
Features degradieren still. Kein E-Mail/Passwort, kein Firestore fürs
Gameplay.

**Analytics/Crashlytics:** `FirebaseAnalyticsBackend implements Analytics`
(bestehendes Interface, Events unverändert); Crashlytics via
`FlutterError.onError`/`PlatformDispatcher.onError`. Nur native Builds —
Web und Tests behalten `DebugAnalytics`/`NoopAnalytics`.
`firebase_options.dart` wird manuell aus der `google-services.json`
generiert (kein `flutterfire configure` nötig; Datei bleibt git-ignored,
die extrahierten Werte in `firebase_options.dart` sind öffentlich-harmlos
— Zugriffsschutz kommt aus den Security Rules, nicht aus Geheimhaltung).

**Bestenliste (Firestore):**
- Collection `leaderboard`, Dokument-ID = anonyme `uid`.
- Felder: `name` (String, 2–14, `[A-Za-z0-9 _-]`), `score` (int, 1..1e8),
  `updatedAt` (serverTimestamp).
- Security Rules (`firebase/firestore.rules` im Repo; Nutzer kopiert sie in
  die Konsole): Lesen öffentlich; Schreiben nur eigenes Dokument
  (`request.auth.uid == docId`), Name/Score validiert, Score darf nur
  steigen. Anzeige: Top 50 nach `score desc`.
- UI unverändert (Leaderboard-Screen markiert eigenen Namen); der
  Game-Over-Eintrag ersetzt den GitHub-Issue-Flow. Danach
  `leaderboard.yaml`-Action + Issue-Weg entfernen; `leaderboard.json`
  bleibt als Archiv liegen.
