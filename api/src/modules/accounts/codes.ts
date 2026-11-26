// One-time email codes (6 digits) for verifying an email and, later, resetting a password.
// Only an HMAC of the code is stored. A code lasts 15 minutes, works once, and is burned after
// 5 wrong tries. Issuing a new code replaces the old one.

import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import { and, eq, isNull } from 'drizzle-orm';
import { config } from '../../config';
import type { Db } from '../../shared/db';
import { AppError } from '../../shared/errors';
import { authCodes } from './schema';

export type CodePurpose = (typeof authCodes.$inferSelect)['purpose'];

export const CODE_TTL_MS = 15 * 60_000;
export const MAX_ATTEMPTS = 5;
export const RESEND_COOLDOWN_MS = 60_000;

function hashCode(userId: string, purpose: CodePurpose, code: string): string {
  return createHmac('sha256', config.JWT_SECRET)
    .update(`${userId}:${purpose}:${code}`)
    .digest('hex');
}

const openCode = (userId: string, purpose: CodePurpose) =>
  and(eq(authCodes.userId, userId), eq(authCodes.purpose, purpose), isNull(authCodes.usedAt));

// Creates a new code and returns it in clear text (to be emailed). Throws 429 when the last
// code for this user and purpose was issued less than a minute ago.
export function issueCode(db: Db, userId: string, purpose: CodePurpose): string {
  const last = db.select().from(authCodes).where(openCode(userId, purpose)).get();
  if (last && Date.now() - Date.parse(last.createdAt) < RESEND_COOLDOWN_MS) {
    throw new AppError(429, 'code_cooldown', 'errors.code_cooldown');
  }
  const code = String(randomInt(0, 1_000_000)).padStart(6, '0');
  db.delete(authCodes).where(openCode(userId, purpose)).run();
  db.insert(authCodes)
    .values({
      userId,
      purpose,
      codeHash: hashCode(userId, purpose, code),
      expiresAt: new Date(Date.now() + CODE_TTL_MS).toISOString(),
    })
    .run();
  return code;
}

// True when the code is right (and uses it up). False for a wrong, expired, used or locked code.
export function consumeCode(db: Db, userId: string, purpose: CodePurpose, code: string): boolean {
  const row = db.select().from(authCodes).where(openCode(userId, purpose)).get();
  if (!row || row.attempts >= MAX_ATTEMPTS || Date.parse(row.expiresAt) <= Date.now()) return false;

  const given = Buffer.from(hashCode(userId, purpose, code), 'hex');
  const real = Buffer.from(row.codeHash, 'hex');
  if (!timingSafeEqual(given, real)) {
    db.update(authCodes)
      .set({ attempts: row.attempts + 1 })
      .where(eq(authCodes.id, row.id))
      .run();
    return false;
  }
  db.update(authCodes)
    .set({ usedAt: new Date().toISOString() })
    .where(eq(authCodes.id, row.id))
    .run();
  return true;
}
