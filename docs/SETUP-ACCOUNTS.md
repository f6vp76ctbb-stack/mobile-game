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

## 2. AdMob (Werbung)

1. Konto anlegen: https://admob.google.com/ → **Apps** → **App hinzufügen**
   (zuerst **Android**; die iOS-App später, wenn du in den App Store gehst).
2. Pro App die **App-ID** kopieren (Format `ca-app-pub-XXXX~XXXX`) und ersetzen:
   - Android: `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
   - iOS: `ios/Runner/Info.plist` → `GADApplicationIdentifier`
3. Je App zwei **Anzeigenblöcke** erstellen: **Interstitial** und **Rewarded**.
   Die Unit-IDs (`ca-app-pub-XXXX/XXXX`) eintragen in
   `lib/monetization/ad_config.dart` (die `REPLACE_ME_*`-Konstanten).
4. **UMP / DSGVO-Meldung** einrichten: AdMob → **Datenschutz & Meldungen** →
   Einwilligungsmeldung (GDPR) für EU erstellen. Der Code ruft den Consent-Flow
   automatisch vor dem ersten Ad-Request auf (`GoogleAdService._requestConsent`).

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
   bereits in `.gitignore`). Stattdessen:
   - lokal nach `android/app/google-services.json` legen (dort erwartet sie
     der Release-Build auf deinem Rechner), **und**
   - den Datei-Inhalt Claude in der Session schicken (einfach einfügen) —
     dann verdrahtet Claude Firebase Analytics + Crashlytics an das bestehende
     `Analytics`-Interface (aktuell läuft `DebugAnalytics`).
8. *(später/optional)* **iOS-App** genauso registrieren (Bundle-ID
   `com.thinkube.qubble`) → `GoogleService-Info.plist` → lokal nach
   `ios/Runner/`. Erst beim App-Store-Gang nötig.

In der Firebase-Konsole musst du sonst **nichts** einstellen — kein
Realtime-Database/Firestore, keine Authentication (wir haben bewusst kein
Backend). Sollte die konto-freie Bestenliste kommen, wäre das ein eigener,
späterer Schritt.

## 4. In-App-Käufe (IAP)

Produkte in **beiden** Konsolen mit **exakt diesen IDs** anlegen
(`lib/monetization/iap.dart`):

| Produkt-ID | Typ | Vorschlag Preis |
|---|---|---|
| `qubble_remove_ads` | Non-Consumable | 4,99 € |
| `qubble_coins_s` | Consumable | 0,99 € |
| `qubble_coins_m` | Consumable | 2,99 € |
| `qubble_coins_l` | Consumable | 7,99 € |

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

---

Nach jedem Schritt kannst du mir sagen „erledigt: X", dann hake ich den
passenden 👤-Punkt in `MASTERPLAN.md` ab und binde den echten Wert im Code an.
