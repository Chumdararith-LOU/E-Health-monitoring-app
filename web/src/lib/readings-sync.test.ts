import type { CustomFieldDto, ReadingDto } from '@ehealth/types';
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
  apiCreateField,
  apiCreateReading,
  apiDeleteReading,
  apiUpdateField,
  apiUpdateReading,
  customFieldFromDto,
  readingFromDto,
  readingToValues,
} from './api';

describe('web readings & fields API client', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('converts Reading <-> ReadingDto round-trip including custom fields', () => {
    const dto: ReadingDto = {
      id: 'r-1',
      patientId: 'p1',
      enteredBy: 'p1',
      measuredAt: '2026-11-25T00:15:00.000Z',
      method: 'ocr',
      note: 'Morning',
      photoUri: null,
      values: { systolic: 124, diastolic: 78, pulse: 72, glucose: 102, weight: 68.4 },
      createdAt: '2026-11-25T00:15:00.000Z',
      updatedAt: null,
    };

    const reading = readingFromDto(dto);
    expect(reading.systolic).toBe(124);
    expect(reading.extra).toEqual({ weight: 68.4 });
    expect(readingToValues(reading)).toEqual(dto.values);
  });

  it('maps CustomFieldDto into web CustomField', () => {
    const dto: CustomFieldDto = {
      id: 'temperature',
      nameEn: 'Temperature',
      nameKm: 'សីតុណ្ហភាព',
      unit: '°C',
      decimals: 1,
      minValue: 34,
      maxValue: 43,
      normalMin: 36.1,
      normalMax: 37.5,
      builtIn: false,
      active: true,
      usedCount: 0,
    };

    const field = customFieldFromDto(dto);
    expect(field).toMatchObject({ id: 'temperature', unit: '°C', min: 34, max: 43, active: true });
  });

  it('sends POST, PUT, DELETE requests for readings and fields with Bearer auth', async () => {
    const calls: { method: string; url: string; auth: string | null }[] = [];
    vi.stubGlobal(
      'fetch',
      vi.fn(async (input: string | URL, init?: RequestInit) => {
        const headers = new Headers(init?.headers);
        calls.push({ method: init?.method ?? 'GET', url: String(input), auth: headers.get('Authorization') });
        if (init?.method === 'DELETE') return new Response(null, { status: 204 });
        return new Response(JSON.stringify({ id: 'ok' }), { status: 200 });
      }),
    );

    await apiCreateReading('p1', { values: { glucose: 100 } }, 'jwt');
    await apiUpdateReading('p1', 'r-1', { note: 'fixed' }, 'jwt');
    await apiDeleteReading('p1', 'r-1', 'jwt');
    await apiCreateField({ nameEn: 'Temp', nameKm: 'សីតុណ្ហភាព', unit: '°C', minValue: 34, maxValue: 43 }, 'jwt');
    await apiUpdateField('temp', { active: false }, 'jwt');

    expect(calls.map((c) => `${c.method} ${new URL(c.url).pathname}`)).toEqual([
      'POST /api/v1/patients/p1/readings',
      'PUT /api/v1/patients/p1/readings/r-1',
      'DELETE /api/v1/patients/p1/readings/r-1',
      'POST /api/v1/fields',
      'PUT /api/v1/fields/temp',
    ]);
    expect(calls.every((c) => c.auth === 'Bearer jwt')).toBe(true);
  });
});
