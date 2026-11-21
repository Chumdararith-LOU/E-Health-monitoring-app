import type { AuthUser } from '@ehealth/types';
import type { RequestHandler } from 'express';
import { forbidden, unauthorized } from './errors';

export type AccessChecker = (user: AuthUser, patientId: string) => Promise<boolean>;

let checker: AccessChecker | undefined;

// Called by the accounts module from its startup hook to plug in the real rule.
export function registerAccessChecker(fn: AccessChecker): void {
  checker = fn;
}

export async function canView(user: AuthUser, patientId: string): Promise<boolean> {
  if (checker) return checker(user, patientId);
  if (user.role === 'patient') return user.id === patientId;
  if (user.role === 'admin') return true;
  // TODO(Phayuk): replace via registerAccessChecker with the real links check
  return true;
}

// Use after requireAuth.
export const requirePatientAccess =
  (paramName = 'patientId'): RequestHandler =>
  async (req, _res, next) => {
    if (!req.user) return next(unauthorized());
    const patientId = req.params[paramName];
    next(
      typeof patientId === 'string' && (await canView(req.user, patientId))
        ? undefined
        : forbidden(),
    );
  };
