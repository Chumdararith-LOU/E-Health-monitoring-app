import { Router } from 'express';
import { z } from 'zod';
import { requirePatientAccess } from '../../shared/access';
import { requireAuth } from '../../shared/auth';
import { validate } from '../../shared/validate';

export const reportsRouter = Router();

reportsRouter.get('/reports/ping', (_req, res) => {
  res.json({ module: 'reports', ok: true });
});

const summaryQuery = z.object({
  days: z.coerce.number().int().min(1).max(365).default(7),
});

reportsRouter.get(
  '/patients/:patientId/summary',
  requireAuth,
  requirePatientAccess(),
  validate({ query: summaryQuery }),
  (req, res) => {
    const { days } = req.query as unknown as z.infer<typeof summaryQuery>;
    res.json({ patientId: req.params.patientId, days, fields: [] });
  },
);