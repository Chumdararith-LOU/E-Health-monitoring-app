// Owner: Phayuk. Draft from the skeleton – owner reviews it by Dec 9.

import type { ISODateTime, Language } from './common';

export const ROLES = ['patient', 'caretaker', 'family', 'doctor', 'admin'] as const;
export type Role = (typeof ROLES)[number];

export interface User {
  id: string;
  name: string;
  role: Role;
  language: Language;
  phone?: string;
  email?: string;
}

export type LinkRelation = 'doctor' | 'caretaker' | 'family';
export type LinkStatus = 'pending' | 'active';

export interface Link {
  id: string;
  patientId: string;
  userId: string;
  relation: LinkRelation;
  status: LinkStatus;
  createdAt: ISODateTime;
}

export interface LoginRequest {
  login: string; // phone or email
  password: string;
}

export interface LoginResponse {
  token: string;
  user: User;
}
