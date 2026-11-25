import { existsSync } from 'node:fs';
import { join } from 'node:path';
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

export function createApp(db: () => Db = getDb) {
  const app = express();
  app.disable('x-powered-by');
  app.locals.getDb = db;
  
  if (config.NODE_ENV === 'development') {
    app.use((req, res, next) => {
      const start = Date.now();
      res.on('finish', () => {
        const ms = Date.now() - start;
        console.log(`${req.method} ${req.originalUrl} → ${res.statusCode} (${ms} ms)`);
      });
      next();
    });
  }

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

  // Unknown API paths always return a structured JSON ApiError.
  app.use('/api', (_req, _res, next) => next(notFound()));

  // In single-container deployments, serve the built React web portal from WEB_DIST_DIR.
  const webDist = config.WEB_DIST_DIR;
  if (webDist && existsSync(join(webDist, 'index.html'))) {
    app.use(express.static(webDist));
    app.get('/', (_req, res) => res.sendFile(join(webDist, 'index.html')));
  }

  app.use((_req, _res, next) => next(notFound()));
  app.use(errorHandler);
  return app;
}
