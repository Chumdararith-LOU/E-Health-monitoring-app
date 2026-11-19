import { Router } from 'express';

export const reportsRouter = Router();

reportsRouter.get('/reports/ping', (_req, res) => {
  res.json({ module: 'reports', ok: true });
});
