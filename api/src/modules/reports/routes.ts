import { Router } from 'express';
import { z } from 'zod';
import { requirePatientAccess } from '../../shared/access';
import { requireAuth } from '../../shared/auth';
import { validate } from '../../shared/validate';
import { computeSeries } from './series';
import { computeSummary } from './summary';

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
    res.json(computeSummary({ patientId: req.params.patientId as string, days, readings: [] }));
  },
);

const seriesQuery = z.object({
  field: z.string().trim().min(1).max(64),
  days: z.coerce.number().int().min(1).max(365).default(7),
});

reportsRouter.get(
  '/patients/:patientId/series',
  requireAuth,
  requirePatientAccess(),
  validate({ query: seriesQuery }),
  (req, res) => {
    const { field, days } = req.query as unknown as z.infer<typeof seriesQuery>;
    res.json(
      computeSeries({
        patientId: req.params.patientId as string,
        fieldKey: field,
        days,
        readings: [],
      }),
    );
  },
);
