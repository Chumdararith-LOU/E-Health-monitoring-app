import { Router } from 'express';

export const router = Router();

router.get('/readings/ping', (_req, res) => {
  res.json({ module: 'readings', ok: true });
});
