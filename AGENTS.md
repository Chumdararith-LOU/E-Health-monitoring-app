# AGENTS.md

## Context

- Project: "E-Health Monitoring App", a final-year project for a team of 4.
- Stack: pnpm workspaces monorepo (TypeScript for API, web, and shared types; Flutter/Dart for mobile):
  - `api/` (Node.js + Express)
  - `web/` (React + Vite)
  - `mobile/` (Flutter / Dart – not part of the pnpm workspace; managed with `flutter pub`)
  - `packages/types/` (shared TypeScript types)
  - `docs/`
- Architecture: modular monolith. One API, one SQLite file.
- Modules and owners:
  - `accounts`: Phayuk
  - `readings`: Seyla
  - `ocr`: Phak
  - `reports`: Rith
  - Rith also owns the shared/platform code.
- Khmer (`km`) is the default language, English (`en`) second.

## Rules for the coding agent

- Do only the step you are asked for. Keep changes small.
- Never commit directly to main. Work on the branch I name; main only changes through pull
  requests (squash merge).
- After each step: run the relevant checks, then make ONE git commit with a short, informal,
  lowercase message (e.g. "add api skeleton"). Do not push unless asked.
- Each module stays in its own area:
  - API: `api/src/modules/<module>` (with its own DB `schema.ts`).
  - Web: each member works on their assigned pages in `web/src/pages/` (see `web/README.md`).
  - Mobile: each member works on their assigned screens in `mobile/lib/screens/` (see `mobile/README.md`).
- Never edit another module's files. Shared/platform code (owned by Rith) lives in:
  - `api/src/shared/`, `packages/types/`
  - `web/src/ui/`, `web/src/lib/`, `web/src/store/`, `web/src/i18n/`
  - `mobile/lib/widgets/`, `mobile/lib/state/`, `mobile/lib/theme/`, `mobile/lib/l10n/`
- All user-facing text goes through i18n/l10n keys, never hard-coded strings. Khmer (`km`) is the
  default. Strings are split per module to avoid merge conflicts:
  - Web: `web/src/i18n/modules/<module>.ts` (`shared`, `accounts`, `readings`, `ocr`, `reports`), merged by `km.ts` & `en.ts`.
  - Mobile: `mobile/lib/l10n/modules/<module>.dart` (`shared`, `accounts`, `readings`, `ocr`, `reports`), merged by `km.dart` & `en.dart`.
  - Edit only your own module's file; Rith owns `shared` and the merged barrels.
- A module may import another module ONLY from its `index.ts` (its public API), never its
  internal files.
- A module never writes to another module's tables.
- A module's tables live only in its own `api/src/modules/<module>/schema.ts`.
- Other modules may reference a table for a foreign key (imported from that module's `index.ts`)
  but never write to it.
- Seeds must be safe to run twice and only touch the module's own tables.
- Before `db:generate`, update your branch from main. If migration files clash in a merge, delete
  your new migration and generate it again.
- The API returns i18n keys (`messageKey`), never Khmer or English text.
- Every route that returns or changes patient data uses `requireAuth` + `requirePatientAccess`.
- Tokens are created only with `signToken()` from `api/src/shared/auth.ts`.
- The real access rule is plugged in with `registerAccessChecker` from the accounts module;
  never edit `shared/access.ts` to add module logic.
