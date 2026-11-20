import type { ApiError } from '@ehealth/types';
import cors from 'cors';
import express, { type ErrorRequestHandler } from 'express';
import { sql } from 'drizzle-orm';
import { config } from './config';
import { moduleRouters } from './modules';
import { type Db, getDb } from './shared/db';
import { devRouter } from './shared/dev/routes';
import { AppError, notFound, toAppError } from './shared/errors';

export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  const appError = toAppError(err);
  if (appError.status >= 500) console.error(err);
  const body: ApiError = { error: { code: appError.code, messageKey: appError.messageKey } };
  res.status(appError.status).json(body);
};

// db defaults to the app's shared database; tests can pass their own.
export function createApp(db: () => Db = getDb) {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors({ origin: config.CORS_ORIGIN }));
  app.use(express.json());

  app.get('/api/v1/health', (_req, res) => {
    try {
      db().get(sql`select 1`);
    } catch (cause) {
      throw new AppError(503, 'db_unavailable', 'errors.db_unavailable', { cause });
    }
    res.json({ ok: true, name: 'ehealth-api', env: config.NODE_ENV, db: 'ok' });
  });
  if (config.DEV_LOGIN) app.use('/api/v1', devRouter);
  for (const router of moduleRouters) app.use('/api/v1', router);

  app.use((_req, _res, next) => next(notFound()));
  app.use(errorHandler);
  return app;
}
