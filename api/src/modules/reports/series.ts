import type { PatientSeries, SeriesPoint } from '@ehealth/types';
import { dayKey, type ReadingInput } from './summary';

export interface SeriesInput {
  patientId: string;
  fieldKey: string;
  days: number;
  readings: ReadingInput[];
  now?: Date;
  timeZone?: string;
}

const DAY_MS = 24 * 60 * 60 * 1000;

export function computeSeries({
  patientId,
  fieldKey,
  days,
  readings,
  now = new Date(),
  timeZone = 'Asia/Phnom_Penh',
}: SeriesInput): PatientSeries {
  const windowDays: string[] = [];
  for (let i = days - 1; i >= 0; i--) {
    windowDays.push(dayKey(new Date(now.getTime() - i * DAY_MS), timeZone));
  }
  const inWindow = new Set(windowDays);

  const points: SeriesPoint[] = readings
    .filter(
      (r) =>
        inWindow.has(dayKey(new Date(r.measuredAt), timeZone)) &&
        Object.prototype.hasOwnProperty.call(r.values, fieldKey),
    )
    .sort((a, b) => Date.parse(a.measuredAt) - Date.parse(b.measuredAt))
    .map((r) => ({ measuredAt: r.measuredAt, value: r.values[fieldKey] }));

  return {
    patientId,
    fieldKey,
    from: windowDays[0],
    to: windowDays[windowDays.length - 1],
    points,
  };
}
