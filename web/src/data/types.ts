export type Role = 'patient' | 'caretaker' | 'family' | 'doctor' | 'admin';
export type Lang = 'km' | 'en';
export type Numerals = 'khmer' | 'western';

export interface User {
  id: string;
  role: Role;
  nameEn: string;
  nameKm: string;
  phone: string;
  /** patients only */
  age?: number;
  conditionsEn?: string;
  conditionsKm?: string;
}

export type LinkRelation = 'doctor' | 'caretaker' | 'family';
export type LinkStatus = 'active' | 'pending';

export interface Link {
  id: string;
  patientId: string;
  userId: string;
  relation: LinkRelation;
  status: LinkStatus;
  /** who started it: 'patient' (invite code / phone) or 'other' (request waiting for patient approval) */
  initiatedBy: 'patient' | 'other';
  createdAt: string;
}

export type MeasureKey = 'systolic' | 'diastolic' | 'pulse' | 'glucose';

export interface Reading {
  id: string;
  patientId: string;
  takenAt: string; // ISO
  systolic?: number;
  diastolic?: number;
  pulse?: number;
  glucose?: number; // always stored in mg/dL
  extra: Record<string, number>; // admin-defined fields, by field id
  enteredBy: string; // user id
  method: 'manual' | 'ocr';
  note?: string;
  photoUri?: string;
  updatedAt?: string;
}

/** Admin-defined field (FR-15). Created on the web admin; the mobile app only reads them. */
export interface CustomField {
  id: string;
  nameEn: string;
  nameKm: string;
  unit: string;
  decimals: number;
  min: number; // safe input limit
  max: number;
  /** archived fields are hidden from forms but their data stays in reports */
  active: boolean;
  createdAt: string;
}

export interface DoctorNote {
  id: string;
  patientId: string;
  authorId: string;
  text: string;
  createdAt: string;
}

export interface Settings {
  lang: Lang;
  numerals: Numerals;
  textScale: 1 | 1.15 | 1.3;
}

export interface DataState {
  version: number;
  users: User[];
  links: Link[];
  readings: Reading[];
  fields: CustomField[];
  notes: DoctorNote[];
}
