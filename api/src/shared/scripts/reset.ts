import { rmSync } from 'node:fs';
import { config } from '../../config';
import { runSeeds, runStartups } from '../../modules';
import { getDb, runMigrations } from '../db';

if (config.NODE_ENV === 'production') {
  console.error('db:reset refuses to run when NODE_ENV=production');
  process.exit(1);
}

if (config.DB_FILE !== ':memory:') {
  // WAL mode keeps two side files next to the database
  for (const suffix of ['', '-wal', '-shm']) rmSync(config.DB_FILE + suffix, { force: true });
}

const db = getDb();
runMigrations(db);
await runStartups(db);
await runSeeds(db);
db.$client.close();
console.log(`reset ${config.DB_FILE}`);
