import { and, eq } from 'drizzle-orm';
import { registerAccessChecker } from '../../shared/access';
import type { Db } from '../../shared/db';
import { patientLinks } from './schema';
import { seedAccounts } from './seed';

export { accountsRouter } from './routes';
export { doctorNotes, inviteCodes, patientLinks, users } from './schema';

export function startup(db: Db): void {
  registerAccessChecker(async (user, patientId) => {
    if (user.role === 'admin') return true;
    if (user.role === 'patient') return user.id === patientId;
    const row = db
      .select({ id: patientLinks.id })
      .from(patientLinks)
      .where(
        and(
          eq(patientLinks.patientId, patientId),
          eq(patientLinks.userId, user.id),
          eq(patientLinks.status, 'active'),
        ),
      )
      .get();
    return Boolean(row);
  });
}

export function seed(db: Db): void {
  seedAccounts(db);
}
