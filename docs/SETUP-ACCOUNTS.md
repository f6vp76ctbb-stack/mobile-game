# Account- & Store-Setup (die 👤-Schritte)

Diese Schritte kann nur ein Mensch erledigen (Konten, Zahlungen, Uploads).
Der Code ist bereits so gebaut, dass er mit **Test-IDs** sofort läuft — hier
wird nur beschrieben, wie du die **echten** IDs/Configs einträgst.

> Reihenfolge-Tipp: 1) Entwickler-Konten, 2) AdMob, 3) Firebase, 4) IAP-Produkte,
> 5) Datenschutz, 6) Signing & Upload. Steuer-/Bankdaten in beiden Konsolen nicht
> vergessen — ohne sie gibt es keine Auszahlung.

---

## 1. Entwickler-Konten

- **Apple Developer Program** — https://developer.apple.com/programs/ (99 €/Jahr).
- **Google Play Console** — https://play.google.com/console/signup (25 € einmalig).
- In beiden Konsolen **Steuer- und Bankdaten** hinterlegen (Payments-Profil).

## 2. AdMob (Werbung)

1. Konto anlegen: https://admob.google.com/ → **Apps** → **App hinzufügen**
   (je eine für Android und iOS; verknüpfe sie mit den Store-Einträgen, sobald
   diese existieren).
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

## 5. Datenschutz & Store-Formulare

1. **Datenschutzerklärung** hosten (kostenlos, z. B. GitHub Pages) — Text-Vorlage
   liefere ich auf Zuruf. URL brauchst du in beiden Store-Einträgen.
2. **Apple**: App Privacy / „Datenschutz-Nutzung" ausfüllen (AdMob sammelt
   Werbe-Identifier → als Tracking deklarieren; App Tracking Transparency-Prompt
   ist über den UMP-Flow abgedeckt).
3. **Google**: Abschnitt **Datensicherheit** ausfüllen (gleiche Angaben).
4. Zielgruppen-/COPPA-Einstufung in beiden Konsolen setzen.

## 6. Signing & Upload

- **Android**: Upload-Keystore erzeugen (`keytool`), in `android/key.properties`
  referenzieren, `flutter build appbundle` → `.aab` in Play Console hochladen.
  Anleitung: https://docs.flutter.dev/deployment/android#signing-the-app
- **iOS**: In Xcode Signing-Team wählen, `flutter build ipa` → über
  Transporter/Xcode zu App Store Connect hochladen.

---

Nach jedem Schritt kannst du mir sagen „erledigt: X", dann hake ich den
passenden 👤-Punkt in `MASTERPLAN.md` ab und binde den echten Wert im Code an.
