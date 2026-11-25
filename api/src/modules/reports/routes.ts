import { type Request, Router } from 'express';
import { z } from 'zod';
import { requirePatientAccess } from '../../shared/access';
import { requireAuth } from '../../shared/auth';
import { type Db, getDb } from '../../shared/db';
import { validate } from '../../shared/validate';
import { customFields, listReadings } from '../readings';
import { computeSeries } from './series';
import { computeSummary, type NormalRange } from './summary';

export const reportsRouter = Router();

const DAY_MS = 24 * 60 * 60 * 1000;
const isoDateRegex = /^\d{4}-\d{2}-\d{2}$/;

function dbOf(req: Request): Db {
  const getter = req.app.locals.getDb as (() => Db) | undefined;
  return (getter ?? getDb)();
}

function loadNormalRanges(db: Db): Record<string, NormalRange> {
  const rows = db
    .select({
      id: customFields.id,
      normalMin: customFields.normalMin,
      normalMax: customFields.normalMax,
    })
    .from(customFields)
    .all();

  const ranges: Record<string, NormalRange> = {};
  for (const row of rows) {
    if (row.normalMin != null || row.normalMax != null) {
      ranges[row.id] = {
        min: row.normalMin ?? undefined,
        max: row.normalMax ?? undefined,
      };
    }
  }
  return ranges;
}

function validCustomRange(q: { from?: string; to?: string }): boolean {
  if (!q.from && !q.to) return true;
  if (!q.from || !q.to) return false;
  const start = Date.parse(`${q.from}T00:00:00Z`);
  const end = Date.parse(`${q.to}T00:00:00Z`);
  if (Number.isNaN(start) || Number.isNaN(end) || start > end) return false;
  const spanDays = Math.floor((end - start) / DAY_MS) + 1;
  return spanDays >= 1 && spanDays <= 366;
}

reportsRouter.get('/reports/ping', (_req, res) => {
  res.json({ module: 'reports', ok: true });
});

const summaryQuery = z
  .object({
    days: z.coerce.number().int().min(1).max(365).default(7),
    from: z.string().regex(isoDateRegex).optional(),
    to: z.string().regex(isoDateRegex).optional(),
  })
  .refine(validCustomRange, { message: 'from and to must be valid YYYY-MM-DD dates with from <= to (max 366 days)' });

reportsRouter.get(
  '/patients/:patientId/summary',
  requireAuth,
  requirePatientAccess(),
  validate({ query: summaryQuery }),
  (req, res) => {
    const db = dbOf(req);
    const { days, from, to } = req.query as unknown as z.infer<typeof summaryQuery>;
    const patientId = req.params.patientId as string;
    const readings = listReadings(db, patientId);
    const ranges = loadNormalRanges(db);
    res.json(computeSummary({ patientId, days, from, to, readings, ranges }));
  },
);

const seriesQuery = z
  .object({
    field: z.string().trim().min(1).max(64),
    days: z.coerce.number().int().min(1).max(365).default(7),
    from: z.string().regex(isoDateRegex).optional(),
    to: z.string().regex(isoDateRegex).optional(),
  })
  .refine(validCustomRange, { message: 'from and to must be valid YYYY-MM-DD dates with from <= to (max 366 days)' });

reportsRouter.get(
  '/patients/:patientId/series',
  requireAuth,
  requirePatientAccess(),
  validate({ query: seriesQuery }),
  (req, res) => {
    const { field, days, from, to } = req.query as unknown as z.infer<typeof seriesQuery>;
    const patientId = req.params.patientId as string;
    const readings = listReadings(dbOf(req), patientId);
    res.json(
      computeSeries({
        patientId,
        fieldKey: field,
        days,
        from,
        to,
        readings,
      }),
    );
  },
);
