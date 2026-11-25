// Shared typed API client for @ehealth/web (Owner: Rith).
// Teammates can import `apiRequest` and `ApiClientError` to call their own endpoints.

import type {
  ApiError,
  AuthUser,
  CreateFieldInput,
  CreateReadingInput,
  CustomFieldDto,
  PatientSeries,
  PatientSummary,
  ReadingDto,
  UpdateFieldInput,
  UpdateReadingInput,
} from '@ehealth/types';
import type { CustomField, Reading } from '../data/types';

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

// ---------- Readings & Custom Fields CRUD ----------

export function readingToValues(reading: Reading): Record<string, number> {
  const values: Record<string, number> = {};
  if (reading.systolic != null) values.systolic = reading.systolic;
  if (reading.diastolic != null) values.diastolic = reading.diastolic;
  if (reading.pulse != null) values.pulse = reading.pulse;
  if (reading.glucose != null) values.glucose = reading.glucose;
  if (reading.extra) {
    for (const [k, v] of Object.entries(reading.extra)) {
      if (v != null && Number.isFinite(v)) values[k] = v;
    }
  }
  return values;
}

export function readingFromDto(dto: ReadingDto): Reading {
  const extra: Record<string, number> = {};
  for (const [k, v] of Object.entries(dto.values)) {
    if (k !== 'systolic' && k !== 'diastolic' && k !== 'pulse' && k !== 'glucose') {
      extra[k] = v;
    }
  }
  return {
    id: dto.id,
    patientId: dto.patientId,
    takenAt: dto.measuredAt,
    systolic: dto.values.systolic,
    diastolic: dto.values.diastolic,
    pulse: dto.values.pulse,
    glucose: dto.values.glucose,
    extra,
    enteredBy: dto.enteredBy,
    method: dto.method,
    note: dto.note ?? undefined,
    updatedAt: dto.updatedAt ?? undefined,
  };
}

export function customFieldFromDto(dto: CustomFieldDto): CustomField {
  return {
    id: dto.id,
    nameEn: dto.nameEn,
    nameKm: dto.nameKm,
    unit: dto.unit,
    decimals: dto.decimals,
    min: dto.minValue,
    max: dto.maxValue,
    active: dto.active,
    createdAt: new Date().toISOString(),
  };
}

export function apiListPatientReadings(
  patientId: string,
  token: string,
  options: { from?: string; to?: string; limit?: number; signal?: AbortSignal } = {},
): Promise<{ readings: ReadingDto[] }> {
  const query = new URLSearchParams();
  if (options.from) query.set('from', options.from);
  if (options.to) query.set('to', options.to);
  if (options.limit != null) query.set('limit', String(options.limit));
  const qs = query.toString();
  return apiRequest<{ readings: ReadingDto[] }>(
    `/patients/${encodeURIComponent(patientId)}/readings${qs ? `?${qs}` : ''}`,
    { token, signal: options.signal },
  );
}

export function apiCreateReading(
  patientId: string,
  input: CreateReadingInput,
  token: string,
): Promise<ReadingDto> {
  return apiRequest<ReadingDto>(`/patients/${encodeURIComponent(patientId)}/readings`, {
    method: 'POST',
    token,
    body: input,
  });
}

export function apiUpdateReading(
  patientId: string,
  readingId: string,
  input: UpdateReadingInput,
  token: string,
): Promise<ReadingDto> {
  return apiRequest<ReadingDto>(
    `/patients/${encodeURIComponent(patientId)}/readings/${encodeURIComponent(readingId)}`,
    { method: 'PUT', token, body: input },
  );
}

export function apiDeleteReading(
  patientId: string,
  readingId: string,
  token: string,
): Promise<void> {
  return apiRequest<void>(
    `/patients/${encodeURIComponent(patientId)}/readings/${encodeURIComponent(readingId)}`,
    { method: 'DELETE', token },
  );
}

export function apiListFields(
  token: string,
  includeArchived = false,
  signal?: AbortSignal,
): Promise<{ fields: CustomFieldDto[] }> {
  const qs = includeArchived ? '?includeArchived=true' : '';
  return apiRequest<{ fields: CustomFieldDto[] }>(`/fields${qs}`, { token, signal });
}

export function apiCreateField(input: CreateFieldInput, token: string): Promise<CustomFieldDto> {
  return apiRequest<CustomFieldDto>('/fields', { method: 'POST', token, body: input });
}

export function apiUpdateField(
  fieldId: string,
  input: UpdateFieldInput,
  token: string,
): Promise<CustomFieldDto> {
  return apiRequest<CustomFieldDto>(`/fields/${encodeURIComponent(fieldId)}`, {
    method: 'PUT',
    token,
    body: input,
  });
}
