# Account- & Store-Setup (die 👤-Schritte)

Diese Schritte kann nur ein Mensch erledigen (Konten, Zahlungen, Uploads).
Der Code ist bereits so gebaut, dass er mit **Test-IDs** sofort läuft — hier
wird nur beschrieben, wie du die **echten** IDs/Configs einträgst.

> **Strategie: Play Store zuerst** (aus Kostengründen — Google 25 € einmalig,
> Apple 99 €/Jahr). Die iOS-/Apple-Schritte sind unten als *(später/optional)*
> markiert und können warten, bis Android läuft. Der Code bleibt unverändert
> für beide Plattformen lauffähig.

> Reihenfolge (Play-first): 0) Steuerliches klären, 1) Play Console, 2) AdMob,
> 3) Firebase, 4) IAP-Produkte, 5) Datenschutz + Impressum, 6) Signing & Upload.

---

## 0. Steuerliches (Hinweis, keine Steuerberatung) 🇩🇪

**Du kannst jetzt starten, ohne vorher ein Gewerbe anzumelden.** Praktisch
relevant wird die Anmeldung, sobald tatsächlich **Geld ausgezahlt** wird —
Google verlangt dafür Steuerdaten im Zahlungsprofil. „Einnahmen" und
„Anmeldung" fallen also ohnehin am selben Punkt zusammen.

Pragmatischer Weg (Hobby-Test → hochskalieren):

- Jetzt bauen & veröffentlichen, beobachten, ob überhaupt Einnahmen kommen.
- **Sobald real Geld fließt:** Gewerbe anmelden (Gewerbeamt, ~20–60 €, schnell,
  auch rückwirkend möglich) und im Finanzamt-Fragebogen die
  **Kleinunternehmerregelung (§19 UStG)** wählen → keine USt, einfache EÜR.
  Dann Steuernummer/ggf. USt-IdNr (BZSt, wegen AdMob-Reverse-Charge) ins
  Google-Zahlungsprofil eintragen.
- Verdienst du nichts und hörst auf → kein Gewerbe nötig, kein Aufwand.

Zur Einordnung: Die **Freigrenzen** (410 € Nebeneinkünfte, 24.500 €
Gewerbesteuer-Freibetrag, 25.000 € Kleinunternehmer) betreffen die
**Besteuerung**, nicht die Anmeldepflicht. Der rechtliche Auslöser der
Anmeldung ist der Start der Tätigkeit mit Gewinnabsicht — bei nennenswerten
Einnahmen also zeitnah anmelden. Im Zweifel kurz Finanzamt/Steuerberater fragen.

## 1. Entwickler-Konten

- **Google Play Console** — https://play.google.com/console/signup (25 € einmalig).
  **Steuer- und Bankdaten** im Payments-Profil hinterlegen (sonst keine Auszahlung).
- **Apple Developer Program** *(später/optional)* —
  https://developer.apple.com/programs/ (99 €/Jahr). Erst nötig, wenn du auch
  in den App Store willst.

## 2. AdMob (Werbung — nur freiwillige Bonus-Videos)

> Qubble zeigt **keine erzwungene Werbung** (keine Interstitials, keine
> Banner). Das einzige Format ist das freiwillige **Rewarded Video** — du
> brauchst also pro Plattform nur EINEN Anzeigenblock.

1. Konto anlegen: https://admob.google.com/ → **Apps** → **App hinzufügen**
   (zuerst **Android**; die iOS-App später, wenn du in den App Store gehst).
   - Frage „Ist die App in einem App-Store gelistet?" → **Nein** wählen (die
     App ist ja noch nicht veröffentlicht). Das ist der normale Weg — AdMob
     legt die App trotzdem an; die Store-Verknüpfung holst du nach dem
     Play-Store-Launch nach (AdMob erinnert dich daran).
2. Die **App-ID** kopieren (Format `ca-app-pub-XXXX~XXXX`) und ersetzen:
   - Android: `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
   - iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier`
3. **Einen Anzeigenblock** erstellen: Typ **Rewarded** (Belohnung z. B.
   „Münzen/1"— der Wert ist egal, unser Code steuert die Belohnung selbst).
   Die Unit-ID (`ca-app-pub-XXXX/XXXX`) eintragen in
   `lib/monetization/ad_config.dart` (`REPLACE_ME_REWARDED_ANDROID`).
4. **UMP / DSGVO-Meldung** einrichten: AdMob → **Datenschutz & Meldungen** →
   Einwilligungsmeldung (GDPR) für EU erstellen. Der Code ruft den Consent-Flow
   automatisch vor dem ersten Ad-Request auf (`GoogleAdService._requestConsent`).

> ✅ **Schritte 1–3 erledigt (22.07.2026):** Android-App-ID im Manifest,
> Rewarded-Unit-ID in `ad_config.dart`. Offen: UMP-Meldung (Schritt 4) und
> später die Store-Verknüpfung + iOS.

> Debug-Builds nutzen **immer** Googles Test-IDs (in `ad_config.dart` fest
> verdrahtet) — echte Ads erscheinen nur im Release-Build. Bitte während der
> Entwicklung nie auf echte Ads klicken (Konto-Sperre).

## 3. Firebase (Analytics + Crashlytics)

**Vorab: das Google-Konto.** Für Firebase reicht ein **normales, kostenloses
Google-Konto**. Ein eingetragenes Unternehmen brauchst du nicht:

- Fragt die Konto-Erstellung nach einem **Organisations-/Unternehmensnamen**,
  trag einfach **„Thinkube"** ein (unser Publisher-Name). Das Feld ist nur ein
  Label — es wird nichts geprüft, du gehst keine Verpflichtung ein.
- **Achtung, falsche Tür:** Wirst du nach einer **Domain**, einem **Abo/Tarif**
  (z. B. „Business Starter") oder **Zahlungsdaten** gefragt, bist du im
  **Google-Workspace**-Anmeldeprozess gelandet — das ist ein Bezahlprodukt und
  für uns unnötig. Abbrechen und stattdessen unter
  https://accounts.google.com/signup ein normales Konto anlegen.
- In der Firebase/Cloud-Konsole erscheint das Projekt dann unter
  „**Keine Organisation**" — das ist völlig normal und richtig so.

**Projekt anlegen (einmalig, ~10 Minuten):**

1. https://console.firebase.google.com/ → **Projekt hinzufügen**.
2. Projektname: **Qubble** (die automatisch erzeugte Projekt-ID wie
   `qubble-a1b2c` einfach übernehmen).
3. **Google Analytics: aktivieren** (Ja) — das ist unser Analytics-Backend.
   - Analytics-Standort: **Deutschland**.
   - Analytics-Konto: „Default Account for Firebase" übernehmen.
4. Es gilt automatisch der **Spark-Tarif (kostenlos)** — Analytics und
   Crashlytics sind darin komplett enthalten. **Keine Kreditkarte nötig,
   nicht auf „Blaze" upgraden.**

**Android-App registrieren:**

5. In der Projektübersicht auf das **Android-Symbol** → App registrieren.
   - Paketname: **`com.thinkube.qubble`** — exakt so, Tippfehler lassen sich
     später nicht korrigieren (nur App löschen + neu anlegen).
   - Nickname: „Qubble Android". **SHA-1 leer lassen** (erst für
     Play-Games/Sign-In nötig, nicht für Analytics/Crashlytics).
6. **`google-services.json` herunterladen.** Die restlichen Schritte des
   Assistenten („SDK hinzufügen" etc.) **überspringen** — das erledigt Claude
   im Code.
7. Die Datei **NICHT ins Repo committen** (Repo ist öffentlich; sie steht
   bereits in `.gitignore`). Lokal nach `android/app/google-services.json`
   legen (der Release-Build auf deinem Rechner braucht sie dort) und den
   Inhalt Claude in der Session schicken.
   ✅ **Erledigt (22.07.2026):** App registriert, Firebase Analytics +
   Crashlytics sind im Code angebunden (`lib/services/firebase_boot*.dart`).
8. *(später/optional)* **iOS-App** genauso registrieren (Bundle-ID
   `com.thinkube.qubble`) → `GoogleService-Info.plist` → lokal nach
   `ios/Runner/`. Erst beim App-Store-Gang nötig.

**Bestenliste (Entscheidung 22.07.2026: kontofrei über Firestore):**

9. **Authentication** → Tab „Sign-in-Methode" → **„Anonym" aktivieren**
   (NICHT E-Mail/Passwort — Spieler sehen nie einen Login).
10. **Firestore Database** → „Datenbank erstellen" → Standort
    **europe-west3 (Frankfurt)** → „Im Produktionsmodus starten".
11. **Sicherheitsregeln einspielen:** Firestore → Tab **„Regeln"** → Inhalt
    von **`firebase/firestore.rules`** aus dem Repo einfügen →
    „Veröffentlichen". Ohne diesen Schritt kann die App keine Scores
    schreiben (Produktionsmodus sperrt alles).

Mehr ist in der Konsole nicht nötig — kein Blaze-Upgrade, keine weiteren
Produkte.

## 4. In-App-Käufe (IAP)

Produkte in **beiden** Konsolen mit **exakt diesen IDs** anlegen
(`lib/monetization/iap.dart`):

| Produkt-ID | Typ | Vorschlag Preis |
|---|---|---|
| `qubble_supporter` | Non-Consumable | 4,99 € (Unterstützer-Paket: Aurora-Theme + Kristall-Skin + 1.500 Münzen + ❤️) |
| `qubble_coins_s` | Consumable | 0,99 € |
| `qubble_coins_m` | Consumable | 2,99 € |
| `qubble_coins_l` | Consumable | 7,99 € |
| `qubble_starter` | Consumable | 1,99 € (Starter-Paket, 48h-Angebot ab Runde 5) |

- App Store Connect: **In-App-Käufe** → jeweils anlegen, Preis + Lokalisierung.
- Play Console: **Monetarisierung → Produkte → In-App-Produkte**.
- Für Tests: App Store Sandbox-Tester / Play Console Lizenz-Tester einrichten.

## 5. Datenschutz & Impressum

1. **Datenschutzerklärung** hosten (kostenlos, z. B. GitHub Pages) — Vorlage
   liegt in `docs/PRIVACY-POLICY.md`. URL im Play-Store-Eintrag hinterlegen.
2. **Impressum** (§ 5 DDG, für gewerbliche Apps in DE Pflicht) — Vorlage in
   `docs/IMPRESSUM.md`. Ausgefüllt hosten (eigene URL) **und** in der App
   erreichbar machen (in den Einstellungen bereits verlinkt, sobald die URL steht).
3. **Google**: Abschnitt **Datensicherheit** ausfüllen (AdMob sammelt
   Werbe-Identifier → deklarieren; UMP-Consent deckt die Einwilligung ab).
4. Zielgruppen-/COPPA-Einstufung in der Play Console setzen.
5. *(später/optional)* **Apple**: App-Privacy-Formular + ATT sind über den
   UMP-Flow abgedeckt — erst relevant beim App-Store-Gang.

## 6. Signing & Upload

- **Android**: Upload-Keystore erzeugen (`keytool`), in `android/key.properties`
  referenzieren, `flutter build appbundle` → `.aab` in Play Console hochladen.
  Anleitung: https://docs.flutter.dev/deployment/android#signing-the-app
- **iOS**: In Xcode Signing-Team wählen, `flutter build ipa` → über
  Transporter/Xcode zu App Store Connect hochladen.

## 7. Geschlossener Test — PFLICHT vor der Veröffentlichung! 🧪

Dein Play-Konto ist ein **neues persönliches Konto** (nach Nov. 2023 erstellt).
Google verlangt deshalb, bevor du die App veröffentlichen darfst:

> **Mindestens 12 Tester müssen 14 Tage lang ununterbrochen** an einem
> geschlossenen Test teilnehmen (Opt-in + App installiert). Erst danach
> kannst du den Produktionszugriff beantragen (Prüfung dauert ≤ 7 Tage).

So läuft es ab:

1. In der Play Console: **Testen → Geschlossene Tests** → Track anlegen,
   `.aab` hochladen (siehe §6), Testversion einreichen.
2. **Tester einladen** — per E-Mail-Liste oder Google-Group. Die Tester
   klicken den Opt-in-Link und installieren die App über Play.
   „Eingeladen" zählt NICHT — nur wer wirklich beigetreten ist + installiert
   hat.
3. **14 Tage warten** (Zähler läuft nur, solange ≥ 12 Tester dabei sind —
   lieber 15–20 einladen als Puffer).
4. Danach in der Console **Produktionszugriff beantragen** (drei kurze
   Fragebögen zur App).

**Woher 12 Tester nehmen?** Optionen (kombinierbar):
- Freunde/Familie/Kollegen (kostenlos, aber alle brauchen ein Google-Konto
  und müssen die App wirklich 14 Tage installiert lassen).
- **Bezahlte Tester-Dienste** (~15–30 € einmalig), die genau diese
  12-Tester-Anforderung erfüllen, z. B. testerscommunity.com,
  primetestlab.com oder Anbieter auf Fiverr („Google Play 12 testers").
  Seriöse Anbieter liefern echte Geräte-Installs + tägliche Nutzung.
- Reddit-Communities wie r/AndroidClosedTesting (Gegenseitigkeits-Prinzip).

Der Test ist ohnehin nützlich: echtes Geräte-Feedback vor dem Launch —
Crashes und Probleme sehen wir in der Play Console (Android Vitals).

---

Nach jedem Schritt kannst du mir sagen „erledigt: X", dann hake ich den
passenden 👤-Punkt in `MASTERPLAN.md` ab und binde den echten Wert im Code an.
