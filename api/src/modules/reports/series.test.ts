import { describe, expect, it } from 'vitest';
import { computeSeries } from './series';

// 2026-11-20 12:00 in Asia/Phnom_Penh (+07:00)
const NOW = new Date('2026-11-20T05:00:00Z');
const PATIENT = '00000000-0000-4000-8000-000000000001';

describe('computeSeries', () => {
  it('returns empty points and correct calendar window when there are no readings', () => {
    const res = computeSeries({
      patientId: PATIENT,
      fieldKey: 'systolic',
      days: 3,
      readings: [],
      now: NOW,
    });
    expect(res).toEqual({
      patientId: PATIENT,
      fieldKey: 'systolic',
      from: '2026-11-18',
      to: '2026-11-20',
      points: [],
    });
  });

  it('extracts only the requested field and sorts points oldest first', () => {
    const res = computeSeries({
      patientId: PATIENT,
      fieldKey: 'systolic',
      days: 7,
      now: NOW,
      readings: [
        { measuredAt: '2026-11-20T01:00:00Z', values: { systolic: 118, glucose: 98 } },
        { measuredAt: '2026-11-18T02:00:00Z', values: { systolic: 128, glucose: 105 } },
        { measuredAt: '2026-11-19T03:00:00Z', values: { glucose: 101 } }, // no systolic -> skipped
      ],
    });

    expect(res.points).toEqual([
      { measuredAt: '2026-11-18T02:00:00Z', value: 128 },
      { measuredAt: '2026-11-20T01:00:00Z', value: 118 },
    ]);
  });

  it('uses Asia/Phnom_Penh calendar days for window filtering', () => {
    const res = computeSeries({
      patientId: PATIENT,
      fieldKey: 'glucose',
      days: 2, // window: 2026-11-19 and 2026-11-20 in +07:00
      now: NOW,
      readings: [
        { measuredAt: '2026-11-18T16:59:00Z', values: { glucose: 90 } }, // Nov 18 23:59 ICT -> outside
        { measuredAt: '2026-11-18T17:01:00Z', values: { glucose: 110 } }, // Nov 19 00:01 ICT -> inside
      ],
    });

    expect(res.from).toBe('2026-11-19');
    expect(res.to).toBe('2026-11-20');
    expect(res.points).toEqual([{ measuredAt: '2026-11-18T17:01:00Z', value: 110 }]);
  });

  it('keeps zero values and ignores Object.prototype keys', () => {
    const zeroRes = computeSeries({
      patientId: PATIENT,
      fieldKey: 'pain',
      days: 7,
      now: NOW,
      readings: [{ measuredAt: '2026-11-20T01:00:00Z', values: { pain: 0 } }],
    });
    expect(zeroRes.points).toEqual([{ measuredAt: '2026-11-20T01:00:00Z', value: 0 }]);

    const protoRes = computeSeries({
      patientId: PATIENT,
      fieldKey: 'toString',
      days: 7,
      now: NOW,
      readings: [{ measuredAt: '2026-11-20T01:00:00Z', values: { systolic: 120 } }],
    });
    expect(protoRes.points).toEqual([]);
  });
});
