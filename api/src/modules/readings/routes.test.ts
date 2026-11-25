import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { createApp } from '../../app';
import { runSeeds, runStartups } from '../index';
import { signToken } from '../../shared/auth';
import { createDb, type Db, runMigrations } from '../../shared/db';
import { devUsers } from '../../shared/dev/dev-users';

let db: Db;
let app: ReturnType<typeof createApp>;

const patientId = devUsers.patient.id;
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

describe('Readings CRUD API', () => {
  it('lists readings newest first and filters by from/to dates', async () => {
    const res = await request(app)
      .get(`/api/v1/patients/${patientId}/readings?limit=5`)
      .set('Authorization', await as('patient'));
    expect(res.status).toBe(200);
    expect(res.body.readings.length).toBe(5);
    expect(res.body.readings[0].measuredAt >= res.body.readings[1].measuredAt).toBe(true);

    const bad = await request(app)
      .get(`/api/v1/patients/${patientId}/readings?from=2026-11-25&to=2026-11-01`)
      .set('Authorization', await as('patient'));
    expect(bad.status).toBe(400);
  });

  it('creates, updates, reflects in /series, and deletes a reading', async () => {
    const measuredAt = new Date().toISOString();
    const created = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('patient'))
      .send({
        measuredAt,
        method: 'manual',
        note: 'Morning test reading',
        values: { systolic: 122, diastolic: 78, pulse: 70, glucose: 102 },
      });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({
      patientId,
      enteredBy: patientId,
      method: 'manual',
      note: 'Morning test reading',
      values: { systolic: 122, diastolic: 78, pulse: 70, glucose: 102 },
    });

    const readingId = created.body.id as string;

    // Immediately visible in live reports /series!
    const seriesRes = await request(app)
      .get(`/api/v1/patients/${patientId}/series?field=systolic&days=1`)
      .set('Authorization', await as('doctor'));
    expect(seriesRes.status).toBe(200);
    expect(
      (seriesRes.body.points as Array<{ measuredAt: string; value: number }>).some(
        (p) => p.measuredAt === measuredAt && p.value === 122,
      ),
    ).toBe(true);

    // Update reading values and note
    const updated = await request(app)
      .put(`/api/v1/patients/${patientId}/readings/${readingId}`)
      .set('Authorization', await as('patient'))
      .send({
        note: 'Updated note',
        values: { systolic: 130, diastolic: 82, glucose: 105 },
      });
    expect(updated.status).toBe(200);
    expect(updated.body.note).toBe('Updated note');
    expect(updated.body.values).toEqual({ systolic: 130, diastolic: 82, glucose: 105 });
    expect(updated.body.updatedAt).toBeTruthy();

    // Delete reading
    const del = await request(app)
      .delete(`/api/v1/patients/${patientId}/readings/${readingId}`)
      .set('Authorization', await as('patient'));
    expect(del.status).toBe(204);

    // Deleting again returns 404
    const delAgain = await request(app)
      .delete(`/api/v1/patients/${patientId}/readings/${readingId}`)
      .set('Authorization', await as('patient'));
    expect(delAgain.status).toBe(404);
  });

  it('rejects out-of-range values, invalid BP pairs, and systolic <= diastolic', async () => {
    const auth = await as('patient');

    const tooHigh = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', auth)
      .send({ values: { systolic: 300, diastolic: 80 } });
    expect(tooHigh.status).toBe(400);

    const halfBp = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', auth)
      .send({ values: { systolic: 120 } });
    expect(halfBp.status).toBe(400);

    const invertedBp = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', auth)
      .send({ values: { systolic: 80, diastolic: 90 } });
    expect(invertedBp.status).toBe(400);
  });

  it('enforces role write permissions (doctor/family read-only, caretaker edits only own entries)', async () => {
    const docPost = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('doctor'))
      .send({ values: { glucose: 100 } });
    expect(docPost.status).toBe(403);

    const famPost = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('family'))
      .send({ values: { glucose: 100 } });
    expect(famPost.status).toBe(403);

    // Patient creates a reading; caretaker cannot edit/delete it
    const patCreated = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('patient'))
      .send({ values: { glucose: 99 } });
    expect(patCreated.status).toBe(201);

    const caretakerEditOther = await request(app)
      .put(`/api/v1/patients/${patientId}/readings/${patCreated.body.id}`)
      .set('Authorization', await as('caretaker'))
      .send({ note: 'Should be blocked' });
    expect(caretakerEditOther.status).toBe(403);

    // Caretaker creates and edits their own entry
    const caretakerCreated = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('caretaker'))
      .send({ values: { glucose: 108 } });
    expect(caretakerCreated.status).toBe(201);

    const caretakerEditOwn = await request(app)
      .put(`/api/v1/patients/${patientId}/readings/${caretakerCreated.body.id}`)
      .set('Authorization', await as('caretaker'))
      .send({ note: 'Recorded by caretaker' });
    expect(caretakerEditOwn.status).toBe(200);
  });
});

describe('Custom Fields CRUD API (US-16)', () => {
  it('lists active fields with usage counts for any authenticated user', async () => {
    const res = await request(app).get('/api/v1/fields').set('Authorization', await as('patient'));
    expect(res.status).toBe(200);
    const ids = (res.body.fields as Array<{ id: string }>).map((f) => f.id);
    expect(ids).toEqual(expect.arrayContaining(['systolic', 'diastolic', 'pulse', 'glucose', 'weight']));
  });

  it('allows only admin to create, update, and archive fields, and blocks unit change once used', async () => {
    const nonAdmin = await request(app)
      .post('/api/v1/fields')
      .set('Authorization', await as('doctor'))
      .send({ nameEn: 'Temp', nameKm: 'សីតុណ្ហភាព', unit: '°C', minValue: 34, maxValue: 43 });
    expect(nonAdmin.status).toBe(403);

    const created = await request(app)
      .post('/api/v1/fields')
      .set('Authorization', await as('admin'))
      .send({
        id: 'temperature',
        nameEn: 'Temperature',
        nameKm: 'សីតុណ្ហភាព',
        unit: '°C',
        decimals: 1,
        minValue: 34,
        maxValue: 43,
        normalMin: 36.1,
        normalMax: 37.5,
      });
    expect(created.status).toBe(201);
    expect(created.body).toMatchObject({ id: 'temperature', usedCount: 0, active: true });

    // Record a reading using the new custom field
    const used = await request(app)
      .post(`/api/v1/patients/${patientId}/readings`)
      .set('Authorization', await as('patient'))
      .send({ values: { temperature: 36.8 } });
    expect(used.status).toBe(201);

    // Changing unit after use → 409 conflict
    const changeUnit = await request(app)
      .put('/api/v1/fields/temperature')
      .set('Authorization', await as('admin'))
      .send({ unit: '°F' });
    expect(changeUnit.status).toBe(409);

    // Archiving custom field succeeds; archiving built-in field fails
    const archived = await request(app)
      .put('/api/v1/fields/temperature')
      .set('Authorization', await as('admin'))
      .send({ active: false });
    expect(archived.status).toBe(200);
    expect(archived.body.active).toBe(false);

    const archiveBuiltIn = await request(app)
      .put('/api/v1/fields/systolic')
      .set('Authorization', await as('admin'))
      .send({ active: false });
    expect(archiveBuiltIn.status).toBe(400);
  });
});
