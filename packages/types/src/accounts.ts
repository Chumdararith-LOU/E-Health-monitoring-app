// Owner: Phayuk. Shared types for accounts: sign-in, register and the signed-in user.

import type { Role } from './common';

// Roles a person can pick when registering. Admins are never self-registered.
export type RegisterRole = Exclude<Role, 'admin'>;

export interface UserDto {
  id: string;
  role: Role;
  nameEn: string;
  nameKm: string;
  email: string | null;
  phone: string | null;
}

export interface RegisterInput {
  role: RegisterRole;
  nameEn?: string; // at least one of nameEn / nameKm is required
  nameKm?: string;
  email: string;
  phone?: string;
  password: string;
}

export interface LoginInput {
  identifier: string; // email or phone number
  password: string;
}

export interface AuthResponse {
  token: string;
  user: UserDto;
}

export type MeResponse = UserDto;
