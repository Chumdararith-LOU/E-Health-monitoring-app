import type { FieldSummary, PatientSummary } from '@ehealth/types';

export interface ReadingInput {
  measuredAt: string;
  values: Record<string, number>;
}

export interface NormalRange {
  min?: number;
  max?: number;
}

export interface DateWindowOptions {
  days?: number;
  from?: string; // YYYY-MM-DD
  to?: string; // YYYY-MM-DD
  now?: Date;
  timeZone?: string;
}

export interface SummaryInput extends DateWindowOptions {
  patientId: string;
  readings: ReadingInput[];
  ranges?: Record<string, NormalRange>; // e.g. { systolic: { min: 90, max: 129 } }
}

const DAY_MS = 24 * 60 * 60 * 1000;

export function dayKey(date: Date, timeZone: string): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(date);
}

/**
 * Builds the inclusive list of YYYY-MM-DD calendar days for either an explicit
 * `[from, to]` range or the last `days` calendar days ending on `now`.
 */
export function buildWindowDays({
  days = 7,
  from,
  to,
  now = new Date(),
  timeZone = 'Asia/Phnom_Penh',
}: DateWindowOptions): string[] {
  if (from && to) {
    const startMs = Date.parse(`${from}T00:00:00Z`);
    const endMs = Date.parse(`${to}T00:00:00Z`);
    const out: string[] = [];
    for (let ms = startMs; ms <= endMs; ms += DAY_MS) {
      out.push(new Date(ms).toISOString().slice(0, 10));
    }
    return out;
  }

  const out: string[] = [];
  for (let i = days - 1; i >= 0; i--) {
    out.push(dayKey(new Date(now.getTime() - i * DAY_MS), timeZone));
  }
  return out;
}

const round1 = (n: number) => Math.round(n * 10) / 10;

type Stats = { min: number; max: number; sum: number; count: number; latest: FieldSummary['latest'] };

export function computeSummary({
  patientId,
  days = 7,
  from,
  to,
  readings,
  ranges = {},
  now = new Date(),
  timeZone = 'Asia/Phnom_Penh',
}: SummaryInput): PatientSummary {
  const windowDays = buildWindowDays({ days, from, to, now, timeZone });
  const inWindow = new Set(windowDays);

  const kept = readings
    .filter((r) => inWindow.has(dayKey(new Date(r.measuredAt), timeZone)))
    .sort((a, b) => Date.parse(a.measuredAt) - Date.parse(b.measuredAt));

  const stats = new Map<string, Stats>();
  const daysWithReading = new Set<string>();
  let outOfRangeCount = 0;

  for (const reading of kept) {
    daysWithReading.add(dayKey(new Date(reading.measuredAt), timeZone));
    let outOfRange = false;

    for (const [fieldKey, value] of Object.entries(reading.values)) {
      const s = stats.get(fieldKey) ?? { min: value, max: value, sum: 0, count: 0, latest: undefined };
      s.min = Math.min(s.min, value);
      s.max = Math.max(s.max, value);
      s.sum += value;
      s.count += 1;
      s.latest = { value, measuredAt: reading.measuredAt };
      stats.set(fieldKey, s);

      const range = ranges[fieldKey];
      const tooLow = range?.min !== undefined && value < range.min;
      const tooHigh = range?.max !== undefined && value > range.max;
      if (tooLow || tooHigh) outOfRange = true;
    }

    if (outOfRange) outOfRangeCount += 1;
  }

  const fields: FieldSummary[] = [...stats].map(([fieldKey, s]) => ({
    fieldKey,
    min: s.min,
    max: s.max,
    avg: round1(s.sum / s.count),
    count: s.count,
    latest: s.latest,
  }));

  return {
    patientId,
    from: windowDays[0],
    to: windowDays[windowDays.length - 1],
    fields,
    missedDays: windowDays.filter((day) => !daysWithReading.has(day)).length,
    outOfRangeCount,
  };
}
