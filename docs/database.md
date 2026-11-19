# Database how-to

One SQLite file for the whole API, managed with [Drizzle](https://orm.drizzle.team).
The file is `api/data/ehealth.db` by default (`DB_FILE` in `api/.env`); it is git-ignored.

All commands below run from the repo root.

## 1. Add a table

Tables live only in your own module: `api/src/modules/<module>/schema.ts`.
This is an **example only** (a made-up `example` module), not a real file:

```ts
// api/src/modules/example/schema.ts
import { index, integer, sqliteTable, text } from 'drizzle-orm/sqlite-core';
import { newId } from '../../shared/ids';

export const notes = sqliteTable(
  'notes',
  {
    id: text('id').primaryKey().$defaultFn(newId), // ids are text UUIDs
    title: text('title').notNull(),
    pinned: integer('pinned', { mode: 'boolean' }).notNull().default(false),
    createdAt: text('created_at') // dates are ISO strings in text columns
      .notNull()
      .$defaultFn(() => new Date().toISOString()),
  },
  (t) => [index('notes_created_at_idx').on(t.createdAt)],
);
```

To point a foreign key at another module's table, import that table from the other module's
`index.ts` (never from its `schema.ts`). You may reference it, but never write to it.

## 2. Generate and commit a migration

1. Update your branch from main first: `git pull origin main`.
2. Generate: `pnpm --filter @ehealth/api db:generate`. This writes SQL into `api/drizzle/`.
3. Read the generated `.sql` file, then commit the whole `api/drizzle/` folder with your change.

If migration files clash when you merge main, delete **your** new migration (the `.sql` file
and its entries in `api/drizzle/meta/`), merge, and run `db:generate` again.

## 3. Apply migrations

```sh
pnpm --filter @ehealth/api db:migrate
```

The API also applies migrations every time it starts (`pnpm --filter @ehealth/api dev`).

## 4. Startup and seed hooks

Your module's `index.ts` may export two optional functions. Both get the database:

```ts
// api/src/modules/example/index.ts
import type { Db } from '../../shared/db';

export function startup(db: Db) {
  // Runs on every API start, after migrations. E.g. insert required rows that are missing.
}

export function seed(db: Db) {
  // Demo data for development. Runs only with db:seed / db:reset.
}
```

- Hooks run in a fixed order: accounts, readings, ocr, reports.
- Both must be safe to run twice (e.g. `.onConflictDoNothing()`) and only touch your own tables.

```sh
pnpm --filter @ehealth/api db:seed   # migrate, startups, then seeds
```

## 5. Reset your local database

```sh
pnpm --filter @ehealth/api db:reset
```

Deletes the database file, then runs migrations, startups and seeds. It refuses to run when
`NODE_ENV=production`.

## 6. Look at the data

```sh
pnpm --filter @ehealth/api db:studio
```

Opens Drizzle Studio in the browser to browse and edit the tables.
