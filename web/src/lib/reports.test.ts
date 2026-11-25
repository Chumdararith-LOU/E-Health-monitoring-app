import type { PatientSeries, PatientSummary } from '@ehealth/types';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { fetchPatientReport, hasLiveSeriesData, pickChartPoints, seriesToChartPoints } from './reports';

function makeSeries(fieldKey: string, points: PatientSeries['points']): PatientSeries {
  return {
    patientId: 'p1',
    fieldKey,
    from: '2026-11-01',
    to: '2026-11-25',
    points,
  };
}

describe('web reports helpers', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('converts API series points into sorted ChartPoints with shared measuredAt IDs', () => {
    const series = makeSeries('systolic', [
      { measuredAt: '2026-11-22T06:30:00.000Z', value: 132 },
      { measuredAt: '2026-11-20T06:15:00.000Z', value: 124 },
      { measuredAt: 'not-a-date', value: 999 },
    ]);

    expect(seriesToChartPoints(series)).toEqual([
      { t: Date.parse('2026-11-20T06:15:00.000Z'), v: 124, id: '2026-11-20T06:15:00.000Z' },
      { t: Date.parse('2026-11-22T06:30:00.000Z'), v: 132, id: '2026-11-22T06:30:00.000Z' },
    ]);
  });

  it('aligns systolic and diastolic point IDs when measured at the same timestamp', () => {
    const ts = '2026-11-24T06:45:00.000Z';
    const sys = seriesToChartPoints(makeSeries('systolic', [{ measuredAt: ts, value: 128 }]));
    const dia = seriesToChartPoints(makeSeries('diastolic', [{ measuredAt: ts, value: 82 }]));
    expect(sys[0].id).toBe(dia[0].id);
    expect(sys[0].t).toBe(dia[0].t);
  });

  it('falls back to demo points when live series is null or empty, and prefers live points when present', () => {
    const demo = [{ t: 1000, v: 120, id: 'demo-1' }];
    expect(pickChartPoints(null, 'systolic', demo)).toBe(demo);
    expect(pickChartPoints({ systolic: makeSeries('systolic', []) }, 'systolic', demo)).toBe(demo);

    const live = {
      systolic: makeSeries('systolic', [{ measuredAt: '2026-11-25T06:30:00.000Z', value: 135 }]),
    };
    expect(pickChartPoints(live, 'systolic', demo)).toEqual([
      { t: Date.parse('2026-11-25T06:30:00.000Z'), v: 135, id: '2026-11-25T06:30:00.000Z' },
    ]);
  });

  it('detects whether any live series has points', () => {
    expect(hasLiveSeriesData(null)).toBe(false);
    expect(hasLiveSeriesData({ systolic: makeSeries('systolic', []) })).toBe(false);
    expect(
      hasLiveSeriesData({
        systolic: makeSeries('systolic', []),
        glucose: makeSeries('glucose', [{ measuredAt: '2026-11-25T06:30:00.000Z', value: 105 }]),
      }),
    ).toBe(true);
  });

  it('fetches summary and unique field series in parallel with Bearer token', async () => {
    const summary: PatientSummary = {
      patientId: 'p1',
      from: '2026-11-01',
      to: '2026-11-25',
      fields: [],
      missedDays: 30,
      outOfRangeCount: 0,
    };
    const mockFetch = vi.fn(async (input: string | URL) => {
      const url = String(input);
      if (url.includes('/summary?')) {
        return new Response(JSON.stringify(summary), { status: 200 });
      }
      const field = new URL(url).searchParams.get('field') ?? 'unknown';
      return new Response(
        JSON.stringify(makeSeries(field, [{ measuredAt: '2026-11-25T06:30:00.000Z', value: 110 }])),
        { status: 200 },
      );
    });
    vi.stubGlobal('fetch', mockFetch);

    const result = await fetchPatientReport('p1', ['systolic', 'diastolic', 'systolic'], 30, 'jwt-token');

    expect(mockFetch).toHaveBeenCalledTimes(3); // 1 summary + 2 unique fields
    expect(result.summary.patientId).toBe('p1');
    expect(Object.keys(result.series).sort()).toEqual(['diastolic', 'systolic']);
    expect(result.series.systolic.points[0].value).toBe(110);
  });

  it('sends from/to query params instead of days when a custom range is given', async () => {
    const urls: string[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: string | URL) => {
        const url = String(input);
        urls.push(url);
        if (url.includes('/summary?')) {
          return new Response(
            JSON.stringify({
              patientId: 'p1',
              from: '2026-11-10',
              to: '2026-11-20',
              fields: [],
              missedDays: 11,
              outOfRangeCount: 0,
            }),
            { status: 200 },
          );
        }
        return new Response(JSON.stringify(makeSeries('systolic', [])), { status: 200 });
      }),
    );

    await fetchPatientReport('p1', ['systolic'], 11, 'jwt', undefined, {
      from: '2026-11-10',
      to: '2026-11-20',
    });

    expect(urls[0]).toContain('from=2026-11-10&to=2026-11-20');
    expect(urls[1]).toContain('field=systolic&from=2026-11-10&to=2026-11-20');
  });
});
