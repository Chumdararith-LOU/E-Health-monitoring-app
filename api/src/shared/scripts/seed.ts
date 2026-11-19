import { config } from '../../config';
import { runSeeds, runStartups } from '../../modules';
import { getDb, runMigrations } from '../db';

const db = getDb();
runMigrations(db);
await runStartups(db);
await runSeeds(db);
db.$client.close();
console.log(`seeded ${config.DB_FILE}`);
