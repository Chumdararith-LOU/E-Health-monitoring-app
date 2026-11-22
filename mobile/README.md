# E-Health Mobile (Flutter) — design build, no backend

The mobile app from the design canvas **"E-Health Mobile App — Home, Record, Reports, Links"**, built in Flutter with **hard-coded sample data**. Every screen and state from the canvas is here and clickable, in **Khmer (default) and English**.

- No server, no database, no internet needed. Data lives in memory and resets when you close the app.
- **No third-party packages**, only the Flutter SDK. You can build it as soon as Flutter is installed.
- The camera and OCR are **simulated**. The viewfinder shows a drawn device, and the "OCR" returns sample numbers.

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

The first time, also run `flutter analyze` and `flutter test`. This build was written without a Flutter SDK available, so this is the first real compile. If anything fails, copy the error message and send it to Claude.

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

The app follows the phone's **font size** setting so elderly users get bigger text, capped at 1.3× so the layout doesn't break. It is portrait-only.

---

## 2. What's inside

| Tab | Screens and states |
|---|---|
| **Home** | Not recorded yet · Recorded today · Caretaker (patient switcher) · Family read-only (no Record tab, no buttons) · Offline, waiting to sync · New account (empty) |
| **Record** | Camera (BP / glucose mode, flash, type manually) → Reading photo (progress, 6 s note) → Review (photo pinned on top; OCR badges; amber low-confidence; glucose added to the same reading) · Hard-limit error (e.g. 728) with Save disabled · Systolic/diastolic swap · Duplicate-morning guard (Replace / Keep both / Cancel) · Type manually · Discard confirm |
| **Reports** | 7 / 30 / 90 days / Custom range · Min-Avg-Max table (includes the Admin custom field "Body weight") · BP, glucose, pulse and weight charts (tap a point for a tooltip) · Export PDF (placeholder dialog, US-18) |
| **History** | Newest first · From/To date filter · Missed-day rows · OCR / Manual / OCR + edited badges · Edit and Delete on your own entries · View photo · Pages of 10 |
| **Links & Settings** | Invite code with live 24 h countdown, Copy, New code · Linked people with Remove access · Morning reminder (time picker + preview) · Language · Khmer/Arabic numerals · Sign out (resets the sample data) |

### Demo controls (yellow DEV strip)

Tap the yellow strip under the sync status, or scroll to the bottom of Links & Settings. From there you can switch:

- **Role:** Patient / Caretaker / Family
- **Recorded today** on/off
- **Offline:** saved readings wait. Turn it off to see "Syncing...", then "Synced".
- **New account:** no readings
- **What the OCR returns:** Clear / Partial / Failed / Misread

For a clean build, set `kShowDevStrip = false` in `lib/widgets/demo_controls.dart`. Those labels are English on purpose because it's a developer tool.

---

## 3. Code map (who wires what to the backend)

```
lib/
  main.dart, app.dart           app start, theme, KH/EN locale, text-size cap
  theme/tokens.dart             ALL colours, type scale, spacing (from design-tokens doc)
  l10n/strings.dart             ALL text, Khmer + English (NFR-01), Khmer numerals (NFR-02)
  data/models.dart              Reading, VitalField schema (core + Admin custom fields), OcrResult
  data/mock_data.dart           ← the hard-coded data. Replace with API calls.
  state/app_state.dart          in-memory state + demo switches (AppScope.of(context))
  widgets/                      the shared UI kit (header, tab bar, TactileButton, BoxedPanel,
                                SegmentedToggle, VitalInputGroup, StatusAlertBanner, StatusBadge,
                                ConfirmModal, TrendChart, DeviceLcd)
  screens/home/                 Home tab                      → Rith (US-14, US-13)
  screens/record/camera_screen  camera + OCR step              → Phak (US-07/08/09)
  screens/record/record_flow    simulateOcr() → real OCR       → Phak
  screens/record/review_screen  review / manual / edit form    → Seyla (US-04/05)
  screens/reports/report_view   Min/Avg/Max + charts           → Rith (US-10/11)
  screens/reports/history_view  history list                   → Seyla (US-06)
  screens/links/links_tab       invite code, links, settings   → Phayuk (US-03), Seyla (US-17), Rith (US-15)
```

Rules from the team docs that this code already follows:

- Screens only use the shared widgets and tokens, never raw colours. Text comes from `strings.dart`, never typed into a screen.
- **OCR → Review contract:** `OcrResult { mode, systolic, diastolic, pulse, glucose, unit, conf, failed, offline }`. Phak returns it and Seyla's review screen reads it.
- **Schema-driven fields:** add an Admin field to `Fields.custom` in `models.dart`. It then appears in the form, the Reports table and the charts with no other change.
- Every status is colour + icon + text. Hard stops block Save, soft flags only warn (FR-06). The duplicate same-morning entry gets a modal (FR-05).

### Placeholders to settle as a team

- Normal ranges (systolic 90–120, diastolic 60–80, glucose 70–125 mg/dL) need a chosen reference.
- Diastolic and pulse hard limits (30–150, 30–220) were my choice. T3 only fixes systolic and glucose.
- Glucose accepts mg/dL or mmol/L and is stored as mg/dL (×18).
- Entries recorded by the caretaker show **View photo** instead of Edit/Delete for the patient. US-05 says "own entries".

Fonts: Noto Sans Khmer and Share Tech Mono, both SIL Open Font License (licences in `assets/fonts/`).
