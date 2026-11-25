// Shared typed API client for @ehealth/web (Owner: Rith).
// Teammates can import `apiRequest` and `ApiClientError` to call their own endpoints.

import type { ApiError, AuthUser, PatientSeries, PatientSummary } from '@ehealth/types';

const rawBase = (import.meta.env.VITE_API_URL as string | undefined) ?? 'http://localhost:3000/api/v1';
export const API_BASE = rawBase.replace(/\/+$/, '');

export class ApiClientError extends Error {
  status: number;
  code: string;
  messageKey: string;

  constructor(status: number, code: string, messageKey: string) {
    super(messageKey);
    this.name = 'ApiClientError';
    this.status = status;
    this.code = code;
    this.messageKey = messageKey;
  }
}

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  token?: string;
  body?: unknown;
  signal?: AbortSignal;
}

export async function apiRequest<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', token, body, signal } = options;
  const headers: Record<string, string> = { Accept: 'application/json' };

  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  let res: Response;
  try {
    res = await fetch(`${API_BASE}${path}`, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal,
    });
  } catch (err) {
    // Let React cleanup cancellations pass through instead of treating them as offline errors.
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw err;
    }
    throw new ApiClientError(0, 'network_error', 'errors.network');
  }

  if (!res.ok) {
    let parsed: Partial<ApiError> | null = null;
    try {
      parsed = (await res.json()) as Partial<ApiError>;
    } catch {
      parsed = null;
    }
    const code = parsed?.error?.code ?? 'http_error';
    const messageKey = parsed?.error?.messageKey ?? 'errors.internal_error';
    throw new ApiClientError(res.status, code, messageKey);
  }

  if (res.status === 204) {
    return undefined as T;
  }
  return (await res.json()) as T;
}

export interface DevLoginResponse {
  token: string;
  user: AuthUser;
}

export function apiDevLogin(role: 'doctor' | 'admin'): Promise<DevLoginResponse> {
  return apiRequest<DevLoginResponse>('/dev/login', {
    method: 'POST',
    body: { role },
  });
}

export interface DateRangeQuery {
  from?: string;
  to?: string;
}

export function apiGetPatientSummary(
  patientId: string,
  days: number,
  token: string,
  signal?: AbortSignal,
  range?: DateRangeQuery,
): Promise<PatientSummary> {
  const query = new URLSearchParams(
    range?.from && range?.to ? { from: range.from, to: range.to } : { days: String(days) },
  );
  return apiRequest<PatientSummary>(`/patients/${encodeURIComponent(patientId)}/summary?${query}`, {
    token,
    signal,
  });
}

export function apiGetPatientSeries(
  patientId: string,
  field: string,
  days: number,
  token: string,
  signal?: AbortSignal,
  range?: DateRangeQuery,
): Promise<PatientSeries> {
  const query = new URLSearchParams(
    range?.from && range?.to
      ? { field, from: range.from, to: range.to }
      : { field, days: String(days) },
  );
  return apiRequest<PatientSeries>(`/patients/${encodeURIComponent(patientId)}/series?${query}`, {
    token,
    signal,
  });
}
