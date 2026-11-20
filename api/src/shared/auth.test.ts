import express, { Router } from 'express';
import request from 'supertest';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { createApp, errorHandler } from '../app';
import { config } from '../config';
import { registerAccessChecker, requirePatientAccess } from './access';
import { requireAuth, requireRole, signToken } from './auth';
import { devUsers } from './dev/dev-users';

// DEV_LOGIN is off under NODE_ENV=test, and createApp reads it once, so flip it per app.
config.DEV_LOGIN = true;
const app = createApp();
config.DEV_LOGIN = false;
const appWithoutDev = createApp();

const testRouter = Router();
testRouter.get('/admin-only', requireAuth, requireRole('admin'), (_req, res) => {
  res.json({ ok: true });
});
testRouter.get('/patients/:patientId', requireAuth, requirePatientAccess(), (_req, res) => {
  res.json({ ok: true });
});
const testApp = express().use(testRouter).use(errorHandler);

const bearer = async (user: (typeof devUsers)[keyof typeof devUsers]) =>
  `Bearer ${await signToken(user)}`;
const otherPatientId = '00000000-0000-4000-8000-000000000099';
const unauthorizedBody = { error: { code: 'unauthorized', messageKey: 'errors.unauthorized' } };
const forbiddenBody = { error: { code: 'forbidden', messageKey: 'errors.forbidden' } };

afterEach(() => {
  vi.useRealTimers();
});

describe('requireAuth', () => {
  it('no token → 401', async () => {
    const res = await request(app).get('/api/v1/dev/whoami');
    expect(res.status).toBe(401);
    expect(res.body).toEqual(unauthorizedBody);
  });

  it('garbage token → 401', async () => {
    const res = await request(app).get('/api/v1/dev/whoami').set('Authorization', 'Bearer nope');
    expect(res.status).toBe(401);
    expect(res.body).toEqual(unauthorizedBody);
  });

  it('expired token → 401', async () => {
    const auth = await bearer(devUsers.doctor);
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(Date.now() + 8 * 24 * 60 * 60 * 1000);
    const res = await request(app).get('/api/v1/dev/whoami').set('Authorization', auth);
    expect(res.status).toBe(401);
    expect(res.body).toEqual(unauthorizedBody);
  });
});

describe('dev login', () => {
  it('login as doctor gives a token that works on /dev/whoami', async () => {
    const login = await request(app).post('/api/v1/dev/login').send({ role: 'doctor' });
    expect(login.status).toBe(200);
    expect(login.body.user).toEqual(devUsers.doctor);
    const res = await request(app)
      .get('/api/v1/dev/whoami')
      .set('Authorization', `Bearer ${login.body.token}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual(devUsers.doctor);
    expect(res.body.role).toBe('doctor');
  });

  it('login by userId works, bad body → 400, unknown userId → 404', async () => {
    const byId = await request(app).post('/api/v1/dev/login').send({ userId: devUsers.admin.id });
    expect(byId.body.user).toEqual(devUsers.admin);
    expect((await request(app).post('/api/v1/dev/login').send({ role: 'x' })).status).toBe(400);
    expect(
      (await request(app).post('/api/v1/dev/login').send({ userId: otherPatientId })).status,
    ).toBe(404);
  });

  it('GET /dev/users lists the 5 users', async () => {
    const res = await request(app).get('/api/v1/dev/users');
    expect(res.body).toEqual(Object.values(devUsers));
  });

  it('with DEV_LOGIN false, /api/v1/dev/login returns 404', async () => {
    const res = await request(appWithoutDev).post('/api/v1/dev/login').send({ role: 'doctor' });
    expect(res.status).toBe(404);
  });

  it('responses have no X-Powered-By header', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.headers['x-powered-by']).toBeUndefined();
  });
});

describe('requireRole', () => {
  it('403 for a patient, 200 for an admin', async () => {
    const patient = await request(testApp)
      .get('/admin-only')
      .set('Authorization', await bearer(devUsers.patient));
    expect(patient.status).toBe(403);
    expect(patient.body).toEqual(forbiddenBody);
    const admin = await request(testApp)
      .get('/admin-only')
      .set('Authorization', await bearer(devUsers.admin));
    expect(admin.status).toBe(200);
  });
});

describe('requirePatientAccess', () => {
  const get = async (patientId: string, user: (typeof devUsers)[keyof typeof devUsers]) =>
    request(testApp)
      .get(`/patients/${patientId}`)
      .set('Authorization', await bearer(user));

  it('patient sees self, 403 for another patient', async () => {
    expect((await get(devUsers.patient.id, devUsers.patient)).status).toBe(200);
    const other = await get(otherPatientId, devUsers.patient);
    expect(other.status).toBe(403);
    expect(other.body).toEqual(forbiddenBody);
  });

  it('admin sees anyone', async () => {
    expect((await get(otherPatientId, devUsers.admin)).status).toBe(200);
  });

  // Keep last: the registered checker stays for the rest of this file.
  it('registerAccessChecker replaces the placeholder rule', async () => {
    registerAccessChecker(async (user) => user.role === 'doctor');
    expect((await get(devUsers.patient.id, devUsers.patient)).status).toBe(403);
    expect((await get(otherPatientId, devUsers.doctor)).status).toBe(200);
    expect((await get(otherPatientId, devUsers.admin)).status).toBe(403);
  });
});
