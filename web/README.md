# E-Health Web Portal (Doctor + Admin)

This is the React + Vite + TypeScript web app for the E-Health Monitoring project. It follows the **E-Health Web Portal** design canvas and uses the same tokens and copy as the mobile app.

All data is **hard-coded** in `src/data/mock.ts`, and there is no backend yet. Each module owner replaces the mock calls with their own API.

## Run it

Requires Node 20.19+ or 22.12+ (Vite 8).

```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # type-check + production build into dist/
npm run preview    # serve dist/ on http://localhost:4173
```

`dist/` uses relative paths (`base: './'`), so you can drop it on any static host or in a sub-folder.

## Demo logins

| Role   | ID                 | Password |
|--------|--------------------|----------|
| Doctor | `012 555 001`      | `1234`   |
| Admin  | `admin@ehealth.kh` | `1234`   |

A session lasts 7 days and is stored in `localStorage` (`ehealth.web.session`). Language and numeral preferences are stored in `ehealth.web.prefs`.

## DEV strip (yellow bar)

The DEV strip is for testers:

- It switches between the Doctor and Admin roles without signing in.
- It simulates the 5-state checklist: `loading`, `empty`, `error`, `offline`, plus `revoked` (the doctor's access to a patient was removed).

Hide it for demos or production with:

```bash
VITE_HIDE_DEV=1 npm run build
```

Patient, Caretaker and Family roles are **mobile-only**, so they are not part of the web app.

## Routes (hash router, no package)

| Route                     | Page                           | Role   |
|---------------------------|--------------------------------|--------|
| `#/login`                 | Login                          | —      |
| `#/doctor`                | Patient dashboard (triage)     | Doctor |
| `#/doctor/patient/:id`    | Patient report + clinical notes| Doctor |
| `#/admin/users`           | Users & roles                  | Admin  |
| `#/admin/fields`          | Custom field builder           | Admin  |

`App.tsx` guards the routes. A user who is not signed in goes to the login page. A doctor cannot open `/admin/*` and an admin cannot open `/doctor/*`; both are sent back to their own home page.

## Code map and owners

| File | What | Owner |
|---|---|---|
| `src/pages/Login.tsx` | Sign in, validation, session-expired banner | Phayuk |
| `src/pages/DoctorDashboard.tsx` | Triage list, search/filter/sort, photo viewer | Phayuk |
| `src/pages/AdminUsers.tsx` | Role change (one role per user), disable/enable, last-admin guard | Phayuk |
| `src/pages/AdminFields.tsx` | Custom field definition, live preview, publish | Seyla |
| `src/pages/PatientReport.tsx` | Period stats, charts, day log, notes, print-to-PDF | Rith |
| `src/components/TrendChart.tsx` | SVG trend chart (normal band, flags, gaps, tooltip) | Rith |
| `src/components/*` | Header, DEV strip, badges, alerts, panels, pager, photo modal | Rith (shared) |
| `src/i18n/strings.ts` | All Khmer/English copy and number/date formatting | Rith (shared) |
| `src/lib/stats.ts` | Range checks, triage, min/avg/max | Shared |
| `src/state/AppState.tsx` | Session, prefs, data and actions | Shared |
| `src/data/mock.ts` | **Hard-coded data, to be replaced by APIs** | Shared |

## Where to plug in the API

Every read and write goes through `src/state/AppState.tsx`:

| Action in AppState | Replace with |
|---|---|
| `login(id, pw)` | `POST /auth/login` (returns the session and role) |
| `buildSampleData()` on load | `GET /doctor/patients`, `GET /patients/:id/readings`, `GET /admin/users`, `GET /fields` |
| `addNote(patientId, text)` | `POST /patients/:id/notes` |
| `setUserRole(userId, role)` | `PATCH /admin/users/:id` (keep the server-side last-admin check) |
| `setUserActive(userId, on)` | `PATCH /admin/users/:id` |
| `saveField(field)` / `setFieldActive(id, on)` | `PUT /fields/:id` |

The pages only call these functions, so swapping the mock for `fetch` does not change any page. Map `loading`/`error`/`offline` from your fetch status onto the same UI states that the DEV strip simulates.

## Placeholders to confirm

- Normal ranges: systolic 90–120, diastolic 60–80, glucose 70–125 mg/dL, pulse 60–100 bpm.
- Hard limits for diastolic (30–150) and pulse (30–220) were picked for the demo.
- Glucose unit: mg/dL only for now (mmol/L is still open).
- The clinic PDF uses the browser's print dialog (`window.print()` with a print stylesheet). A server-rendered PDF can replace it later.

## Fonts

Noto Sans Khmer and Share Tech Mono are bundled under `src/assets/fonts/` (SIL OFL 1.1, licences included). They work offline.
