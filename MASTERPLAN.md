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

### Phase 1 — MVP (Woche 1–2)
- [ ] Flutter-Projekt, Game-Engine: Board, Teile, Drag & Drop, Clear-Logik
- [ ] Scoring + Game Over + Highscore (lokal)
- [ ] Basis-UI: Menü, Spiel, Game-Over-Screen
- [ ] Unit-Tests für die komplette Spiellogik (Board, Generator, Scoring)

### Phase 2 — Game Feel & Retention (Woche 3–4)
- [ ] Animationen, Partikel, Sounds, Haptik, Combo-Fieber
- [ ] Daily Challenge + Streak
- [ ] Themes, Missionen, Münz-Ökonomie
- [ ] Onboarding (3 geführte Züge, kein Text-Tutorial)

### Phase 3 — Monetarisierung & Stores (Woche 5–6)
- [ ] AdMob-Integration (Interstitial + Rewarded) mit Frequency Capping
- [ ] IAP (Werbefrei + Münzen), Restore Purchases
- [ ] Firebase Analytics-Events (Funnel: install → runde 1 → runde 3 → D1)
- [ ] Store-Listings: Icon, Screenshots, ASO-Texte (DE + EN), Datenschutzerklärung
- [ ] App-Review-Anforderungen: DSGVO/UMP-Consent-Dialog (AdMob UMP SDK), COPPA-Einstufung

### Phase 4 — Soft Launch (Woche 7–8)
- [ ] Release nur Play Store, 1–2 kleine Märkte (z. B. Niederlande/Skandinavien)
- [ ] KPIs messen (siehe unten), Fairness-Tuning & Ad-Frequenz iterieren
- [ ] Crashfrei-Rate > 99,5 %

### Phase 5 — Global Launch & Growth (ab Woche 9)
- [ ] iOS + Android weltweit
- [ ] ASO-Iteration (Keywords, Screenshot-A/B im Play Store)
- [ ] Organik pushen: TikTok/Shorts mit „satisfying"-Clips (Combo-Fieber ist genau dafür gebaut)
- [ ] Erst wenn LTV > CPI messbar: kleine Paid-UA-Tests

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

Phase 1 starten: Flutter-Projekt aufsetzen und die komplette Spiellogik
test-getrieben bauen. Die Entwicklungs-Konventionen stehen in `CLAUDE.md`.
