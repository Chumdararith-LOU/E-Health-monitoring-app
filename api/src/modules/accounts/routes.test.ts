import request from 'supertest';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../../app';
import { verifyToken } from '../../shared/auth';
import { createDb, type Db, runMigrations } from '../../shared/db';
import { runSeeds, runStartups } from '../index';
import { hashPassword, verifyPassword } from './password';
import { resetRateLimits } from './rate-limit';

let db: Db;
let app: ReturnType<typeof createApp>;

beforeAll(async () => {
  db = createDb(':memory:');
  runMigrations(db);
  await runStartups(db);
  await runSeeds(db);
  app = createApp(() => db);
});

beforeEach(() => resetRateLimits());

afterAll(() => {
  db.$client.close();
});

const registerBody = {
  role: 'patient',
  nameEn: 'Test Patient',
  email: 'Test.Patient@Example.com',
  phone: '099 111 222',
  password: 'correct-horse',
};

describe('passwords', () => {
  it('verifies the right password only, with a fresh salt each time', async () => {
    const a = await hashPassword('secret-123');
    const b = await hashPassword('secret-123');
    expect(a).not.toBe(b);
    expect(await verifyPassword('secret-123', a)).toBe(true);
    expect(await verifyPassword('secret-124', a)).toBe(false);
    expect(await verifyPassword('secret-123', 'dev-demo-123456')).toBe(false);
  });
});

describe('POST /auth/register', () => {
  it('creates an account, lowercases the email and returns a working token', async () => {
    const res = await request(app).post('/api/v1/auth/register').send(registerBody);
    expect(res.status).toBe(201);
    expect(res.body.user).toMatchObject({
      role: 'patient',
      nameEn: 'Test Patient',
      nameKm: 'Test Patient',
      email: 'test.patient@example.com',
      phone: '099111222',
    });
    expect(res.body.user).not.toHaveProperty('passwordHash');
    const me = await verifyToken(res.body.token);
    expect(me).toMatchObject({ id: res.body.user.id, role: 'patient' });
  });

  it('rejects a duplicate email and a duplicate phone written with other spacing', async () => {
    const email = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...registerBody, email: 'TEST.patient@example.com', phone: undefined });
    expect(email.status).toBe(409);
    expect(email.body.error).toEqual({ code: 'email_taken', messageKey: 'errors.email_taken' });

    const phone = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...registerBody, email: 'other@example.com', phone: '099-111-222' });
    expect(phone.status).toBe(409);
    expect(phone.body.error.code).toBe('phone_taken');

    // demo users stored with spaces still count
    const demo = await request(app)
      .post('/api/v1/auth/register')
      .send({ ...registerBody, email: 'other@example.com', phone: '023900100' });
    expect(demo.status).toBe(409);
  });

  it('rejects bad input: admin role, short password, bad email, no name, honeypot', async () => {
    const bad = [
      { ...registerBody, email: 'a1@example.com', phone: undefined, role: 'admin' },
      { ...registerBody, email: 'a2@example.com', phone: undefined, password: 'short' },
      { ...registerBody, email: 'not-an-email', phone: undefined },
      { ...registerBody, email: 'a3@example.com', phone: undefined, nameEn: undefined },
      { ...registerBody, email: 'a4@example.com', phone: undefined, website: 'http://spam' },
    ];
    for (const body of bad) {
      const res = await request(app).post('/api/v1/auth/register').send(body);
      expect(res.status).toBe(400);
      expect(res.body.error.messageKey).toBe('errors.validation_failed');
    }
  });

  it('accepts an empty honeypot and a Khmer-only name', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      role: 'family',
      nameKm: 'សុខ វិបុល',
      email: 'khmer@example.com',
      password: 'correct-horse',
      website: '',
    });
    expect(res.status).toBe(201);
    expect(res.body.user).toMatchObject({ nameKm: 'សុខ វិបុល', nameEn: 'សុខ វិបុល' });
  });

  it('limits register to 5 per minute', async () => {
    let last = 0;
    for (let i = 0; i < 6; i++) {
      const res = await request(app).post('/api/v1/auth/register').send({});
      last = res.status;
    }
    expect(last).toBe(429);
  });
});

describe('POST /auth/login', () => {
  it('signs in a demo user by phone with spaces, and by phone without spaces', async () => {
    for (const identifier of ['023 900 100', '023900100']) {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier, password: '123456' });
      expect(res.status).toBe(200);
      expect(res.body.user).toMatchObject({ id: 'd1', role: 'doctor' });
      expect(await verifyToken(res.body.token)).toMatchObject({ id: 'd1', role: 'doctor' });
    }
  });

  it('signs in the admin by email, ignoring case', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'Admin@EHealth.kh', password: '123456' });
    expect(res.status).toBe(200);
    expect(res.body.user.role).toBe('admin');
  });

  it('signs in a freshly registered user with the password they chose', async () => {
    await request(app)
      .post('/api/v1/auth/register')
      .send({ ...registerBody, email: 'fresh@example.com', phone: undefined });
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'fresh@example.com', password: 'correct-horse' });
    expect(res.status).toBe(200);
  });

  it('gives the same 401 for a wrong password and an unknown user', async () => {
    const wrong = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '023 900 100', password: 'nope' });
    const unknown = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'nobody@example.com', password: 'nope' });
    expect(wrong.status).toBe(401);
    expect(unknown.status).toBe(401);
    expect(wrong.body).toEqual(unknown.body);
    expect(wrong.body.error.messageKey).toBe('errors.invalid_credentials');
  });

  it('rejects a missing body with 400 and limits login to 10 per minute', async () => {
    const bad = await request(app).post('/api/v1/auth/login').send({});
    expect(bad.status).toBe(400);
    let last = 0;
    for (let i = 0; i < 10; i++) {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'x@example.com', password: 'x' });
      last = res.status;
    }
    expect(last).toBe(429);
  });
});

describe('GET /auth/me', () => {
  it('returns the signed-in user and 401 without a token', async () => {
    const login = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '023 900 100', password: '123456' });
    const me = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${login.body.token}`);
    expect(me.status).toBe(200);
    expect(me.body).toEqual(login.body.user);

    expect((await request(app).get('/api/v1/auth/me')).status).toBe(401);
  });
});
