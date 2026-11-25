import type { Db } from '../../shared/db';
import { ensureBuiltInFields, seedReadings } from './seed';

export { listReadings, type PatientReadingRecord } from './queries';
export { readingsRouter } from './routes';
export { customFields, readings, readingValues, reminders } from './schema';

export function startup(db: Db): void {
  ensureBuiltInFields(db);
}

export function seed(db: Db): void {
  seedReadings(db);
}
