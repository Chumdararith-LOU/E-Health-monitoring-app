import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../../app';
import { runSeeds, runStartups } from '../index';
import { signToken } from '../../shared/auth';
import { createDb, type Db, runMigrations } from '../../shared/db';
import { devUsers } from '../../shared/dev/dev-users';

let db: Db;
let app: ReturnType<typeof createApp>;

const own = devUsers.patient.id;
const other = '00000000-0000-4000-8000-000000000099';
const url = (patientId: string, query = '') => `/api/v1/patients/${patientId}/summary${query}`;
const seriesUrl = (patientId: string, query = '') => `/api/v1/patients/${patientId}/series${query}`;
const as = async (role: keyof typeof devUsers) => `Bearer ${await signToken(devUsers[role])}`;

beforeAll(async () => {
  db = createDb(':memory:');
  runMigrations(db);
  await runStartups(db);
  await runSeeds(db);
  app = createApp(() => db);
});

afterAll(() => {
  db.$client.close();
});

describe('GET /patients/:patientId/summary', () => {
  it('401 without a token', async () => {
    const res = await request(app).get(url(own));
    expect(res.status).toBe(401);
  });

  it('200 for the patient themselves with real seeded stats (days defaults to 7)', async () => {
    const res = await request(app).get(url(own)).set('Authorization', await as('patient'));
    expect(res.status).toBe(200);
    expect(res.body.patientId).toBe(own);
    const keys = (res.body.fields as Array<{ fieldKey: string }>).map((f) => f.fieldKey).sort();
    expect(keys).toEqual(expect.arrayContaining(['diastolic', 'glucose', 'pulse', 'systolic']));
    const sys = (res.body.fields as Array<{ fieldKey: string; min: number; avg: number; max: number; count: number }>).find(
      (f) => f.fieldKey === 'systolic',
    )!;
    expect(sys.count).toBeGreaterThan(0);
    expect(sys.min).toBeLessThanOrEqual(sys.avg);
    expect(sys.avg).toBeLessThanOrEqual(sys.max);
  });

  it('200 for a linked doctor, 403 for an unlinked patient', async () => {
    const linked = await request(app).get(url('p1', '?days=30')).set('Authorization', await as('doctor'));
    expect(linked.status).toBe(200);
    expect(linked.body.fields.length).toBeGreaterThan(0);

    const unlinked = await request(app).get(url(other)).set('Authorization', await as('doctor'));
    expect(unlinked.status).toBe(403);
  });

  it('403 when a patient asks for another patient', async () => {
    const res = await request(app).get(url(other)).set('Authorization', await as('patient'));
    expect(res.status).toBe(403);
  });

  it('200 for an admin on any patient (even one with no readings)', async () => {
    const res = await request(app).get(url(other)).set('Authorization', await as('admin'));
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ patientId: other, fields: [], missedDays: 7 });
  });

  it('400 when days is out of range', async () => {
    const res = await request(app).get(url(own, '?days=0')).set('Authorization', await as('patient'));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_failed');
  });

  it('200 for custom from/to date range and 400 when from > to or unpaired', async () => {
    const today = new Date().toISOString().slice(0, 10);
    const weekAgo = new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);

    const custom = await request(app)
      .get(url(own, `?from=${weekAgo}&to=${today}`))
      .set('Authorization', await as('patient'));
    expect(custom.status).toBe(200);
    expect(custom.body.from).toBe(weekAgo);
    expect(custom.body.to).toBe(today);

    const inverted = await request(app)
      .get(url(own, `?from=${today}&to=${weekAgo}`))
      .set('Authorization', await as('patient'));
    expect(inverted.status).toBe(400);

    const unpaired = await request(app)
      .get(url(own, `?from=${weekAgo}`))
      .set('Authorization', await as('patient'));
    expect(unpaired.status).toBe(400);
  });

  it('computes outOfRangeCount using SQLite custom_fields normal ranges', async () => {
    // p4 has high BP (~148/90) seeded in SQLite, exceeding normalMax (129/84).
    const res = await request(app).get(url('p4', '?days=30')).set('Authorization', await as('doctor'));
    expect(res.status).toBe(200);
    expect(res.body.outOfRangeCount).toBeGreaterThan(0);
  });
});

describe('GET /patients/:patientId/series', () => {
  it('401 without a token', async () => {
    const res = await request(app).get(seriesUrl(own, '?field=systolic'));
    expect(res.status).toBe(401);
  });

  it('200 for the patient themselves with real seeded series points', async () => {
    const res = await request(app)
      .get(seriesUrl(own, '?field=systolic&days=30'))
      .set('Authorization', await as('patient'));
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ patientId: own, fieldKey: 'systolic' });
    expect(res.body.from).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(res.body.to).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(res.body.points.length).toBeGreaterThan(10);
  });

  it('403 when a patient asks for another patient', async () => {
    const res = await request(app)
      .get(seriesUrl(other, '?field=systolic'))
      .set('Authorization', await as('patient'));
    expect(res.status).toBe(403);
  });

  it('200 for an admin on any patient', async () => {
    const res = await request(app)
      .get(seriesUrl(other, '?field=glucose&days=30'))
      .set('Authorization', await as('admin'));
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ patientId: other, fieldKey: 'glucose', points: [] });
  });

  it('400 when field is missing', async () => {
    const res = await request(app)
      .get(seriesUrl(own))
      .set('Authorization', await as('patient'));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_failed');
  });

  it('400 when days is out of range', async () => {
    const res = await request(app)
      .get(seriesUrl(own, '?field=systolic&days=0'))
      .set('Authorization', await as('patient'));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('validation_failed');
  });
});
