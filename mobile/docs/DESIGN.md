# Mobile app: HCI / UX design notes

**Owner for Design review (T74):** SARITH SEYLA  
**Principle:** reliable and consistent before beautiful. Primary users are older patients and caretakers on a phone; Khmer is the default language.

| User | Context | Design response |
|---|---|---|
| **Patient** | Morning routine at home, large fingers, sometimes poor eyesight | Big primary **Record now** on Home; large fields; safe limits block Save; normal ranges only warn |
| **Caretaker** | Records for one or more patients | Same entry form; **Change** patient switcher on Record / History / Reports |
| **Family** | View only | No edit/delete; same history and reports layout |
| **Doctor (phone)** | Quick check between visits | Attention-first home list; patient page with notes |

Companion web notes: [`web/docs/DESIGN.md`](../../web/docs/DESIGN.md). Team sign-off checklist: [`docs/design-review.md`](../../docs/design-review.md).

## 1. Information architecture

```
Tabs (role-based):  Home · Record · History · Reports · Settings
Push screens:       Reading form · OCR · Reading detail · Links · Patient detail
```

- At most **two levels** from a tab. Back always returns to the previous screen.
- Caretakers switch patient with the same **PatientSwitcher** on Record, History and Reports (never buried in Settings only).
- Settings holds language, numerals, text size, **morning reminder** time, care-team links and reset demo data.

## 2. Heuristics applied

| Principle | Where |
|---|---|
| **Visibility of system status** | Home shows recorded today vs not; toast after save/update/delete; level badge on save |
| **Match with the real world** | Clinical units on every field; morning = before 12:00 local (FR-05); Khmer dates and optional Khmer numerals |
| **User control & freedom** | Delete → toast with **Undo**; discard confirm on dirty form; Replace / Keep both / Cancel on duplicate morning reading |
| **Consistency** | Shared widgets only (`AppButton`, `AppField`, …); same tokens as web (blue, status colours, type scale) |
| **Error prevention** | Safe input limits (FR-06) block Save; family role cannot edit; OCR low-confidence falls back to typing |
| **Recognition rather than recall** | Normal range shown next to each value on detail; out-of-range = colour + icon + word |
| **Flexibility & efficiency** | History: 7 / 30 / 90 / all / custom range; “Only out of range” filter |
| **Minimalist design** | One job per screen; Record is choose method → form, not a dashboard |
| **Help with errors** | Inline messages next to fields (“Enter a number from 50 to 260”) |

## 3. Flows to confirm in Design review (T74)

### 3.1 Manual reading entry (US-04)

1. Home → **Record now**, or Record tab → type or photo.
2. Form shows systolic, diastolic, pulse, glucose, then any **admin custom fields**.
3. Values outside the safe limit → red error, Save disabled.
4. Values outside the normal range → warning only; Save still allowed.
5. Save → toast with level · navigate to Home.

### 3.2 Same-morning duplicate (FR-05)

1. Save a morning reading (takenAt before 12:00).
2. Save another morning reading the same local day.
3. Dialog: **Replace** / **Keep both** / **Cancel** (copy in `l10n/modules/readings.dart`).
4. Replace overwrites the earlier id; Keep both stores both.

### 3.3 Custom fields (US-16 preview)

1. Admin adds a field on web (`FieldsPage`) in the demo store.
2. On mobile (same demo seed / later API), the new field appears on the form, history detail and reports table/chart with **no code change** beyond the fields list.

## 4. Screen map (mock-up → code)

| Screen | Path | Notes for review |
|---|---|---|
| Home | `screens/home/` | Today status; reminder banner when on |
| Record chooser | `screens/record/record_screen.dart` | Photo vs type |
| Reading form | `screens/record/reading_form_screen.dart` | Entry, edit, duplicate, limits |
| OCR | `screens/record/ocr_screen.dart` | Phak; low-confidence → form |
| History | `screens/history/history_screen.dart` | Newest first, period, flagged filter |
| Reading detail | `screens/history/reading_detail_screen.dart` | Edit / delete + undo |
| Settings | `screens/settings/settings_screen.dart` | Reminder time saved; notifications not yet (US-17 Sprint 2) |

## 5. Accessibility & elderly-friendly targets

- Touch targets ≥ 44 dp; text size setting (Normal / Large / Extra large), capped with system scale.
- Contrast and status never by colour alone.
- Khmer line height taller; Noto Sans Khmer + Google Sans.
- Portrait only; layout fluid for ~360–430 dp widths.

## 6. Requirement coverage (mobile, readings-owned)

| Item | Status in mock-up |
|---|---|
| US-04 Manual entry | ✓ form + safe limits + range warnings |
| US-05 Edit / delete + undo | ✓ detail screen |
| US-06 History list / filters | ✓ period + out-of-range |
| FR-05 Morning duplicate | ✓ Replace / Keep both |
| US-16 Custom fields (consume) | ✓ driven by `fields` list |
| US-17 Morning reminder | ◐ time saved; **no** local notification yet |

## 7. Open points for the team

- Confirm demo normal ranges vs WHO / MoH reference (see `docs/kickoff-and-demo-kit.md`).
- Native speaker pass on medical Khmer in `l10n/modules/readings.dart`.
- Sign off this document + a live walkthrough before **Design reviewed** (2026-12-09).
