import { Router } from 'express';

export const router = Router();

router.get('/accounts/ping', (_req, res) => {
  res.json({ module: 'accounts', ok: true });
});
