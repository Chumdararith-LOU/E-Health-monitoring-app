// Accounts routes: register, sign in, and "who am I" (US-01, US-02).
// The public routes are rate limited; /auth/me runs requireAuth.

import type { AuthResponse, UserDto } from '@ehealth/types';
import { eq, sql } from 'drizzle-orm';
import { type Request, Router } from 'express';
import { z } from 'zod';
import { requireAuth, signToken } from '../../shared/auth';
import { type Db, getDb } from '../../shared/db';
import { conflict, unauthorized } from '../../shared/errors';
import { validate } from '../../shared/validate';
import { DUMMY_HASH, hashPassword, verifyPassword } from './password';
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
    password: z.string().min(8).max(200),
    // Honeypot: hidden in the form, so real people leave it empty. Bots fill it in.
    website: z.string().max(0).optional(),
  })
  .refine((body) => body.nameEn || body.nameKm);

const loginBody = z.object({
  identifier: z.string().trim().min(1).max(254),
  password: z.string().min(1).max(200),
});

const registerLimit = rateLimit({ windowMs: 60_000, max: 5 });
const loginLimit = rateLimit({ windowMs: 60_000, max: 10 });

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
