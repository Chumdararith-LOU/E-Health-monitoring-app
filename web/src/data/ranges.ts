import { CustomField, MeasureKey, Reading } from './types';

/**
 * FR-06. Safe input limits reject impossible values (typos).
 * Normal ranges only FLAG a value; they never block saving.
 *
 * NOTE: the normal ranges below are DEMO values for adult morning (fasting) readings.
 * Open question in the spec: which reference to cite (WHO / Cambodian MoH) and whether
 * a doctor can adjust per patient. Change them here only; every screen reads from this file.
 */
export interface MeasureDef {
  key: MeasureKey;
  unit: string;
  safeMin: number;
  safeMax: number;
  normalMin: number;
  normalMax: number;
}

export const MEASURES: Record<MeasureKey, MeasureDef> = {
  systolic: { key: 'systolic', unit: 'mmHg', safeMin: 50, safeMax: 260, normalMin: 90, normalMax: 129 },
  diastolic: { key: 'diastolic', unit: 'mmHg', safeMin: 30, safeMax: 160, normalMin: 60, normalMax: 84 },
  pulse: { key: 'pulse', unit: 'bpm', safeMin: 30, safeMax: 220, normalMin: 60, normalMax: 100 },
  glucose: { key: 'glucose', unit: 'mg/dL', safeMin: 20, safeMax: 600, normalMin: 70, normalMax: 130 },
};

export const MEASURE_ORDER: MeasureKey[] = ['systolic', 'diastolic', 'pulse', 'glucose'];

export type Level = 'normal' | 'high' | 'low';

export function levelOf(key: MeasureKey, value: number | undefined): Level | undefined {
  if (value == null) return undefined;
  const m = MEASURES[key];
  if (value > m.normalMax) return 'high';
  if (value < m.normalMin) return 'low';
  return 'normal';
}

/** Worst level across a reading: high > low > normal. */
export function readingLevel(r: Reading): Level {
  let worst: Level = 'normal';
  for (const k of MEASURE_ORDER) {
    const l = levelOf(k, r[k]);
    if (l === 'high') return 'high';
    if (l === 'low') worst = 'low';
  }
  return worst;
}

export function isOutOfRange(r: Reading) {
  return readingLevel(r) !== 'normal';
}

export function safeLimitsFor(key: MeasureKey | string, fields: CustomField[]) {
  if (key in MEASURES) {
    const m = MEASURES[key as MeasureKey];
    return { min: m.safeMin, max: m.safeMax };
  }
  const f = fields.find((x) => x.id === key);
  return f ? { min: f.min, max: f.max } : { min: -Infinity, max: Infinity };
}

export const MMOL_FACTOR = 18.0; // mg/dL = mmol/L × 18
