# E-Health Mobile (Flutter) — front-end demo, no backend

The E-Health mobile app in Flutter, ported from the team's React Native design prototype (`ehealth-app`) with the same look, screens and behaviour. **Khmer is the default**, English the second language.

- No server needed. Demo data is generated on first start and **saved on the phone**, so it survives restarts. Settings → *Reset demo data* brings it back.
- Four roles: **patient, caretaker, family member, doctor** (admin is web-only).
- Packages: `shared_preferences` (save data), `image_picker` (camera), `share_plus` (share the invite code). The first two are from the Flutter team.
- The camera is real, but **OCR is simulated**: demo photos return the numbers printed on them, camera photos return plausible numbers.

---

## 1. Run it (first time)

You need Flutter **3.27 or newer**. Check with `flutter --version`, and use `flutter upgrade` if it's older.

```bash
# in this folder
bash setup.sh          # macOS / Linux
setup.bat              # Windows
```

The setup script runs `flutter create .`, which adds the `android/` and `ios/` folders without touching `lib/`. It then runs `flutter pub get` and sets the app name to **E-Health**.

Then plug in a phone and run:

```bash
flutter devices        # your phone should be listed
flutter run            # debug build, hot reload with "r"
```

### Connecting to the local API

The app works standalone with demo data when the API is not running. When the API server (`pnpm --filter @ehealth/api dev`) is running on port `3000`:

- **iOS Simulator / macOS:** uses `http://localhost:3000/api/v1` automatically.
- **Android Emulator:** uses `http://10.0.2.2:3000/api/v1` automatically (`10.0.2.2` maps to the host computer's `localhost`).
- **Physical phone on the same Wi-Fi:** pass your computer's LAN IP:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000/api/v1
  ```

Already wired (falls back cleanly to demo data while the `readings` module returns empty data):
- `ApiClient.devLogin(role)` → `POST /api/v1/dev/login` (called in `AppState.signIn`)
- `ReportsRepository.fetchPatientReport(...)` → `GET /api/v1/patients/:patientId/summary` & `GET /api/v1/patients/:patientId/series` (called in `ReportsScreen`)

Before you push, run `flutter analyze` and `flutter test`; both should pass with no issues.

### Samsung Galaxy S22+, S22 Ultra, S20 Ultra (Android)

1. **Settings → About phone → Software information** → tap **Build number** 7 times (turns on Developer options).
2. **Settings → Developer options → USB debugging** → On.
3. Plug in with USB and accept the "Allow USB debugging?" prompt on the phone.
4. `flutter run`

To put it on teammates' phones without a cable, run `flutter build apk --release` and send them `build/app/outputs/flutter-apk/app-release.apk`. They open it and allow "Install unknown apps".

### iPhone 17 (iOS)

iPhone builds **need a Mac with Xcode**.

1. On the Mac: `bash setup.sh`, then `cd ios && pod install && cd ..` (only if Flutter asks for it).
2. `open ios/Runner.xcworkspace` → **Runner → Signing & Capabilities** → choose your Apple ID team. A free account works for 7-day test installs.
3. On the iPhone: **Settings → Privacy & Security → Developer Mode** → On (it restarts).
4. Plug it in and run `flutter run`. The first time, trust the developer under **Settings → General → VPN & Device Management**.

### Screen sizes

The layout is fluid, so nothing is fixed to one phone. It was laid out for 360–430 dp wide screens, which covers S22+ (~384 dp), S22 Ultra (~384–412 dp), S20 Ultra (~412 dp) and iPhone 17 (~402 pt). It handles notches, punch-hole cameras, the iPhone Dynamic Island and the home indicator through SafeArea.

The app follows the phone's **font size** setting, capped at 1.3× so the layout doesn't break, and has its own text-size setting (Normal / Large / Extra large). It is portrait-only.

---

## 2. Using the demo

On the sign-in screen, tap a role under **Demo accounts**, or type a demo phone number with the password `123456`.

| Role | Demo user | Phone | What to try |
|---|---|---|---|
| Patient | Sok Chantha | 012 345 678 | Home shows "Not recorded yet today". Tap **Record now**, then a photo or type the numbers. Approve Dr. Ouk Malis in Settings → My care team. |
| Caretaker | Dara Pich | 011 765 432 | Records for 2 patients. Use **Change** at the top of Record, History or Reports to switch patient. |
| Family member | Sok Sreyleak | 096 555 0101 | View only: nothing can be edited. |
| Doctor | Dr. Lim Bunthoeun | 023 900 100 | Dashboard puts the patients who need attention first. Open a patient → **Add note**. |

Things to try:

- **OCR**: Record → *Photo of blood pressure monitor* → *Use demo photo (clear)* fills in 132/84, pulse 72. *Use demo photo (blurry)* shows the fallback to typing (US-09).
- **Validation**: type systolic 300 to see the safe-limit error, 145 to see the "outside normal range" warning.
- **Duplicate morning reading** (FR-05): record twice before 12:00 to get Replace / Keep both.
- **Undo**: delete a reading, then tap **Undo** on the message at the bottom.
- **Link a patient** (caretaker, family or doctor): Settings → Linked patients → code `246810`.
- **Settings**: language, Khmer numerals ១២៣, text size, reminder time, reset demo data.

---

## 3. Code map (who wires what to the backend)

```
lib/
  main.dart, app.dart              app start, theme, KH/EN locale, text-size cap
  theme/tokens.dart                ALL colours, spacing, radii, type scale
  theme/icons.dart                 the Material Design Icons the app uses (font in assets/fonts)
  l10n/strings.dart                I18n: t(key), Khmer numerals and dates (NFR-01, NFR-02)
  l10n/modules/*.dart              ALL text, split per module (shared, accounts, readings, ocr, reports)
  l10n/km.dart, en.dart            Merged barrels (tests verify km/en parity and no duplicate keys)
  data/types.dart                  User, Link, Reading, CustomField, DoctorNote, Settings
  data/ranges.dart                 safe input limits (FR-06) + normal ranges for flags
  data/stats.dart                  min / max / average, missed days, doctor summary (FR-10, FR-12)
  data/seed.dart                   ← the demo data. Replace with API calls.
  api/                             shared HTTP client (`api_client.dart`), DTOs (`api_models.dart`), reports repository (`reports_repository.dart`)
  state/app_state.dart             local store + dev JWT token; plays the API's role until every module lands
  widgets/                         the shared UI kit: AppText, AppButton, AppCard, AppField, Segmented,
                                   StatusBadge, LineChart, PatientSwitcher, sheets, dialog + toast
  screens/shell.dart               header, role-based bottom tabs, push() / goToTab()
  screens/auth/                    sign in                              → Phayuk (US-01)
  screens/home/                    Home per role, patient page, notes   → Rith (US-14, US-13, US-12, US-19)
  screens/record/record_screen     choose photo or typing               → Seyla (US-04)
  screens/record/ocr_screen        camera + simulated OCR               → Phak (US-07/08/09)
  screens/record/reading_form      new / OCR / edit form                → Seyla (US-04/05)
  screens/history/                 history list + reading detail        → Seyla (US-05, US-06)
  screens/reports/                 Min/Avg/Max + charts                 → Rith (US-10/11)
  screens/links/                   care team, invite, link a patient    → Phayuk (US-03)
  screens/settings/                language, text size, reminder        → Rith (US-15), Seyla (US-17)
```

Shared code (`shell.dart`, `widgets/`, `state/`, `theme/`, `l10n/`) is owned by Rith.

Rules this code follows:

- Screens only use the shared widgets and tokens, never raw colours. Text comes from `km.dart` / `en.dart`, never typed into a screen.
- **OCR → form contract:** `Prefill { systolic, diastolic, pulse, glucose, photoUri, lowConfidence }`. Phak's OCR screen fills it and the reading form reads it.
- **Admin-defined fields:** add one to `fields` in `seed.dart`. It appears in the form, the Reports table and a chart with no other change.
- Every status is colour + icon + word. Safe limits block Save; normal ranges only warn (FR-06).

### Open points for the team

- Normal ranges in `data/ranges.dart` are demo values. Replace them with the reference the team chooses (WHO or Cambodian MoH).
- Have a native speaker review the medical terms in `km.dart`.
- Real OCR: plug ML Kit or Tesseract into `_simulate()` in `ocr_screen.dart`.
- The reminder time is saved, but no notification is sent yet.

Fonts: Google Sans and Noto Sans Khmer (SIL Open Font License), Material Design Icons (Apache 2.0). Licences are in `assets/fonts/`.
