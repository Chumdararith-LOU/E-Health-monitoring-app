// Public read helper for other modules (e.g. reports) to query a patient's readings from SQLite.

import { asc, eq, inArray } from 'drizzle-orm';
import type { Db } from '../../shared/db';
import { readings, readingValues } from './schema';

export interface PatientReadingRecord {
  id: string;
  measuredAt: string;
  values: Record<string, number>;
}

export function listReadings(db: Db, patientId: string): PatientReadingRecord[] {
  const rows = db
    .select({ id: readings.id, measuredAt: readings.measuredAt })
    .from(readings)
    .where(eq(readings.patientId, patientId))
    .orderBy(asc(readings.measuredAt))
    .all();

  if (rows.length === 0) return [];

  const readingIds = rows.map((r) => r.id);
  const valRows = db
    .select({
      readingId: readingValues.readingId,
      fieldKey: readingValues.fieldKey,
      value: readingValues.value,
    })
    .from(readingValues)
    .where(inArray(readingValues.readingId, readingIds))
    .all();

  const byReading = new Map<string, Record<string, number>>();
  for (const v of valRows) {
    let map = byReading.get(v.readingId);
    if (!map) {
      map = {};
      byReading.set(v.readingId, map);
    }
    map[v.fieldKey] = v.value;
  }

  return rows.map((r) => ({
    id: r.id,
    measuredAt: r.measuredAt,
    values: byReading.get(r.id) ?? {},
  }));
}
