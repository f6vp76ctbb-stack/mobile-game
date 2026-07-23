# 🚀 LAUNCH — dein aktueller Fahrplan (eine Datei, alles drin)

> **Das ist ab jetzt die EINZIGE Datei, die du zum Veröffentlichen brauchst.**
> Sie fasst `RELEASE.md`, `SETUP-ACCOUNTS.md` und `STORE-LISTING.md` zusammen,
> hakt Erledigtes ab und sagt dir für **jeden** Play-Console-Abschnitt, **was du
> genau eintragen sollst**. Die anderen Docs sind nur noch Nachschlagewerk
> (Detail-Texte, Vorlagen).

Stand: 23.07.2026 · App: **Qubble** · Paketname: `com.thinkube.qubble`

---

## Wo steht was? (Mini-Landkarte)

| Wenn du … brauchst | schau in |
|---|---|
| Diesen Fahrplan / Play-Console-Antworten | **diese Datei** |
| Fertige Store-Texte (Titel, Beschreibung, Keywords, Captions) | `docs/STORE-LISTING.md` |
| Datenschutz-Text zum Hosten | `docs/PRIVACY-POLICY.md` |
| Impressum-Text zum Hosten | `docs/IMPRESSUM.md` |
| Wie die `.aab` per GitHub gebaut wird | `docs/BUILD-CI.md` |
| Konto-Details (AdMob, Firebase, IAP-Preise) | `docs/SETUP-ACCOUNTS.md` |

---

## ✅ Schon erledigt (nichts mehr zu tun)

- **Spiel fertig & getestet** — `flutter analyze` + alle Tests grün, CI prüft jeden Push.
- **Release-Härtung** — Admin-/Cheat-Funktionen nur im Debug-Build; öffentlicher Web-Build verschenkt nichts.
- **AdMob** — Android-App-ID im Manifest, Rewarded-Unit-ID im Code.
- **Firebase** — App registriert, Analytics + Crashlytics angebunden, Bestenliste (Firestore, kontofrei) inkl. Regeln.
- **Play-Console-Konto** angelegt (25 €).
- **Signing-Schlüssel + GitHub-Secrets** eingerichtet, CI baut die signierte `.aab`.
- **`.aab` gebaut, signiert und in die Play Console hochgeladen.** ← dein letzter Schritt

Damit ist die **technische** Arbeit im Wesentlichen durch. Es fehlen nur noch
**Formulare & Texte in der Console** plus der **Pflicht-Testlauf**. Alles unten
kannst nur du (👤) erledigen — es ist Klick-Arbeit, kein Code.

---

## 🧭 Reihenfolge auf einen Blick

1. **App-Inhalte** ausfüllen (die Liste „Spielinformationen angeben") → Abschnitt A
2. **Store-Eintrag** einrichten (Kategorie, Kontakt, Texte, Bilder) → Abschnitt B
3. **In-App-Produkte** anlegen (6 Stück) → Abschnitt C
4. **Geschlossener Test** (12 Tester, 14 Tage) → Abschnitt D
5. **Produktionszugriff beantragen** → Abschnitt D
6. **Soft Launch** (1–2 Märkte) → Abschnitt E

Kleinere Code-Restpunkte (UMP-Meldung, gehostete URLs, Screenshots) stehen in
Abschnitt F — die kann ich (Claude) dir größtenteils vorbereiten.

---

## A. „App-Inhalte" ausfüllen (das ist deine Liste in der Console)

Menü: **Richtlinien → App-Inhalte**. Für Qubble die konkreten Antworten:

### A1 · Datenschutzerklärung
- Feld erwartet eine **URL**. Text steht fertig in `docs/PRIVACY-POLICY.md` — muss
  nur noch **gehostet** werden (kostenlos via GitHub Pages, siehe F2).
- ➜ Sobald die URL steht: hier eintragen.

### A2 · Anmeldedaten (App access)
- Qubble hat **keinen Login und keine gesperrten Bereiche**.
- ➜ Wähle **„Alle Funktionen sind ohne besonderen Zugriff verfügbar"**. Fertig.

### A3 · Anzeigen (Ads)
- ➜ **„Ja, die App enthält Werbung."** (Rewarded-Videos zählen als Werbung.)

### A4 · Einstufung des Inhalts (Content rating)
- Fragebogen starten, Kategorie **„Spiel"**. Für Qubble ehrlich:
  Keine Gewalt, kein Sex, keine Schimpfwörter, kein Glücksspiel, keine Drogen.
- **Diese zwei musst du bejahen:** enthält **Werbung** und **digitale Käufe**.
- **Nutzer interagieren:** Ja — die **Bestenliste zeigt selbstgewählte Namen**
  öffentlich (deshalb Namensfilter im Code). Wenn gefragt, angeben.
- ➜ Ergebnis wird **PEGI 3 / USK 0 / „Jeder"** mit Hinweisen „In-App-Käufe" und
  „Nutzer interagieren". E-Mail für die Einstufung angeben.

### A5 · Zielgruppe (Target audience)
- **Wichtig:** Weil die App Werbung + Käufe hat, **NICHT** als Kinder-App labeln
  (sonst greifen strenge Kinder-/COPPA-Regeln).
- ➜ Altersgruppen **13–15, 16–17, 18+** wählen (keine Gruppe unter 13).
- ➜ „Richtet sich die App an Kinder?" → **Nein**.

### A6 · Datensicherheit (Data safety)
- Das ist das aufwändigste Formular. Für Qubble zu deklarieren:

| Datenart | Erhoben? | Geteilt? | Wofür | Quelle |
|---|---|---|---|---|
| Geräte- oder andere IDs (Werbe-ID) | Ja | Ja | Werbung | AdMob |
| App-Aktivität (In-App-Aktionen) | Ja | Nein | Analyse | Firebase Analytics |
| Absturzprotokolle / Diagnose | Ja | Nein | App-Funktion/Analyse | Crashlytics |
| Name / Nutzername (Bestenlisten-Name) | Ja | Ja | App-Funktion (öffentliche Bestenliste) | Firestore |
| Ungefährer Standort | Optional* | Ja* | Werbung | AdMob |

  \*AdMob leitet aus der IP ggf. einen groben Standort ab. Im Zweifel
  „ungefährer Standort → Werbung" **mit** deklarieren (safer).
- **Keine** E-Mail, **kein** genauer Standort, **keine** Kontakte/Fotos.
- Weitere Fragen: **Übertragung verschlüsselt** → **Ja** (alles über HTTPS).
  **Löschung anfragbar** → **Ja**, verweise auf die Datenschutz-Mail.
- ➜ Muss zur gehosteten Datenschutzerklärung passen (die deckt AdMob/Firebase ab).

### A7 · Behörden-Apps → **Nein** &nbsp; · A8 · Finanzfunktionen → **Nein** &nbsp; · A9 · Gesundheit → **Nein**
- Qubble ist keins davon. Jeweils schlicht **„Nein / trifft nicht zu"**.

---

## B. Store-Eintrag & Präsentation

Menü: **Wachstum → Store-Präsenz → Haupt-Store-Eintrag** und **App-Kategorie**.

### B1 · App-Kategorie & Kontaktdaten
- Kategorie: **Spiele → Puzzle**.
- Kontakt-E-Mail: deine Support-Adresse (Pflicht). Website optional.

### B2 · Store-Eintrag (Texte + Grafik)
Texte **fertig** in `docs/STORE-LISTING.md` — nur kopieren:
- **Titel** (30 Z.): `Qubble – Block Puzzle`
- **Kurzbeschreibung** (80 Z.) und **Vollbeschreibung** (DE, ~ 4000 Z.): aus dem Listing.
- **App-Symbol** 512×512: ist gesetzt (im Projekt vorhanden).
- **Feature-Grafik** 1024×500: **fehlt noch** — brauchst du (kann ich als Vorlage bauen, siehe F3).
- **Screenshots** (min. 2, empfohlen 6, Portrait): **fehlen noch** → F3.

> Hinweis: In der englischen Vollbeschreibung steht noch „WHY GRIDPOP?" (alter
> Name). Vor dem Einfügen zu **Qubble** korrigieren — sag Bescheid, dann fixe ich
> den Text im Repo.

---

## C. In-App-Produkte anlegen

Menü: **Monetarisierung → Produkte → In-App-Produkte**. **Exakt diese IDs**
(sie sind im Code fest verdrahtet — Tippfehler = Produkt funktioniert nicht):

| Produkt-ID | Typ | Preisvorschlag |
|---|---|---|
| `qubble_supporter` | Non-Consumable | 4,99 € |
| `qubble_coins_s` | Consumable | 0,99 € |
| `qubble_coins_m` | Consumable | 2,99 € |
| `qubble_coins_l` | Consumable | 7,99 € |
| `qubble_starter` | Consumable | 1,99 € |
| `qubble_rename` | Consumable | 1,49 € |

Für Tests einen **Lizenz-Tester** in der Console hinterlegen (kauft ohne echte Abbuchung).

---

## D. Geschlossener Test → Produktion (die Pflichthürde 🧪)

Dein Konto ist neu/persönlich → Google verlangt **vor** der Veröffentlichung:

> **Mindestens 12 Tester nehmen 14 Tage ununterbrochen** an einem geschlossenen
> Test teil (beigetreten **und** installiert — „eingeladen" zählt nicht).

Ablauf:
1. **Testen → Geschlossene Tests** → Track anlegen, deine hochgeladene `.aab`
   diesem Track zuweisen, Testversion einreichen.
2. **Tester einladen** (E-Mail-Liste oder Google-Gruppe). Lieber **15–20**
   einladen als Puffer — der 14-Tage-Zähler läuft nur bei ≥ 12 aktiven Testern.
3. **14 Tage warten.** Zeit nutzen: In-App-Feedback einsammeln, Abstürze unter
   **Android Vitals** beobachten.
4. Danach **Produktionszugriff beantragen** (3 kurze Fragebögen; Prüfung ≤ 7 Tage).

**12 Tester finden:** Freunde/Familie (brauchen Google-Konto + 14 Tage installiert),
bezahlte Dienste (~15–30 €, z. B. testerscommunity.com / primetestlab.com / Fiverr
„Google Play 12 testers"), oder r/AndroidClosedTesting (Gegenseitigkeit).

---

## E. Soft Launch (nach Freigabe der Produktion)

- Zuerst **nur** 1–2 kleine Märkte (z. B. Niederlande/Skandinavien).
- KPIs beobachten (Details in `MASTERPLAN.md`): D1/D7-Retention, Session-Länge,
  Rewarded-Engagement, crash-freie Rate > 99,5 %.
- Erst tunen (Fairness-Generator, Ad-Frequenz), **dann** global ausrollen.

---

## F. Code-Restpunkte (meist von mir/Claude vorbereitbar)

- **F1 · UMP-Einwilligungsmeldung (AdMob):** In AdMob → *Datenschutz & Meldungen*
  eine GDPR-Meldung erstellen. Der Code ruft den Consent-Flow bereits automatisch
  auf — es fehlt nur das Anlegen der Meldung in der AdMob-Oberfläche (👤).
- **F2 · Datenschutz + Impressum hosten:** Vorlagen in `docs/PRIVACY-POLICY.md` /
  `docs/IMPRESSUM.md`. Ich kann sie als GitHub-Pages-Seite einrichten und dir die
  fertigen URLs geben — sag „mach die Datenschutz-Seite", dann erledige ich das.
- **F3 · Screenshots + Feature-Grafik:** Sobald du magst, nehme ich die 6 Screens
  (Plan in `docs/STORE-LISTING.md`) auf und baue eine 1024×500-Feature-Grafik.
- **F4 · Store-Text „GRIDPOP" → „Qubble"** in der EN-Vollbeschreibung fixen.
- **F5 · Versionsnummer:** Vor jedem neuen Upload `version:` in `pubspec.yaml`
  erhöhen (der Teil nach `+` muss steigen).

---

### Kurz gesagt
Technisch bist du fertig — der Rest ist Formular-Klickarbeit in der Console
(Abschnitte A–C), dann der 14-Tage-Testlauf (D), dann Soft Launch (E). Arbeite
A → B → C ab; für alles unter F sag mir einfach Bescheid, dann liefere ich zu.
