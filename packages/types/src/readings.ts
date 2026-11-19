// Owner: Seyla. Draft from the skeleton – owner reviews it by Dec 9.

import type { ISODateTime } from './common';

export const BUILTIN_FIELD_KEYS = ['systolic', 'diastolic', 'pulse', 'glucose'] as const;
export type BuiltinFieldKey = (typeof BUILTIN_FIELD_KEYS)[number];

export interface Field {
  id: string;
  key: string;
  nameKm: string;
  nameEn: string;
  unit: string;
  minValue: number;
  maxValue: number;
  normalMin?: number;
  normalMax?: number;
  builtIn: boolean;
  active: boolean;
  sortOrder: number;
}

export type EntryMethod = 'manual' | 'ocr';

export interface Reading {
  id: string;
  patientId: string;
  enteredBy: string;
  measuredAt: ISODateTime;
  method: EntryMethod;
  photoUrl?: string;
  note?: string;
  values: Record<string, number>; // key = Field.key
}

export type NewReading = {
  measuredAt: ISODateTime;
  method: EntryMethod;
  photoUrl?: string;
  note?: string;
  values: Record<string, number>;
};
