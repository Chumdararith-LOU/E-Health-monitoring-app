import { ROLES } from '@ehealth/types';
import { Router } from 'express';
import { z } from 'zod';
import { requireAuth, signToken } from '../auth';
import { notFound } from '../errors';
import { validate } from '../validate';
import { devUsers } from './dev-users';

// Passwordless login for development. app.ts mounts this only when config.DEV_LOGIN is true.
export const devRouter = Router();

const loginBody = z.union([z.object({ role: z.enum(ROLES) }), z.object({ userId: z.string() })]);

devRouter.get('/dev/users', (_req, res) => {
  res.json(Object.values(devUsers));
});

devRouter.post('/dev/login', validate({ body: loginBody }), async (req, res) => {
  const body: z.infer<typeof loginBody> = req.body;
  const user =
    'role' in body
      ? devUsers[body.role]
      : Object.values(devUsers).find((u) => u.id === body.userId);
  if (!user) throw notFound();
  res.json({ token: await signToken(user), user });
});

devRouter.get('/dev/whoami', requireAuth, (req, res) => {
  res.json(req.user);
});
