// Helpers for fetching and adapting live patient report data from the API (Owner: Rith).

import type { PatientSeries, PatientSummary } from '@ehealth/types';
import type { ChartPoint } from '../ui/Charts';
import { apiGetPatientSeries, apiGetPatientSummary } from './api';

export interface LivePatientReport {
  summary: PatientSummary;
  series: Record<string, PatientSeries>;
}

/**
 * Fetches a patient's summary and all requested field series in parallel.
 * Shares one AbortSignal so changing patient/period cancels every in-flight request together.
 */
export async function fetchPatientReport(
  patientId: string,
  fieldKeys: readonly string[],
  days: number,
  token: string,
  signal?: AbortSignal,
): Promise<LivePatientReport> {
  const uniqueFields = Array.from(new Set(fieldKeys));
  const [summary, ...seriesList] = await Promise.all([
    apiGetPatientSummary(patientId, days, token, signal),
    ...uniqueFields.map((field) => apiGetPatientSeries(patientId, field, days, token, signal)),
  ]);

  const series: Record<string, PatientSeries> = {};
  for (const item of seriesList) {
    series[item.fieldKey] = item;
  }
  return { summary, series };
}

/**
 * Converts API series points (`{ measuredAt, value }`) into LineChart points (`{ t, v, id }`).
 * Uses `measuredAt` as the shared point ID so multi-series charts (e.g. systolic + diastolic)
 * align in both the chart tooltip and the table view.
 */
export function seriesToChartPoints(series: PatientSeries): ChartPoint[] {
  const seen = new Map<string, number>();
  return series.points
    .map((pt) => {
      const t = Date.parse(pt.measuredAt);
      const count = seen.get(pt.measuredAt) ?? 0;
      seen.set(pt.measuredAt, count + 1);
      const id = count === 0 ? pt.measuredAt : `${pt.measuredAt}#${count}`;
      return { t, v: pt.value, id };
    })
    .filter((pt) => !Number.isNaN(pt.t))
    .sort((a, b) => a.t - b.t);
}

/**
 * Picks live API points when available, falling back to local demo points while
 * the readings module returns empty data.
 */
export function pickChartPoints(
  liveSeries: Record<string, PatientSeries> | null,
  fieldKey: string,
  fallback: ChartPoint[],
): ChartPoint[] {
  const live = liveSeries?.[fieldKey];
  if (!live || live.points.length === 0) return fallback;
  return seriesToChartPoints(live);
}

/** True when at least one fetched series contains live readings from the API. */
export function hasLiveSeriesData(liveSeries: Record<string, PatientSeries> | null): boolean {
  if (!liveSeries) return false;
  return Object.values(liveSeries).some((s) => s.points.length > 0);
}
