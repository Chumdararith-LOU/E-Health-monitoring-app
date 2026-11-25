# E-Health Monitoring App

Patients record their blood pressure and blood glucose every morning, either by hand or by
taking a photo of the device screen (read with OCR). Doctors, caretakers and family follow
the readings through reports. The app is Khmer first, with English as a second language.

## Team

| Member | Area                   |
| ------ | ---------------------- |
| Rith   | Reports & platform     |
| Phayuk | Accounts & doctor view |
| Seyla  | Readings               |
| Phak   | OCR                    |

## How to run

### Prerequisites

- Node.js 24 (matches `.nvmrc`)
- pnpm 10 (`corepack enable`)
- Flutter 3.27+ (only needed for `mobile/`)

### API & Web

Run everything from the repository root (do not run `npm install` inside `api/` or `web/`):

```zsh
pnpm install
cp api/.env.example api/.env
pnpm --filter @ehealth/api db:reset
pnpm dev
```

- API: http://localhost:3000/api/v1/health
- Web portal: http://localhost:5173
- Bruno API collection: open `api/requests/ehealth-api/` and select the `local` environment

### Mobile (Flutter)

`mobile/` is not part of the pnpm workspace:

```zsh
cd mobile
flutter pub get
flutter run
```

### Checks before pushing

```zsh
pnpm api:lint && pnpm typecheck && pnpm test && pnpm build
```

For `mobile/`:

```zsh
cd mobile && flutter analyze && flutter test
```

### Team docs

- [AGENTS.md](AGENTS.md) — architecture, module ownership, and git rules
- [docs/database.md](docs/database.md) — Drizzle schemas, migrations, and seeds
- [docs/auth.md](docs/auth.md) — JWT auth, dev login, and patient access checks
- [docs/api/README.md](docs/api/README.md) — OpenAPI contract, linting, and Prism mock server
- [web/README.md](web/README.md) & [mobile/README.md](mobile/README.md) — client setup and screen ownership
