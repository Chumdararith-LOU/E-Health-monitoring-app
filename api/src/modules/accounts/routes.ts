// Accounts routes: register, sign in, "who am I", email verification and password reset (US-01, US-02).
// The public routes are rate limited; /auth/me runs requireAuth.

import type { AuthResponse, UserDto } from '@ehealth/types';
import { eq, sql } from 'drizzle-orm';
import { type Request, Router } from 'express';
import { z } from 'zod';
import { requireAuth, signToken } from '../../shared/auth';
import { type Db, getDb } from '../../shared/db';
import { AppError, badRequest, conflict, unauthorized } from '../../shared/errors';
import { validate } from '../../shared/validate';
import { consumeCode } from './codes';
import { sendVerificationCode } from './email-verification';
import { DUMMY_HASH, hashPassword, verifyPassword } from './password';
import { sendResetCode } from './password-reset';
import { rateLimit } from './rate-limit';
import { users } from './schema';

export const accountsRouter = Router();

function dbOf(req: Request): Db {
  const getter = req.app.locals.getDb as (() => Db) | undefined;
  return (getter ?? getDb)();
}

function toUserDto(row: typeof users.$inferSelect): UserDto {
  return {
    id: row.id,
    role: row.role,
    nameEn: row.nameEn,
    nameKm: row.nameKm,
    email: row.email,
    phone: row.phone,
    emailVerified: row.emailVerifiedAt !== null,
  };
}

async function toAuthResponse(row: typeof users.$inferSelect): Promise<AuthResponse> {
  const token = await signToken({ id: row.id, role: row.role, name: row.nameEn });
  return { token, user: toUserDto(row) };
}

// "012 345 678" and "012345678" are the same phone number.
const stripSpaces = (value: string) => value.replace(/[\s-]/g, '');

const samePhone = (phone: string) =>
  sql`replace(replace(${users.phone}, ' ', ''), '-', '') = ${stripSpaces(phone)}`;

const newPassword = z.string().min(8).max(200);

const registerBody = z
  .object({
    role: z.enum(['patient', 'caretaker', 'family', 'doctor']),
    nameEn: z.string().trim().min(1).max(100).optional(),
    nameKm: z.string().trim().min(1).max(100).optional(),
    email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
    phone: z
      .string()
      .trim()
      .regex(/^\+?[\d\s-]{8,16}$/)
      .optional(),
    password: newPassword,
    // Honeypot: hidden in the form, so real people leave it empty. Bots fill it in.
    website: z.string().max(0).optional(),
  })
  .refine((body) => body.nameEn || body.nameKm);

const loginBody = z.object({
  identifier: z.string().trim().min(1).max(254),
  password: z.string().min(1).max(200),
});

const confirmBody = z.object({
  code: z
    .string()
    .trim()
    .regex(/^\d{6}$/),
});

const forgotBody = z.object({ email: z.string().trim().toLowerCase().max(254).pipe(z.email()) });

const resetBody = z.object({
  email: z.string().trim().toLowerCase().max(254).pipe(z.email()),
  code: z
    .string()
    .trim()
    .regex(/^\d{6}$/),
  newPassword,
});

const changeBody = z.object({ currentPassword: z.string().min(1).max(200), newPassword });

const registerLimit = rateLimit({ windowMs: 60_000, max: 5 });
const loginLimit = rateLimit({ windowMs: 60_000, max: 10 });
const sendCodeLimit = rateLimit({ windowMs: 60_000, max: 5 });
const confirmLimit = rateLimit({ windowMs: 60_000, max: 10 });
const forgotLimit = rateLimit({ windowMs: 60_000, max: 5 });
const resetLimit = rateLimit({ windowMs: 60_000, max: 10 });
const changeLimit = rateLimit({ windowMs: 60_000, max: 10 });

accountsRouter.post(
  '/auth/register',
  registerLimit,
  validate({ body: registerBody }),
  async (req, res) => {
    const body: z.infer<typeof registerBody> = req.body;
    const db = dbOf(req);

    if (db.select({ id: users.id }).from(users).where(eq(users.email, body.email)).get()) {
      throw conflict('email_taken', 'errors.email_taken');
    }
    const phone = body.phone ? stripSpaces(body.phone) : null;
    if (phone && db.select({ id: users.id }).from(users).where(samePhone(phone)).get()) {
      throw conflict('phone_taken', 'errors.phone_taken');
    }

    const nameEn = body.nameEn ?? body.nameKm!;
    const nameKm = body.nameKm ?? body.nameEn!;
    const passwordHash = await hashPassword(body.password);
    const row = db
      .insert(users)
      .values({ role: body.role, nameEn, nameKm, email: body.email, phone, passwordHash })
      .returning()
      .get();

    // The account exists even if the email fails; the user can ask for a new code later.
    try {
      await sendVerificationCode(db, { id: row.id, email: body.email });
    } catch (err) {
      console.error('could not send the verification email', err);
    }
    res.status(201).json(await toAuthResponse(row));
  },
);

accountsRouter.post('/auth/login', loginLimit, validate({ body: loginBody }), async (req, res) => {
  const body: z.infer<typeof loginBody> = req.body;
  const db = dbOf(req);

  const where = body.identifier.includes('@')
    ? eq(users.email, body.identifier.toLowerCase())
    : samePhone(body.identifier);
  const row = db.select().from(users).where(where).get();

  // Same work and the same answer for "no such user" and "wrong password".
  const ok = await verifyPassword(body.password, row?.passwordHash ?? DUMMY_HASH);
  if (!row || !ok) throw unauthorized('invalid_credentials', 'errors.invalid_credentials');

  res.json(await toAuthResponse(row));
});

accountsRouter.get('/auth/me', requireAuth, (req, res) => {
  const row = dbOf(req).select().from(users).where(eq(users.id, req.user!.id)).get();
  if (!row) throw unauthorized();
  res.json(toUserDto(row));
});

accountsRouter.post('/auth/verify-email/send', requireAuth, sendCodeLimit, async (req, res) => {
  const db = dbOf(req);
  const row = db.select().from(users).where(eq(users.id, req.user!.id)).get();
  if (!row) throw unauthorized();
  if (!row.email) throw badRequest('no_email', 'errors.no_email');
  if (row.emailVerifiedAt) throw conflict('already_verified', 'errors.already_verified');

  await sendVerificationCode(db, { id: row.id, email: row.email });
  res.status(204).end();
});

accountsRouter.post(
  '/auth/verify-email/confirm',
  requireAuth,
  confirmLimit,
  validate({ body: confirmBody }),
  (req, res) => {
    const body: z.infer<typeof confirmBody> = req.body;
    const db = dbOf(req);
    const row = db.select().from(users).where(eq(users.id, req.user!.id)).get();
    if (!row) throw unauthorized();

    if (!consumeCode(db, row.id, 'verify_email', body.code)) {
      throw badRequest('invalid_code', 'errors.invalid_code');
    }
    const updated = db
      .update(users)
      .set({ emailVerifiedAt: new Date().toISOString() })
      .where(eq(users.id, row.id))
      .returning()
      .get();
    res.json(toUserDto(updated));
  },
);

// Always answers 204, whether or not the email has an account, so it cannot be used to find out
// who is registered. A cooldown or a mail failure is only logged for the same reason.
accountsRouter.post(
  '/auth/password/forgot',
  forgotLimit,
  validate({ body: forgotBody }),
  async (req, res) => {
    const body: z.infer<typeof forgotBody> = req.body;
    const db = dbOf(req);
    const row = db.select().from(users).where(eq(users.email, body.email)).get();
    if (row) {
      try {
        await sendResetCode(db, { id: row.id, email: body.email });
      } catch (err) {
        if (!(err instanceof AppError && err.code === 'code_cooldown')) {
          console.error('could not send the password reset email', err);
        }
      }
    }
    res.status(204).end();
  },
);

accountsRouter.post(
  '/auth/password/reset',
  resetLimit,
  validate({ body: resetBody }),
  async (req, res) => {
    const body: z.infer<typeof resetBody> = req.body;
    const db = dbOf(req);
    const row = db.select().from(users).where(eq(users.email, body.email)).get();

    // Unknown email and wrong code give the same answer.
    if (!row || !consumeCode(db, row.id, 'reset_password', body.code)) {
      throw badRequest('invalid_code', 'errors.invalid_code');
    }
    db.update(users)
      .set({
        passwordHash: await hashPassword(body.newPassword),
        // the code proves the person owns this inbox
        emailVerifiedAt: row.emailVerifiedAt ?? new Date().toISOString(),
      })
      .where(eq(users.id, row.id))
      .run();
    res.status(204).end();
  },
);

accountsRouter.post(
  '/auth/password/change',
  requireAuth,
  changeLimit,
  validate({ body: changeBody }),
  async (req, res) => {
    const body: z.infer<typeof changeBody> = req.body;
    const db = dbOf(req);
    const row = db.select().from(users).where(eq(users.id, req.user!.id)).get();
    if (!row) throw unauthorized();

    if (!(await verifyPassword(body.currentPassword, row.passwordHash))) {
      // 400, not 401: a 401 makes the apps sign the user out
      throw badRequest('invalid_password', 'errors.invalid_password');
    }
    db.update(users)
      .set({ passwordHash: await hashPassword(body.newPassword) })
      .where(eq(users.id, row.id))
      .run();
    res.status(204).end();
  },
);
