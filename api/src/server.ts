import { createApp } from './app';
import { config } from './config';
import { runStartups } from './modules';
import { getDb, runMigrations } from './shared/db';

const db = getDb();
runMigrations(db);
await runStartups(db);

createApp().listen(config.PORT, () => {
  console.log(`ehealth-api listening on http://localhost:${config.PORT} (${config.NODE_ENV})`);
});
