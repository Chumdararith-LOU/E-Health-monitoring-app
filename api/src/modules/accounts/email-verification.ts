// Sending the "verify your email" code.

import type { Db } from '../../shared/db';
import { issueCode } from './codes';
import { sendMail } from './mail';
import { verifyEmailTemplate } from './mail-templates';

// Issues a code and emails it. Throws 429 (cooldown) or 502 (mail provider failed).
export async function sendVerificationCode(db: Db, user: { id: string; email: string }) {
  const code = issueCode(db, user.id, 'verify_email');
  await sendMail({ to: user.email, ...verifyEmailTemplate(code) });
}
