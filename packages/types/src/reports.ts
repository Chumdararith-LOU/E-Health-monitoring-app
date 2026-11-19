// Owner: Rith. Draft from the skeleton – owner reviews it by Dec 9.

import type { ISODateTime } from './common';

export interface FieldSummary {
  fieldKey: string;
  min: number;
  max: number;
  avg: number;
  count: number;
  latest?: {
    value: number;
    measuredAt: ISODateTime;
  };
}

export interface PatientSummary {
  patientId: string;
  from: ISODateTime;
  to: ISODateTime;
  fields: FieldSummary[];
  missedDays: number;
  outOfRangeCount: number;
}

export interface SeriesPoint {
  measuredAt: ISODateTime;
  value: number;
}
