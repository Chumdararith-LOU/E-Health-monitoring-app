// Idempotent startup & development seed for readings (built-in fields, custom fields, 90-day readings, reminders).

import type { Db } from '../../shared/db';
import { devUsers } from '../../shared/dev/dev-users';
import { customFields, readings, readingValues, reminders } from './schema';

const BUILT_IN_FIELDS: (typeof customFields.$inferInsert)[] = [
  {
    id: 'systolic',
    nameEn: 'Systolic',
    nameKm: 'សម្ពាធខាងលើ',
    unit: 'mmHg',
    decimals: 0,
    minValue: 50,
    maxValue: 260,
    normalMin: 90,
    normalMax: 129,
    builtIn: true,
    active: true,
  },
  {
    id: 'diastolic',
    nameEn: 'Diastolic',
    nameKm: 'សម្ពាធខាងក្រោម',
    unit: 'mmHg',
    decimals: 0,
    minValue: 30,
    maxValue: 160,
    normalMin: 60,
    normalMax: 84,
    builtIn: true,
    active: true,
  },
  {
    id: 'pulse',
    nameEn: 'Pulse',
    nameKm: 'ជីពចរ',
    unit: 'bpm',
    decimals: 0,
    minValue: 30,
    maxValue: 220,
    normalMin: 60,
    normalMax: 100,
    builtIn: true,
    active: true,
  },
  {
    id: 'glucose',
    nameEn: 'Blood sugar',
    nameKm: 'ជាតិស្ករក្នុងឈាម',
    unit: 'mg/dL',
    decimals: 0,
    minValue: 20,
    maxValue: 600,
    normalMin: 70,
    normalMax: 130,
    builtIn: true,
    active: true,
  },
];

const DEMO_CUSTOM_FIELDS: (typeof customFields.$inferInsert)[] = [
  {
    id: 'weight',
    nameEn: 'Weight',
    nameKm: 'ទម្ងន់',
    unit: 'kg',
    decimals: 1,
    minValue: 20,
    maxValue: 250,
    builtIn: false,
    active: true,
  },
];

// Deterministic PRNG so `db:reset` always generates the exact same 90 days of readings.
function mulberry32(seed: number) {
  let a = seed;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

interface SeedProfile {
  patientId: string;
  enteredBy: string;
  sys: number;
  dia: number;
  pulse: number;
  glucose: number;
  weight?: number;
  skipToday?: boolean;
  skipLastDays?: number;
  trend?: number;
}

const PROFILES: SeedProfile[] = [
  {
    patientId: devUsers.patient.id,
    enteredBy: devUsers.patient.id,
    sys: 126,
    dia: 78,
    pulse: 74,
    glucose: 108,
    weight: 66.5,
  },
  {
    patientId: 'p1',
    enteredBy: 'p1',
    sys: 128,
    dia: 77,
    pulse: 76,
    glucose: 110,
    weight: 68.5,
    skipToday: true,
    trend: -5,
  },
  {
    patientId: 'p2',
    enteredBy: 'c1',
    sys: 114,
    dia: 72,
    pulse: 72,
    glucose: 98,
  },
  {
    patientId: 'p3',
    enteredBy: 'p3',
    sys: 120,
    dia: 78,
    pulse: 80,
    glucose: 158,
    weight: 74.0,
    skipLastDays: 3,
  },
  {
    patientId: 'p4',
    enteredBy: 'c1',
    sys: 148,
    dia: 90,
    pulse: 70,
    glucose: 110,
    trend: 8,
  },
];

export function ensureBuiltInFields(db: Db): void {
  db.insert(customFields).values(BUILT_IN_FIELDS).onConflictDoNothing().run();
}

export function seedReadings(db: Db, now = new Date()): void {
  ensureBuiltInFields(db);
  db.insert(customFields).values(DEMO_CUSTOM_FIELDS).onConflictDoNothing().run();

  const rand = mulberry32(20261125);
  const readingRows: (typeof readings.$inferInsert)[] = [];
  const valueRows: (typeof readingValues.$inferInsert)[] = [];

  // Midnight UTC baseline aligned to morning Phnom Penh time (~06:30 UTC+7 = 23:30 UTC previous day,
  // using 00:00 UTC = 07:00 Asia/Phnom_Penh so every day falls cleanly on the expected local date).
  const todayUtc = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  const DAY_MS = 24 * 60 * 60 * 1000;

  for (const p of PROFILES) {
    for (let ago = 89; ago >= 0; ago--) {
      if (p.skipToday && ago === 0) continue;
      if (p.skipLastDays && ago < p.skipLastDays) continue;
      if (ago > 0 && rand() < 0.08) continue;

      const progress = (89 - ago) / 30;
      const drift = (p.trend ?? 0) * (progress - 1.5);
      const jitter = (sd: number) => Math.round((rand() - 0.5) * 2 * sd);

      const sys = Math.max(85, Math.min(220, Math.round(p.sys + drift + jitter(8))));
      const dia = Math.max(50, Math.min(sys - 15, Math.round(p.dia + drift * 0.4 + jitter(5))));
      const pulse = Math.max(48, Math.min(130, Math.round(p.pulse + jitter(7))));
      const glu = Math.max(55, Math.min(350, Math.round(p.glucose + jitter(16))));

      const minutesOffset = Math.floor(rand() * 45); // 07:00 – 07:44 Phnom Penh
      const measuredAt = new Date(todayUtc - ago * DAY_MS + minutesOffset * 60 * 1000).toISOString();
      const id = `seed-r-${p.patientId}-d${ago}`;

      readingRows.push({
        id,
        patientId: p.patientId,
        enteredBy: p.enteredBy,
        measuredAt,
        method: rand() < 0.4 ? 'ocr' : 'manual',
      });

      valueRows.push(
        { readingId: id, fieldKey: 'systolic', value: sys },
        { readingId: id, fieldKey: 'diastolic', value: dia },
        { readingId: id, fieldKey: 'pulse', value: pulse },
        { readingId: id, fieldKey: 'glucose', value: glu },
      );

      if (p.weight != null && ago % 3 === 0) {
        const w = Math.round((p.weight + (rand() - 0.5) * 1.2) * 10) / 10;
        valueRows.push({ readingId: id, fieldKey: 'weight', value: w });
      }
    }
  }

  db.transaction((tx) => {
    if (readingRows.length > 0) {
      tx.insert(readings).values(readingRows).onConflictDoNothing().run();
    }
    if (valueRows.length > 0) {
      tx.insert(readingValues).values(valueRows).onConflictDoNothing().run();
    }
    tx.insert(reminders)
      .values(
        PROFILES.map((p) => ({
          patientId: p.patientId,
          enabled: true,
          minutesAfterMidnight: 6 * 60 + 30,
        })),
      )
      .onConflictDoNothing()
      .run();
  });
}
