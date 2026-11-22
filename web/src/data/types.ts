// Shared data shapes. When the real API arrives (GET /patients, /patients/{id}/summary,
// /users, /fields …), map the JSON into these types and the pages keep working.

export type Lang = 'km' | 'en';
export type Role = 'patient' | 'caretaker' | 'family' | 'doctor' | 'admin';
export type EntryMethod = 'manual' | 'ocr' | 'ocrEdited';

/** Text in both languages. */
export interface Bi {
  km: string;
  en: string;
}

export interface Reading {
  id: string;
  patientId: string;
  time: Date;
  systolic: number;
  diastolic: number;
  pulse: number;
  /** Always mg/dL. */
  glucose: number;
  /** Admin custom field values by field id (e.g. wt, temp). */
  extra: Record<string, number>;
  note?: Bi;
  author: 'self' | 'caretaker';
  method: EntryMethod;
  photo: boolean;
}

export interface Person {
  name: Bi;
  phone: string;
}

export interface Patient {
  id: string;
  name: Bi;
  sex: 'f' | 'm';
  age: number;
  phone: string;
  linkedSince: Date;
  caretaker?: Person;
  family?: Person;
  devices: Bi;
}

export interface ClinicalNote {
  id: string;
  patientId: string;
  time: Date;
  author: Bi;
  text: Bi;
}

export interface User {
  id: string;
  name: Bi;
  contact: string;
  role: Role;
  active: boolean;
  created: Date;
}

/**
 * One tracked measure. Core vitals and Admin custom fields (US-16) share
 * this schema, so forms, history, reports and charts treat them the same.
 */
export interface VitalField {
  id: string;
  name: Bi;
  unit: string;
  decimal: boolean;
  hardMin: number;
  hardMax: number;
  normalMin: number;
  normalMax: number;
  core: boolean;
  active: boolean;
}

export interface Session {
  userId: string;
  role: 'doctor' | 'admin';
  name: Bi;
  expiresAt: number;
}
