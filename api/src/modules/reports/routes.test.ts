import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from '../../app';
import { signToken } from '../../shared/auth';
import { devUsers } from '../../shared/dev/dev-users';

const app = createApp();
const own = devUsers.patient.id;
const other = '00000000-0000-4000-8000-000000000099';
const url = (patientId: string, query = '') => `/api/v1/patients/${patientId}/summary${query}`;
const as = async (role: keyof typeof devUsers) => `Bearer ${await signToken(devUsers[role])}`;

describe('GET /patients/:patientId/summary', () => {
  it('401 without a token', async () => {
    const res = await request(app).get(url(own));
    expect(res.status).toBe(401);
  });

  it('200 for the patient themselves, days defaults to 7', async () => {
    const res = await request(app).get(url(own)).set('Authorization', await as('patient'));
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ patientId: own, fields: [], missedDays: 7 });
  });

  it('403 when a patient asks for another patient', async () => {
    const res = await request(app).get(url(other)).set('Authorization', await as('patient'));
    expect(res.status).toBe(403);
  });

  it('200 for an admin on any patient', async () => {
    const res = await request(app).get(url(other)).set('Authorization', await as('admin'));
    expect(res.status).toBe(200);
  });

  it('400 when days is out of range', async () => {
    const res = await request(app).get(url(own, '?days=0')).set('Authorization', await as('patient'));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_failed');
  });
});