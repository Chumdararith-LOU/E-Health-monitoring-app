import { describe, expect, it } from 'vitest';
import { computeSummary, dayKey } from './summary';

const now = new Date('2026-11-20T02:00:00Z');

const ranges = {
  systolic: { min: 90, max: 120 },
  diastolic: { min: 60, max: 80 },
  glucose: { min: 70, max: 99 },
};

const readings = [
  { measuredAt: '2026-11-17T23:30:00Z', values: { systolic: 128, diastolic: 84, glucose: 105 } },
  { measuredAt: '2026-11-19T00:05:00Z', values: { systolic: 118, diastolic: 78, glucose: 98 } },
  { measuredAt: '2026-11-16T23:00:00Z', values: { systolic: 200, diastolic: 120, glucose: 300 } },
];

describe('dayKey', () => {
  it('uses the Phnom Penh date, not the UTC date', () => {
    expect(dayKey(new Date('2026-11-17T23:30:00Z'), 'Asia/Phnom_Penh')).toBe('2026-11-18');
  });
});

describe('computeSummary', () => {
  const summary = computeSummary({ patientId: 'p1', days: 3, readings, ranges, now });

  it('covers the last 3 days', () => {
    expect(summary.from).toBe('2026-11-18');
    expect(summary.to).toBe('2026-11-20');
  });

  it('computes min, max, average and count per field', () => {
    const systolic = summary.fields.find((f) => f.fieldKey === 'systolic');
    expect(systolic).toMatchObject({ min: 118, max: 128, avg: 123, count: 2 });
    const glucose = summary.fields.find((f) => f.fieldKey === 'glucose');
    expect(glucose).toMatchObject({ min: 98, max: 105, avg: 101.5, count: 2 });
  });

  it('keeps the latest value', () => {
    const systolic = summary.fields.find((f) => f.fieldKey === 'systolic');
    expect(systolic?.latest).toEqual({ value: 118, measuredAt: '2026-11-19T00:05:00Z' });
  });

  it('counts missed days and out-of-range readings', () => {
    expect(summary.missedDays).toBe(1); 
    expect(summary.outOfRangeCount).toBe(1); 
  });

  it('handles no readings at all', () => {
    const empty = computeSummary({ patientId: 'p1', days: 7, readings: [], now });
    expect(empty).toMatchObject({ fields: [], missedDays: 7, outOfRangeCount: 0 });
  });
});