// Owner: Rith (shared). Every module router, mounted by app.ts under /api/v1,
// and every module's optional startup(db) / seed(db) hook.
import type { Db } from '../shared/db';
import * as accounts from './accounts';
import * as ocr from './ocr';
import * as readings from './readings';
import * as reports from './reports';

export const moduleRouters = [
  accounts.accountsRouter,
  readings.readingsRouter,
  ocr.ocrRouter,
  reports.reportsRouter,
];

type Hook = (db: Db) => void | Promise<void>;

export interface AppModule {
  name: string;
  startup?: Hook;
  seed?: Hook;
}

// Picks up startup/seed from a module's index.ts exports when they are there.
export function toAppModule(name: string, exports: object): AppModule {
  const { startup, seed } = exports as { startup?: unknown; seed?: unknown };
  return {
    name,
    startup: typeof startup === 'function' ? (startup as Hook) : undefined,
    seed: typeof seed === 'function' ? (seed as Hook) : undefined,
  };
}

// Fixed order: accounts first, so later modules can rely on its data.
export const modules: AppModule[] = [
  toAppModule('accounts', accounts),
  toAppModule('readings', readings),
  toAppModule('ocr', ocr),
  toAppModule('reports', reports),
];

export async function runStartups(db: Db, list: readonly AppModule[] = modules): Promise<void> {
  for (const module of list) await module.startup?.(db);
}

export async function runSeeds(db: Db, list: readonly AppModule[] = modules): Promise<void> {
  for (const module of list) await module.seed?.(db);
}
