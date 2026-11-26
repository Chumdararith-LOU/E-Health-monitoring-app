// Password hashing with node:crypto scrypt (no extra dependency).
// Stored format: scrypt$<saltHex>$<hashHex>

import { randomBytes, scrypt, scryptSync, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt) as (
  password: string,
  salt: Buffer,
  keylen: number,
) => Promise<Buffer>;

const KEY_LENGTH = 64;
const SALT_LENGTH = 16;

export function hashPasswordSync(password: string): string {
  const salt = randomBytes(SALT_LENGTH);
  const hash = scryptSync(password, salt, KEY_LENGTH);
  return `scrypt$${salt.toString('hex')}$${hash.toString('hex')}`;
}

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(SALT_LENGTH);
  const hash = await scryptAsync(password, salt, KEY_LENGTH);
  return `scrypt$${salt.toString('hex')}$${hash.toString('hex')}`;
}

// False for a wrong password and for any stored value that is not in the format above.
export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [scheme, saltHex, hashHex] = stored.split('$');
  if (scheme !== 'scrypt' || !saltHex || !hashHex) return false;
  const expected = Buffer.from(hashHex, 'hex');
  if (expected.length !== KEY_LENGTH) return false;
  const actual = await scryptAsync(password, Buffer.from(saltHex, 'hex'), KEY_LENGTH);
  return timingSafeEqual(actual, expected);
}

// A real hash nobody knows the password of. Checked when the user is unknown, so a missing
// account takes as long to answer as a wrong password.
export const DUMMY_HASH = hashPasswordSync(randomBytes(16).toString('hex'));
