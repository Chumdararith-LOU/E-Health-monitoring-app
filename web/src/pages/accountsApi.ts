// Accounts API calls for the sign-in and reset-password pages (Owner: Phayuk).
// Kept next to the pages so the shared src/lib/api.ts stays untouched.

import type {
  AuthResponse,
  ForgotPasswordInput,
  LoginInput,
  ResetPasswordInput,
  UserDto,
} from '@ehealth/types';
import type { User } from '../data/types';
import type { I18n } from '../i18n';
import type { StringKey } from '../i18n/en';
import { ApiClientError, apiRequest } from '../lib/api';

export const apiLogin = (input: LoginInput) =>
  apiRequest<AuthResponse>('/auth/login', { method: 'POST', body: input });

export const apiForgotPassword = (input: ForgotPasswordInput) =>
  apiRequest<void>('/auth/password/forgot', { method: 'POST', body: input });

export const apiResetPassword = (input: ResetPasswordInput) =>
  apiRequest<void>('/auth/password/reset', { method: 'POST', body: input });

export function userFromDto(dto: UserDto): User {
  return {
    id: dto.id,
    role: dto.role,
    nameEn: dto.nameEn,
    nameKm: dto.nameKm,
    phone: dto.phone ?? dto.email ?? '',
  };
}

// Error codes of the accounts routes → our own strings. Anything else uses the shared API errors.
const ACCOUNT_ERRORS: Record<string, StringKey> = {
  invalid_credentials: 'acctErrInvalidCredentials',
  invalid_code: 'acctErrInvalidCode',
  too_many_requests: 'acctErrTooMany',
  code_cooldown: 'acctErrCooldown',
  mail_failed: 'acctErrMailFailed',
};

export function accountErrorText(i18n: I18n, err: unknown): string {
  if (err instanceof ApiClientError) {
    const key = ACCOUNT_ERRORS[err.code];
    return key ? i18n.t(key) : i18n.apiError(err.messageKey);
  }
  return i18n.apiError('errors.internal_error');
}

// The API is not running → the pages fall back to the local demo data.
export const isOffline = (err: unknown) => err instanceof ApiClientError && err.status === 0;
