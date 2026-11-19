import { existsSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import Database from 'better-sqlite3';
import { type BetterSQLite3Database, drizzle } from 'drizzle-orm/better-sqlite3';
import { migrate } from 'drizzle-orm/better-sqlite3/migrator';
import { apiDir, config } from '../config';

export type Db = BetterSQLite3Database & { $client: Database.Database };

const migrationsFolder = join(apiDir, 'drizzle');

export function createDb(file: string): Db {
  if (file !== ':memory:') mkdirSync(dirname(file), { recursive: true });
  const sqlite = new Database(file);
  sqlite.pragma('journal_mode = WAL');
  sqlite.pragma('foreign_keys = ON');
  return drizzle({ client: sqlite });
}

export function runMigrations(db: Db, folder = migrationsFolder): void {
  if (!existsSync(join(folder, 'meta', '_journal.json'))) {
    console.log('no migrations yet');
    return;
  }
  migrate(db, { migrationsFolder: folder });
}

let shared: Db | undefined;

// The app's database, opened on first use (importing this file opens nothing).
export function getDb(): Db {
  shared ??= createDb(config.DB_FILE);
  return shared;
}
