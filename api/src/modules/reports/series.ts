import type { PatientSeries, SeriesPoint } from '@ehealth/types';
import { buildWindowDays, type DateWindowOptions, dayKey, type ReadingInput } from './summary';

export interface SeriesInput extends DateWindowOptions {
  patientId: string;
  fieldKey: string;
  readings: ReadingInput[];
}

export function computeSeries({
  patientId,
  fieldKey,
  days = 7,
  from,
  to,
  readings,
  now = new Date(),
  timeZone = 'Asia/Phnom_Penh',
}: SeriesInput): PatientSeries {
  const windowDays = buildWindowDays({ days, from, to, now, timeZone });
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
