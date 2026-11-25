# E-Health Web Portal (Doctor + Admin)

This is the React + Vite + TypeScript web app (`@ehealth/web`) in the E-Health Monitoring monorepo. It is for **doctors and admins**; patients, caretakers and family use the mobile app.

It has the same look as the mobile app: Google Sans for Latin text, Noto Sans Khmer for Khmer, the same blue, the same status colours and the same normal ranges. Khmer is the default language and English is the second.

The screens run on **demo data saved in the browser** (`localStorage`). There is no backend call in the pages yet. `src/store/AppStore.tsx` plays the role of the future API, so each module owner can swap its actions for real API calls without changing the pages (see [Where to plug in the API](#where-to-plug-in-the-api)).

Design decisions (HCI / UX) and requirement coverage are in [`docs/DESIGN.md`](docs/DESIGN.md).

## Run it

Requires **Node 24** (see root `.nvmrc`) and **pnpm**. Run commands from the **repo root** (do not run `npm install` inside `web/`):

```bash
pnpm install                          # install all workspace packages
pnpm --filter @ehealth/web dev        # web only, http://localhost:5173
pnpm typecheck                        # type-check types, api, and web
pnpm build                            # production builds for api and web
pnpm --filter @ehealth/web preview    # serve web/dist/ on http://localhost:4173
```

`pnpm --filter @ehealth/web dev` also prints a `Network:` address, such as `http://192.168.1.20:5173`. Open it on a phone on the same Wi-Fi to see the doctor's mobile view.

`dist/` uses relative paths (`base: './'`) and a hash router, so it can be served from any static host or sub-folder.

## Demo accounts

On the sign-in page, tap an account, or type its phone or email with the password `123456`.

| Account           | Role   | Sign in with       | What to try                                                                                                                                 |
| ----------------- | ------ | ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------- |
| Dr. Lim Bunthoeun | Doctor | `023 900 100`      | Dashboard with 8 patients, the ones needing attention first. Search, filter, sort. Open a patient → charts, readings, notes, **Export PDF** |
| Dr. Ouk Malis     | Doctor | `023 900 200`      | Fewer patients; one link is still waiting for the patient's approval                                                                        |
| System Admin      | Admin  | `admin@ehealth.kh` | Change roles (with Undo), add a tracked field, archive or restore fields, remove links, fix or delete readings                              |

Phone numbers of patients, caretakers and family are rejected with a message to use the mobile app.

The demo data is kept in `localStorage` (`ehealth-web-demo-v1` key). **Settings → Reset demo data** brings it back. The web app and the mobile app each keep their own demo data until the API exists.

## Routes (hash router)

| Route              | Page                                    | Role                       |
| ------------------ | --------------------------------------- | -------------------------- |
| `#/signin`         | Sign in                                 | —                          |
| `#/patients`       | My patients (triage dashboard)          | Doctor                     |
| `#/patients/:id`   | Patient: overview, readings, notes, PDF | Doctor (admin for support) |
| `#/admin/users`    | Users & roles                           | Admin                      |
| `#/admin/fields`   | Tracked fields (custom fields)          | Admin                      |
| `#/admin/links`    | Care-team links                         | Admin                      |
| `#/admin/readings` | Readings support (edit / delete)        | Admin                      |
| `#/settings`       | Language, numerals, text size, reset    | Both                       |

Tabs, period and filters are kept in the URL (`?tab=readings&p=90`), so Back, Refresh and bookmarks work. A user who is not signed in goes to the sign-in page; each role only sees its own pages.

## Code map and owners

| File                                         | What                                                                    | Owner         |
| -------------------------------------------- | ----------------------------------------------------------------------- | ------------- |
| `src/pages/SignInPage.tsx`                   | Sign in, validation, demo accounts, mobile-only roles redirected        | Phayuk        |
| `src/pages/DashboardPage.tsx`                | Triage dashboard: KPI tiles, search, filter, sort, sparklines, flags    | Phayuk        |
| `src/pages/admin/UsersPage.tsx`              | Role change (confirm + undo, not your own role)                         | Phayuk        |
| `src/pages/admin/LinksPage.tsx`              | Care-team links overview, remove + undo                                 | Phayuk        |
| `src/pages/admin/FieldsPage.tsx`             | Custom field builder, live preview, archive / restore                   | Seyla         |
| `src/pages/admin/ReadingsSupportPage.tsx`    | Admin edit / delete of readings, same validation as mobile              | Seyla         |
| `src/ui/ReadingModal.tsx`                    | Reading detail with each value next to its normal range                 | Seyla         |
| `src/pages/PatientPage.tsx`                  | Period stats, charts, readings table, notes, print-to-PDF               | Rith          |
| `src/ui/Charts.tsx`                          | SVG line chart (normal band, tooltip, keyboard), sparkline, table view  | Rith          |
| `src/pages/SettingsPage.tsx`                 | Language, Khmer numerals, text size, reset demo data                    | Rith (shared) |
| `src/App.tsx`                                | Routes, role-based navigation, sidebar / phone bottom bar               | Rith (shared) |
| `src/ui/Kit.tsx`, `Feedback.tsx`, `Icon.tsx` | Button, Field, Segmented, Chip, Tabs, Badge; dialog + toast; icons      | Rith (shared) |
| `src/styles/app.css`                         | Design tokens, every component style, responsive and print layout       | Rith (shared) |
| `src/i18n/`                                  | `km.ts` (default), `en.ts`, Khmer numerals and dates                    | Rith (shared) |
| `src/store/AppStore.tsx`                     | Local store standing in for the API (`canView` on every read)           | Rith (shared) |
| `src/data/`                                  | Demo seed, normal ranges, stats, validation (same rules as mobile)      | Shared        |
| `src/lib/api.ts`                             | Shared HTTP client (`apiRequest`, `ApiClientError`, dev login, reports) | Rith (shared) |

## Where to plug in the API

Use `apiRequest<T>()` from `src/lib/api.ts` for all API calls. It handles `VITE_API_URL` (default `http://localhost:3000/api/v1`), attaches `Authorization: Bearer <token>` when `token` is passed, supports `AbortSignal`, and throws `ApiClientError` with the backend's `messageKey`.

Already wired in the app (falls back to local demo data when the API server is not running):

- `apiDevLogin(role)` → `POST /api/v1/dev/login` (called by `AppStore.signIn` to obtain a dev JWT)
- `apiGetPatientSummary(patientId, days, token, signal)` → `GET /api/v1/patients/:patientId/summary` (called by `PatientPage`)

Ready in `src/lib/api.ts` for when live series data is wired:

- `apiGetPatientSeries(patientId, field, days, token, signal)` → `GET /api/v1/patients/:patientId/series`

Actions in `src/store/AppStore.tsx` to replace as modules land:

| Store action                      | Replace with                                                   |
| --------------------------------- | -------------------------------------------------------------- |
| `signIn(id)`                      | `POST /api/v1/auth/login` (returns JWT + user)                 |
| `makeSeed()` on load              | `GET` patients, readings, users, links and fields from the API |
| `upsertReading` / `deleteReading` | `PUT` / `DELETE /api/v1/readings/:id` (admin support)          |
| `addNote`                         | `POST /api/v1/patients/:id/notes`                              |
| `setRole`                         | `PATCH /api/v1/admin/users/:id`                                |
| `upsertField`                     | `PUT /api/v1/fields/:id`                                       |
| `removeLink` / `restoreLink`      | `DELETE` / `POST /api/v1/links`                                |

## Placeholders to confirm

- Normal ranges (`src/data/ranges.ts`): systolic 90–129, diastolic 60–84, pulse 60–100 bpm, glucose 70–130 mg/dL. Confirm the medical reference.
- Safe input limits: systolic 50–260, diastolic 30–160, pulse 30–220, glucose 20–600.
- Glucose unit: mg/dL only for now.
- Export PDF uses the browser's print dialog with a print stylesheet. A server-rendered PDF can replace it later.
- Ask a native speaker to review the Khmer wording in `src/i18n/km.ts`.

## Fonts

Google Sans and Noto Sans Khmer are bundled under `src/assets/fonts/` (SIL OFL 1.1, licences included). They work offline.
