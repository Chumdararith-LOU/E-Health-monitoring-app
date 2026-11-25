import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { describe, expect, it, vi } from 'vitest';
import { type AppModule, runSeeds, runStartups, toAppModule } from '../modules';
import { createDb, type Db, runMigrations } from './db';

describe('createDb', () => {
  it("opens ':memory:' with foreign keys on", () => {
    const db = createDb(':memory:');
    expect(db.$client.pragma('foreign_keys', { simple: true })).toBe(1);
    db.$client.close();
  });
});

describe('runMigrations', () => {
  it('skips without an error when there are no migrations yet', () => {
    const emptyFolder = mkdtempSync(join(tmpdir(), 'ehealth-migrations-'));
    const log = vi.spyOn(console, 'log').mockImplementation(() => {});
    try {
      expect(() => runMigrations(createDb(':memory:'), emptyFolder)).not.toThrow();
      expect(log).toHaveBeenCalledWith('no migrations yet');
    } finally {
      log.mockRestore();
      rmSync(emptyFolder, { recursive: true });
    }
  });
});

describe('module hooks', () => {
  it('runStartups and runSeeds call the hooks in order and skip missing ones', async () => {
    const db = createDb(':memory:');
    const calls: string[] = [];
    const hook = (name: string) => async (received: Db) => {
      expect(received).toBe(db);
      calls.push(name);
    };
    // Fake index.ts exports: some modules have hooks, some don't
    const fakeModules: AppModule[] = [
      toAppModule('a', { aRouter: {}, startup: hook('a.startup'), seed: hook('a.seed') }),
      toAppModule('b', { bRouter: {} }),
      toAppModule('c', { startup: hook('c.startup') }),
      toAppModule('d', { seed: hook('d.seed'), startup: 'not a function' }),
    ];

    await runStartups(db, fakeModules);
    await runSeeds(db, fakeModules);

    expect(calls).toEqual(['a.startup', 'c.startup', 'a.seed', 'd.seed']);
    db.$client.close();
  });

  it('migrations, startups, and seeds run cleanly and are safe to run twice', async () => {
    const db = createDb(':memory:');
    runMigrations(db);
    await runStartups(db);
    await runSeeds(db);

    const counts = () =>
      Object.fromEntries(
        ['users', 'patient_links', 'invite_codes', 'doctor_notes', 'custom_fields', 'readings', 'reading_values', 'reminders'].map(
          (table) => [
            table,
            (db.$client.prepare(`SELECT count(*) AS n FROM ${table}`).get() as { n: number }).n,
          ],
        ),
      );

    const first = counts();
    expect(first.users).toBeGreaterThanOrEqual(18);
    expect(first.patient_links).toBeGreaterThanOrEqual(15);
    expect(first.custom_fields).toBe(5);
    expect(first.readings).toBeGreaterThan(300);
    expect(first.reading_values).toBeGreaterThan(1200);
    expect(first.reminders).toBe(5);

    // Running startups and seeds a second time must not duplicate rows or throw.
    await runStartups(db);
    await runSeeds(db);
    expect(counts()).toEqual(first);
    db.$client.close();
  });
});
