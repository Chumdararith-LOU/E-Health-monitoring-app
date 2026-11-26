import { eq } from 'drizzle-orm';
import request from 'supertest';
import { afterAll, beforeAll, beforeEach, describe, expect, it } from 'vitest';
import { createApp } from '../../app';
import { verifyToken } from '../../shared/auth';
import { createDb, type Db, runMigrations } from '../../shared/db';
import { runSeeds, runStartups } from '../index';
import { sentMail } from './mail';
import { hashPassword, verifyPassword } from './password';
import { resetRateLimits } from './rate-limit';
import { authCodes, users } from './schema';

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

// ---- Email verification (US-01) ----

const lastCodeFor = (email: string): string => {
  const mail = [...sentMail].reverse().find((m) => m.to === email);
  const code = mail?.text.match(/^\d{6}$/m)?.[0];
  if (!code) throw new Error(`no code mailed to ${email}`);
  return code;
};

// Pretend the last code was issued 2 minutes ago, so the 1-minute cooldown is over.
const skipCooldown = () =>
  db
    .update(authCodes)
    .set({ createdAt: new Date(Date.now() - 120_000).toISOString() })
    .run();

async function registerFresh(email: string) {
  const res = await request(app)
    .post('/api/v1/auth/register')
    .send({ role: 'patient', nameEn: 'Verify Me', email, password: 'correct-horse' });
  expect(res.status).toBe(201);
  return { token: `Bearer ${res.body.token as string}`, user: res.body.user };
}

describe('email verification', () => {
  it('seeded demo users are verified, new users are not', async () => {
    const demo = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '023 900 100', password: '123456' });
    expect(demo.body.user.emailVerified).toBe(true);

    const { user } = await registerFresh('new1@example.com');
    expect(user.emailVerified).toBe(false);
  });

  it('register mails a bilingual 6-digit code, and confirm verifies the email', async () => {
    const { token } = await registerFresh('new2@example.com');
    const mail = [...sentMail].reverse().find((m) => m.to === 'new2@example.com');
    expect(mail?.subject).toContain('Verify your email');
    expect(mail?.text).toContain('កូដ');

    const res = await request(app)
      .post('/api/v1/auth/verify-email/confirm')
      .set('Authorization', token)
      .send({ code: lastCodeFor('new2@example.com') });
    expect(res.status).toBe(200);
    expect(res.body.emailVerified).toBe(true);

    const me = await request(app).get('/api/v1/auth/me').set('Authorization', token);
    expect(me.body.emailVerified).toBe(true);
  });

  it('only stores a hash of the code, and a code works once', async () => {
    const { token } = await registerFresh('new3@example.com');
    const code = lastCodeFor('new3@example.com');
    const stored = db.select().from(authCodes).all();
    expect(stored.some((row) => row.codeHash.includes(code))).toBe(false);

    const send = () =>
      request(app)
        .post('/api/v1/auth/verify-email/confirm')
        .set('Authorization', token)
        .send({ code });
    expect((await send()).status).toBe(200);
    const again = await send();
    expect(again.status).toBe(400);
    expect(again.body.error.code).toBe('invalid_code');
  });

  it('rejects a wrong code, a badly formed code, and locks the code after 5 wrong tries', async () => {
    const { token } = await registerFresh('new4@example.com');
    const good = lastCodeFor('new4@example.com');
    const wrong = good === '000000' ? '111111' : '000000';
    const confirm = (code: string) =>
      request(app)
        .post('/api/v1/auth/verify-email/confirm')
        .set('Authorization', token)
        .send({ code });

    expect((await confirm('12ab')).status).toBe(400);
    for (let i = 0; i < 5; i++) {
      const res = await confirm(wrong);
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe('invalid_code');
    }
    // locked: even the right code fails now
    expect((await confirm(good)).status).toBe(400);

    // a new code unlocks it
    skipCooldown();
    expect(
      (await request(app).post('/api/v1/auth/verify-email/send').set('Authorization', token))
        .status,
    ).toBe(204);
    expect((await confirm(lastCodeFor('new4@example.com'))).status).toBe(200);
  });

  it('rejects an expired code', async () => {
    const { token } = await registerFresh('new5@example.com');
    const code = lastCodeFor('new5@example.com');
    db.update(authCodes)
      .set({ expiresAt: new Date(Date.now() - 1000).toISOString() })
      .run();
    const res = await request(app)
      .post('/api/v1/auth/verify-email/confirm')
      .set('Authorization', token)
      .send({ code });
    expect(res.status).toBe(400);
  });

  it('send: needs a token, has a 1-minute cooldown, and a new code replaces the old one', async () => {
    expect((await request(app).post('/api/v1/auth/verify-email/send')).status).toBe(401);

    const { token } = await registerFresh('new6@example.com');
    const first = lastCodeFor('new6@example.com');

    const tooSoon = await request(app)
      .post('/api/v1/auth/verify-email/send')
      .set('Authorization', token);
    expect(tooSoon.status).toBe(429);
    expect(tooSoon.body.error.code).toBe('code_cooldown');

    skipCooldown();
    const sendAgain = await request(app)
      .post('/api/v1/auth/verify-email/send')
      .set('Authorization', token);
    expect(sendAgain.status).toBe(204);
    const second = lastCodeFor('new6@example.com');

    if (first !== second) {
      const old = await request(app)
        .post('/api/v1/auth/verify-email/confirm')
        .set('Authorization', token)
        .send({ code: first });
      expect(old.status).toBe(400);
    }
    const ok = await request(app)
      .post('/api/v1/auth/verify-email/confirm')
      .set('Authorization', token)
      .send({ code: second });
    expect(ok.status).toBe(200);
  });

  it('send: 409 when already verified, 400 when the account has no email', async () => {
    const demo = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'admin@ehealth.kh', password: '123456' });
    const verified = await request(app)
      .post('/api/v1/auth/verify-email/send')
      .set('Authorization', `Bearer ${demo.body.token}`);
    expect(verified.status).toBe(409);
    expect(verified.body.error.code).toBe('already_verified');

    // seeded doctor has a phone but no email
    const doctor = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: '023 900 100', password: '123456' });
    db.update(users).set({ emailVerifiedAt: null }).where(eq(users.id, 'd1')).run();
    const noEmail = await request(app)
      .post('/api/v1/auth/verify-email/send')
      .set('Authorization', `Bearer ${doctor.body.token}`);
    expect(noEmail.status).toBe(400);
    expect(noEmail.body.error.code).toBe('no_email');
  });
});

// ---- Password reset and change ----

const mailsTo = (email: string) => sentMail.filter((m) => m.to === email);

const forgot = (email: string) => request(app).post('/api/v1/auth/password/forgot').send({ email });

const reset = (body: object) => request(app).post('/api/v1/auth/password/reset').send(body);

const login = (identifier: string, password: string) =>
  request(app).post('/api/v1/auth/login').send({ identifier, password });

describe('password reset', () => {
  it('forgot answers 204 for an unknown email and sends nothing', async () => {
    const res = await forgot('ghost@example.com');
    expect(res.status).toBe(204);
    expect(mailsTo('ghost@example.com')).toHaveLength(0);
  });

  it('forgot mails a bilingual code, reset changes the password, and the old one stops working', async () => {
    await registerFresh('reset1@example.com');
    expect((await forgot('Reset1@Example.com')).status).toBe(204);
    const mail = mailsTo('reset1@example.com').at(-1);
    expect(mail?.subject).toContain('Reset your password');

    const done = await reset({
      email: 'reset1@example.com',
      code: lastCodeFor('reset1@example.com'),
      newPassword: 'brand-new-pass',
    });
    expect(done.status).toBe(204);

    expect((await login('reset1@example.com', 'brand-new-pass')).status).toBe(200);
    expect((await login('reset1@example.com', 'correct-horse')).status).toBe(401);
  });

  it('a reset code works once, and a good reset also verifies the email', async () => {
    await registerFresh('reset2@example.com');
    await forgot('reset2@example.com');
    const code = lastCodeFor('reset2@example.com');
    const body = { email: 'reset2@example.com', code, newPassword: 'brand-new-pass' };

    expect((await reset(body)).status).toBe(204);
    const again = await reset({ ...body, newPassword: 'another-pass-1' });
    expect(again.status).toBe(400);
    expect(again.body.error.code).toBe('invalid_code');

    const user = (await login('reset2@example.com', 'brand-new-pass')).body.user;
    expect(user.emailVerified).toBe(true);
  });

  it('gives the same answer for an unknown email and a wrong code', async () => {
    await registerFresh('reset3@example.com');
    await forgot('reset3@example.com');
    const wrong = await reset({
      email: 'reset3@example.com',
      code: '000000' === lastCodeFor('reset3@example.com') ? '111111' : '000000',
      newPassword: 'brand-new-pass',
    });
    const unknown = await reset({
      email: 'ghost@example.com',
      code: '123456',
      newPassword: 'brand-new-pass',
    });
    expect(wrong.status).toBe(400);
    expect(wrong.body).toEqual(unknown.body);
    // the password did not change
    expect((await login('reset3@example.com', 'correct-horse')).status).toBe(200);
  });

  it('locks the code after 5 wrong tries, and a new code unlocks it', async () => {
    await registerFresh('reset4@example.com');
    await forgot('reset4@example.com');
    const good = lastCodeFor('reset4@example.com');
    const wrong = good === '000000' ? '111111' : '000000';
    const body = { email: 'reset4@example.com', newPassword: 'brand-new-pass' };

    for (let i = 0; i < 5; i++) expect((await reset({ ...body, code: wrong })).status).toBe(400);
    expect((await reset({ ...body, code: good })).status).toBe(400);

    skipCooldown();
    await forgot('reset4@example.com');
    expect((await reset({ ...body, code: lastCodeFor('reset4@example.com') })).status).toBe(204);
  });

  it('rejects an expired code and a weak new password', async () => {
    await registerFresh('reset5@example.com');
    await forgot('reset5@example.com');
    const code = lastCodeFor('reset5@example.com');
    const body = { email: 'reset5@example.com', code, newPassword: 'short' };
    expect((await reset(body)).status).toBe(400); // validation, code is not used up

    db.update(authCodes)
      .set({ expiresAt: new Date(Date.now() - 1000).toISOString() })
      .run();
    const expired = await reset({ ...body, newPassword: 'long-enough-1' });
    expect(expired.status).toBe(400);
    expect(expired.body.error.code).toBe('invalid_code');
  });

  it('keeps verify and reset codes apart', async () => {
    const { token } = await registerFresh('reset6@example.com');
    const verifyCode = lastCodeFor('reset6@example.com');

    // a verify code cannot reset the password
    const asReset = await reset({
      email: 'reset6@example.com',
      code: verifyCode,
      newPassword: 'brand-new-pass',
    });
    expect(asReset.status).toBe(400);

    // and asking for a reset code does not replace the verify code
    await forgot('reset6@example.com');
    const confirm = await request(app)
      .post('/api/v1/auth/verify-email/confirm')
      .set('Authorization', token)
      .send({ code: verifyCode });
    expect(confirm.status).toBe(200);
  });

  it('forgot is quiet during the cooldown: still 204, no second email', async () => {
    await registerFresh('reset7@example.com');
    await forgot('reset7@example.com');
    const before = mailsTo('reset7@example.com').length;
    expect((await forgot('reset7@example.com')).status).toBe(204);
    expect(mailsTo('reset7@example.com')).toHaveLength(before);
  });

  it('limits forgot to 5 per minute and rejects a bad email with 400', async () => {
    expect((await forgot('not-an-email')).status).toBe(400);
    let last = 0;
    for (let i = 0; i < 6; i++) last = (await forgot('ghost@example.com')).status;
    expect(last).toBe(429);
  });
});

describe('POST /auth/password/change', () => {
  it('needs a token, checks the current password, and sets the new one', async () => {
    const { token } = await registerFresh('change1@example.com');
    const change = (body: object, auth: string | null = token) => {
      const req = request(app).post('/api/v1/auth/password/change');
      return (auth ? req.set('Authorization', auth) : req).send(body);
    };

    expect((await change({ currentPassword: 'x', newPassword: 'whatever-123' }, null)).status).toBe(
      401,
    );

    const wrong = await change({ currentPassword: 'wrong-pass', newPassword: 'whatever-123' });
    expect(wrong.status).toBe(400);
    expect(wrong.body.error.code).toBe('invalid_password');

    expect((await change({ currentPassword: 'correct-horse', newPassword: 'short' })).status).toBe(
      400,
    );

    const ok = await change({ currentPassword: 'correct-horse', newPassword: 'whatever-123' });
    expect(ok.status).toBe(204);
    expect((await login('change1@example.com', 'whatever-123')).status).toBe(200);
    expect((await login('change1@example.com', 'correct-horse')).status).toBe(401);
  });
});
