// Shared types for readings and admin-defined custom fields (US-04 to US-06, US-16).

import type { ISODateTime } from './common';

export type EntryMethod = 'manual' | 'ocr';

export interface ReadingDto {
  id: string;
  patientId: string;
  enteredBy: string;
  measuredAt: ISODateTime;
  method: EntryMethod;
  note: string | null;
  photoUri: string | null;
  values: Record<string, number>;
  createdAt: ISODateTime;
  updatedAt: ISODateTime | null;
}

export interface CreateReadingInput {
  measuredAt?: ISODateTime;
  method?: EntryMethod;
  note?: string | null;
  photoUri?: string | null;
  values: Record<string, number>;
}

export interface UpdateReadingInput {
  measuredAt?: ISODateTime;
  note?: string | null;
  values?: Record<string, number>;
}

export interface CustomFieldDto {
  id: string;
  nameEn: string;
  nameKm: string;
  unit: string;
  decimals: number;
  minValue: number;
  maxValue: number;
  normalMin: number | null;
  normalMax: number | null;
  builtIn: boolean;
  active: boolean;
  usedCount: number;
}

export interface CreateFieldInput {
  id?: string;
  nameEn: string;
  nameKm: string;
  unit: string;
  decimals?: number;
  minValue: number;
  maxValue: number;
  normalMin?: number | null;
  normalMax?: number | null;
}

export interface UpdateFieldInput {
  nameEn?: string;
  nameKm?: string;
  unit?: string;
  decimals?: number;
  minValue?: number;
  maxValue?: number;
  normalMin?: number | null;
  normalMax?: number | null;
  active?: boolean;
}
