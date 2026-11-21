import { type AuthUser, ROLES, type Role } from '@ehealth/types';
import type { RequestHandler } from 'express';
import { SignJWT, jwtVerify } from 'jose';
import { z } from 'zod';
import { config } from '../config';
import { forbidden, unauthorized } from './errors';

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser; // set by requireAuth
    }
  }
}

const secret = new TextEncoder().encode(config.JWT_SECRET);
const claims = z.object({ sub: z.string(), role: z.enum(ROLES), name: z.string() });

export function signToken(user: AuthUser): Promise<string> {
  return new SignJWT({ role: user.role, name: user.name })
    .setProtectedHeader({ alg: 'HS256' })
    .setSubject(user.id)
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(secret);
}

// Throws a 401 AppError for a bad, expired or malformed token.
export async function verifyToken(token: string): Promise<AuthUser> {
  try {
    const { payload } = await jwtVerify(token, secret, { algorithms: ['HS256'] });
    const { sub, role, name } = claims.parse(payload);
    return { id: sub, role, name };
  } catch {
    throw unauthorized();
  }
}

export const requireAuth: RequestHandler = async (req, _res, next) => {
  const token = req.headers.authorization?.match(/^Bearer (.+)$/i)?.[1];
  if (!token) return next(unauthorized());
  req.user = await verifyToken(token);
  next();
};

// Use after requireAuth.
export const requireRole =
  (...roles: Role[]): RequestHandler =>
  (req, _res, next) => {
    if (!req.user) return next(unauthorized());
    next(roles.includes(req.user.role) ? undefined : forbidden());
  };
