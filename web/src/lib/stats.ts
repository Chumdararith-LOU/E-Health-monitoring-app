// Report maths (FR-10, FR-12). Rith: replace with GET /patients/{id}/summary
// later; keep the same output shapes so the pages don't change.

import { dayStart, daysAgo } from '../data/mock';
import type { Patient, Reading, VitalField } from '../data/types';

export type RangeStatus = 'normal' | 'high' | 'low';

export function valueOf(r: Reading, fieldId: string): number | undefined {
  switch (fieldId) {
    case 'sys':
      return r.systolic;
    case 'dia':
      return r.diastolic;
    case 'pul':
      return r.pulse;
    case 'glu':
      return r.glucose;
    default:
      return r.extra[fieldId];
  }
}

export function statusOf(f: VitalField, v: number): RangeStatus {
  if (v > f.normalMax) return 'high';
  if (v < f.normalMin) return 'low';
  return 'normal';
}

export function fmtValue(f: VitalField, v: number): string {
  return f.decimal ? v.toFixed(1) : String(Math.round(v));
}

export const byField = (fields: VitalField[], id: string) => fields.find((f) => f.id === id)!;

/** Out of range on any core vital. */
export function readingFlags(fields: VitalField[], r: Reading) {
  const s = statusOf(byField(fields, 'sys'), r.systolic);
  const d = statusOf(byField(fields, 'dia'), r.diastolic);
  const g = statusOf(byField(fields, 'glu'), r.glucose);
  const p = statusOf(byField(fields, 'pul'), r.pulse);
  const bp: RangeStatus = s === 'high' || d === 'high' ? 'high' : s === 'low' || d === 'low' ? 'low' : 'normal';
  return { bp, sys: s, dia: d, glu: g, pul: p, any: bp !== 'normal' || g !== 'normal' || p !== 'normal' };
}

export function readingsOf(all: Reading[], patientId: string): Reading[] {
  return all.filter((r) => r.patientId === patientId).sort((a, b) => b.time.getTime() - a.time.getTime());
}

export function inRange(rs: Reading[], start: Date, end: Date): Reading[] {
  const s = dayStart(start).getTime();
  const e = dayStart(end).getTime() + 24 * 3600 * 1000;
  return rs.filter((r) => r.time.getTime() >= s && r.time.getTime() < e);
}

export interface Stat {
  min: number;
  avg: number;
  max: number;
  count: number;
  flagged: number;
}

export function statFor(rs: Reading[], f: VitalField): Stat | null {
  const vals = rs.map((r) => valueOf(r, f.id)).filter((v): v is number => v !== undefined);
  if (!vals.length) return null;
  let flagged = 0;
  for (const v of vals) if (statusOf(f, v) !== 'normal') flagged++;
  return {
    min: Math.min(...vals),
    max: Math.max(...vals),
    avg: vals.reduce((a, b) => a + b, 0) / vals.length,
    count: vals.length,
    flagged,
  };
}

export const sameDay = (a: Date, b: Date) => dayStart(a).getTime() === dayStart(b).getTime();
export const dayDiff = (a: Date, b: Date) => Math.round((dayStart(a).getTime() - dayStart(b).getTime()) / (24 * 3600 * 1000));

export interface TriageRow {
  patient: Patient;
  latest?: Reading;
  bp: RangeStatus;
  glu: RangeStatus;
  flagged: boolean;
  /** Days without a reading up to today (0 = recorded today). */
  missed: number;
  avgSys?: number;
  avgDia?: number;
  avgGlu?: number;
  priority: number;
}

/** One row per linked patient for the doctor dashboard (US-12). */
export function triage(patients: Patient[], readings: Reading[], fields: VitalField[], today = new Date()): TriageRow[] {
  return patients.map((p) => {
    const rs = readingsOf(readings, p.id);
    const latest = rs[0];
    const flags = latest ? readingFlags(fields, latest) : undefined;
    const missed = latest ? Math.max(0, dayDiff(today, latest.time)) : 99;
    const week = inRange(rs, daysAgo(6, today), today);
    const avg = (pick: (r: Reading) => number) => (week.length ? week.reduce((a, r) => a + pick(r), 0) / week.length : undefined);
    const flagged = !!flags && (flags.bp !== 'normal' || flags.glu !== 'normal');
    return {
      patient: p,
      latest,
      bp: flags?.bp ?? 'normal',
      glu: flags?.glu ?? 'normal',
      flagged,
      missed,
      avgSys: avg((r) => r.systolic),
      avgDia: avg((r) => r.diastolic),
      avgGlu: avg((r) => r.glucose),
      priority: flagged ? 0 : missed > 0 ? 1 : 2,
    };
  });
}
