import { Router } from 'express';

export const router = Router();

router.get('/reports/ping', (_req, res) => {
  res.json({ module: 'reports', ok: true });
});
