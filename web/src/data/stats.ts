import { addDays, dayKey, startOfDay } from './dates';
import { isOutOfRange, readingLevel } from './ranges';
import { Reading } from './types';

export type PeriodKind = 7 | 30 | 90 | 'custom' | 'all';

export interface Range {
  from: Date; // start of first day
  to: Date; // end of last day
  days: number;
}

export function lastNDays(n: number, now = new Date()): Range {
  const to = new Date(startOfDay(now).getTime() + 24 * 3600 * 1000 - 1);
  return { from: startOfDay(addDays(now, -(n - 1))), to, days: n };
}

export function customRange(a: Date, b: Date): Range {
  const from = startOfDay(a < b ? a : b);
  const last = startOfDay(a < b ? b : a);
  const to = new Date(last.getTime() + 24 * 3600 * 1000 - 1);
  return { from, to, days: Math.round((last.getTime() - from.getTime()) / 86400000) + 1 };
}

export function inRange(readings: Reading[], r: Range) {
  const a = r.from.getTime();
  const b = r.to.getTime();
  return readings.filter((x) => {
    const t = new Date(x.takenAt).getTime();
    return t >= a && t <= b;
  });
}

export interface Stat {
  min?: number;
  max?: number;
  avg?: number;
  count: number;
}

/** FR-10. Readings without the measure are ignored (not counted as 0). */
export function statOf(readings: Reading[], get: (r: Reading) => number | undefined): Stat {
  const vals = readings.map(get).filter((v): v is number => typeof v === 'number' && !Number.isNaN(v));
  if (!vals.length) return { count: 0 };
  const sum = vals.reduce((a, b) => a + b, 0);
  return { min: Math.min(...vals), max: Math.max(...vals), avg: sum / vals.length, count: vals.length };
}

export function daysWithReadings(readings: Reading[]) {
  return new Set(readings.map((r) => dayKey(r.takenAt))).size;
}

/** Days in the last n days (not counting today) without any reading. */
export function missedDays(readings: Reading[], n = 7, now = new Date()) {
  const keys = new Set(readings.map((r) => dayKey(r.takenAt)));
  let missed = 0;
  for (let i = 1; i <= n; i++) if (!keys.has(dayKey(addDays(now, -i)))) missed++;
  return missed;
}

export interface PatientSummary {
  latest?: Reading;
  avg7: { systolic?: number; diastolic?: number; glucose?: number };
  outOfRange7: number;
  missed7: number;
  latestLevel?: ReturnType<typeof readingLevel>;
  attentionScore: number;
}

/** What GET /patients/{id}/summary will return (FR-12). */
export function summarize(readingsNewestFirst: Reading[], now = new Date()): PatientSummary {
  const week = inRange(readingsNewestFirst, lastNDays(7, now));
  const latest = readingsNewestFirst[0];
  const outOfRange7 = week.filter(isOutOfRange).length;
  const missed7 = missedDays(readingsNewestFirst, 7, now);
  const latestLevel = latest ? readingLevel(latest) : undefined;
  // Needs attention: latest reading out of range, 3+ out-of-range readings this week, or 2+ missed days
  const flagged = (latestLevel && latestLevel !== 'normal') || outOfRange7 >= 3 || missed7 >= 2;
  const attentionScore = flagged ? (latestLevel && latestLevel !== 'normal' ? 100 : 0) + outOfRange7 * 10 + missed7 * 8 + 1 : 0;
  return {
    latest,
    avg7: {
      systolic: statOf(week, (r) => r.systolic).avg,
      diastolic: statOf(week, (r) => r.diastolic).avg,
      glucose: statOf(week, (r) => r.glucose).avg,
    },
    outOfRange7,
    missed7,
    latestLevel,
    attentionScore,
  };
}
