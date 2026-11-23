# E-Health Web Portal (Doctor + Admin)

This is the React + Vite + TypeScript web app (`@ehealth/web`) in the E-Health Monitoring monorepo. It shares API types from `@ehealth/types` and uses the same design tokens and Khmer/English copy as the mobile app.

Dev login (`POST /api/v1/dev/login`) and patient summary (`GET /api/v1/patients/:patientId/summary`) are already wired to `@ehealth/api`. Other screens still read sample data from `src/data/mock.ts` until each module owner connects their API endpoints.

## Run it

Requires **Node 24** (see root `.nvmrc`) and **pnpm**. Run commands from the **repo root** (do not run `npm install` inside `web/`):

```bash
pnpm install                          # install all workspace packages
pnpm dev                              # run API (:3000) + web (:5173) together
pnpm --filter @ehealth/web dev        # web only (falls back to mock mode if API is off)
pnpm typecheck                        # type-check types, api, and web
pnpm build                            # production builds for api and web
pnpm --filter @ehealth/web preview    # serve web/dist/ on http://localhost:4173
```

`dist/` uses relative paths (`base: './'`), so it can be served from any static host or sub-folder.

## Environment variables

| Variable        | Default                        | Purpose                                                                                       |
| --------------- | ------------------------------ | --------------------------------------------------------------------------------------------- |
| `VITE_API_URL`  | `http://localhost:3000/api/v1` | Base URL for `@ehealth/api`. Override in `web/.env.local` if running the API on another port. |
| `VITE_HIDE_DEV` | (unset)                        | Set to `1` at build time to hide the yellow DEV strip for demos or production.                |

## Demo logins

| Role   | ID                 | Password |
| ------ | ------------------ | -------- |
| Doctor | `012 555 001`      | `1234`   |
| Admin  | `admin@ehealth.kh` | `1234`   |

A session lasts 7 days and is stored in `localStorage` (`ehealth.web.session`). Language and numeral preferences are stored in `ehealth.web.prefs`.

## DEV strip (yellow bar)

The DEV strip is for development and testing:

- Clicking **Doctor** or **Admin** calls `POST /api/v1/dev/login` and stores the real JWT (`api: live`). If the API server is not running, it falls back to a local mock session (`api: mock`).
- It simulates the 5-state checklist: loading, empty, error, offline, plus revoked (doctor's access to a patient was removed).

Hide it for demos or production with:

```bash
VITE_HIDE_DEV=1 pnpm --filter @ehealth/web build
```

Patient, Caretaker, and Family roles are mobile-only, so they are not part of the web app.

## Routes (hash router, no package)

| Route                  | Page                            | Role   |
| ---------------------- | ------------------------------- | ------ |
| `#/login`              | Login                           | —      |
| `#/doctor`             | Patient dashboard (triage)      | Doctor |
| `#/doctor/patient/:id` | Patient report + clinical notes | Doctor |
| `#/admin/users`        | Users & roles                   | Admin  |
| `#/admin/fields`       | Custom field builder            | Admin  |

`App.tsx` guards the routes. A user who is not signed in goes to the login page. A doctor cannot open `/admin/*` and an admin cannot open `/doctor/*`; both are sent back to their own home page.

## Code map and owners

| File                            | What                                                                          | Owner         |
| ------------------------------- | ----------------------------------------------------------------------------- | ------------- |
| `src/pages/Login.tsx`           | Sign in, validation, session-expired banner                                   | Phayuk        |
| `src/pages/DoctorDashboard.tsx` | Triage list, search/filter/sort, photo viewer                                 | Phayuk        |
| `src/pages/AdminUsers.tsx`      | Role change (one role per user), disable/enable, last-admin guard             | Phayuk        |
| `src/pages/AdminFields.tsx`     | Custom field definition, live preview, publish                                | Seyla         |
| `src/pages/PatientReport.tsx`   | Period stats, charts, day log, notes, print-to-PDF                            | Rith          |
| `src/components/TrendChart.tsx` | SVG trend chart (normal band, flags, gaps, tooltip)                           | Rith          |
| `src/components/*`              | Header, DEV strip, badges, alerts, panels, pager, photo modal                 | Rith (shared) |
| `src/lib/api.ts`                | Shared HTTP client (`apiRequest`, `ApiClientError`, dev login, reports calls) | Rith (shared) |
| `src/i18n/strings.ts`           | All Khmer/English copy, number/date formatting, and `apiErrorText()`          | Rith (shared) |
| `src/lib/stats.ts`              | Range checks, triage, min/avg/max                                             | Shared        |
| `src/state/AppState.tsx`        | Session (including JWT token), prefs, data, and actions                       | Shared        |
| `src/data/mock.ts`              | Sample data, gradually replaced by live API calls                             | Shared        |

## Where to plug in the API

Use `apiRequest<T>()` from `src/lib/api.ts` for all API calls. It handles `VITE_API_URL`, attaches `Authorization: Bearer <token>` when `token` is passed, supports `AbortSignal`, and throws `ApiClientError` with the backend's `messageKey`. Translate caught errors for the UI with `apiErrorText(lang, err.messageKey)` from `src/i18n/strings.ts`.

Already wired in `src/lib/api.ts`:

- `apiDevLogin(role)` → `POST /api/v1/dev/login`
- `apiGetPatientSummary(patientId, days, token, signal)` → `GET /api/v1/patients/:patientId/summary`
- `apiGetPatientSeries(patientId, field, days, token, signal)` → `GET /api/v1/patients/:patientId/series`

Remaining actions in `src/state/AppState.tsx` to wire as modules land:

| Action in `AppState`                          | Replace with                                                                                                        |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `login(id, pw)`                               | `POST /api/v1/auth/login` (returns JWT + user)                                                                      |
| `buildSampleData()` on load                   | `GET /api/v1/doctor/patients`, `GET /api/v1/patients/:id/readings`, `GET /api/v1/admin/users`, `GET /api/v1/fields` |
| `addNote(patientId, text)`                    | `POST /api/v1/patients/:id/notes`                                                                                   |
| `setUserRole(userId, role)`                   | `PATCH /api/v1/admin/users/:id` (keep the server-side last-admin check)                                             |
| `setUserActive(userId, on)`                   | `PATCH /api/v1/admin/users/:id`                                                                                     |
| `saveField(field)` / `setFieldActive(id, on)` | `PUT /api/v1/fields/:id`                                                                                            |

Map loading / error / offline / 403 from your fetch calls onto the same UI states that the DEV strip simulates (see `src/pages/PatientReport.tsx` for a working example).

## Placeholders to confirm

- Normal ranges: systolic 90–120, diastolic 60–80, glucose 70–125 mg/dL, pulse 60–100 bpm.
- Hard limits for diastolic (30–150) and pulse (30–220) were picked for the demo.
- Glucose unit: mg/dL only for now (mmol/L is still open).
- The clinic PDF uses the browser's print dialog (`window.print()` with a print stylesheet). A server-rendered PDF can replace it later.

## Fonts

Noto Sans Khmer and Share Tech Mono are bundled under `src/assets/fonts/` (SIL OFL 1.1, licences included). They work offline.
