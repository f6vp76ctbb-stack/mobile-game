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

1. Projekt anlegen: https://console.firebase.google.com/ → Android- und
   iOS-App mit den echten Bundle-IDs registrieren.
2. Config-Dateien herunterladen und ins Repo legen:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
3. Sag mir Bescheid, sobald die Dateien liegen — dann binde ich das
   Firebase-Analytics-Backend an das bestehende `Analytics`-Interface an
   (aktuell läuft `DebugAnalytics`, das die Funnel-Events nur ausgibt).

## 4. In-App-Käufe (IAP)

Produkte in **beiden** Konsolen mit **exakt diesen IDs** anlegen
(`lib/monetization/iap.dart`):

| Produkt-ID | Typ | Vorschlag Preis |
|---|---|---|
| `gridpop_remove_ads` | Non-Consumable | 4,99 € |
| `gridpop_coins_s` | Consumable | 0,99 € |
| `gridpop_coins_m` | Consumable | 2,99 € |
| `gridpop_coins_l` | Consumable | 7,99 € |

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
