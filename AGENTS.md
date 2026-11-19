# AGENTS.md

## Context

- Project: "E-Health Monitoring App", a final-year project for a team of 4.
- Stack: TypeScript everywhere, pnpm workspaces monorepo:
  - `api/` (Node.js + Express)
  - `web/` (React + Vite)
  - `mobile/` (React Native + Expo)
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
- Each module stays in its own folders: `api/src/modules/<module>`, `web/src/modules/<module>`,
  `mobile/src/modules/<module>`. It has its own DB schema file and its own language files
  `locales/km/<module>.json` and `locales/en/<module>.json`.
- Never edit another module's files. Shared code lives in `api/src/shared`, `web/src/shared`,
  `mobile/src/shared` and `packages/types`.
- All user-facing text goes through i18n keys, never hard-coded strings. Khmer is the default.
- A module may import another module ONLY from its `index.ts` (its public API), never its
  internal files.
- A module never writes to another module's tables.
- The API returns i18n keys (`messageKey`), never Khmer or English text.
