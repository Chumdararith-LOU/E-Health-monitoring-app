import { type Request, Router } from 'express';
import { z } from 'zod';
import { requirePatientAccess } from '../../shared/access';
import { requireAuth } from '../../shared/auth';
import { type Db, getDb } from '../../shared/db';
import { validate } from '../../shared/validate';
import { listReadings } from '../readings';
import { computeSeries } from './series';
import { computeSummary } from './summary';

export const reportsRouter = Router();

function dbOf(req: Request): Db {
  const getter = req.app.locals.getDb as (() => Db) | undefined;
  return (getter ?? getDb)();
}

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
    const patientId = req.params.patientId as string;
    const readings = listReadings(dbOf(req), patientId);
    res.json(computeSummary({ patientId, days, readings }));
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
    const patientId = req.params.patientId as string;
    const readings = listReadings(dbOf(req), patientId);
    res.json(
      computeSeries({
        patientId,
        fieldKey: field,
        days,
        readings,
      }),
    );
  },
);
