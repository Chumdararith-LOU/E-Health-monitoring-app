# API contract (OpenAPI)

One file per module. Only the owner edits it.

| File | Owner |
|---|---|
| openapi.yaml, common.yaml, platform.yaml, reports.yaml | Rith |
| accounts.yaml | Phayuk |
| readings.yaml | Seyla |
| ocr.yaml | Phak |

## Adding an endpoint
1. Describe it in your module file (path item under a key, schemas under `schemas:`), with an example.
2. Add ONE line in `openapi.yaml` under your module's comment:
   `/your/path: { $ref: './yourmodule.yaml#/yourKey' }`
3. Reuse `./common.yaml` for ApiError, Role, AuthUser and the 400/401/403 responses.
4. Run `pnpm api:lint`. Put the contract change in the same pull request as the code.

## Commands
- `pnpm api:lint` – check the contract (CI runs this)
- `pnpm api:docs` – build docs/api/dist/index.html
- `pnpm api:mock` – fake API on http://127.0.0.1:4010 that answers with the examples
- `pnpm api:bundle` – one combined file (docs/api/dist/openapi.yaml) for code generators, e.g. Dart models