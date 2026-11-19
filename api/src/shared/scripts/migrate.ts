import { config } from '../../config';
import { getDb, runMigrations } from '../db';

const db = getDb();
runMigrations(db);
db.$client.close();
console.log(`migrated ${config.DB_FILE}`);
