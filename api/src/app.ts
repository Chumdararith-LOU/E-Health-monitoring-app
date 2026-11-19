import type { ApiError } from '@ehealth/types';
import cors from 'cors';
import express, { type ErrorRequestHandler } from 'express';
import { config } from './config';
import { moduleRouters } from './modules';
import { notFound, toAppError } from './shared/errors';

const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  const appError = toAppError(err);
  if (appError.status >= 500) console.error(err);
  const body: ApiError = { error: { code: appError.code, messageKey: appError.messageKey } };
  res.status(appError.status).json(body);
};

export function createApp() {
  const app = express();
  app.use(cors({ origin: config.CORS_ORIGIN }));
  app.use(express.json());

  app.get('/api/v1/health', (_req, res) => {
    res.json({ ok: true, name: 'ehealth-api', env: config.NODE_ENV });
  });
  for (const router of moduleRouters) app.use('/api/v1', router);

  app.use((_req, _res, next) => next(notFound()));
  app.use(errorHandler);
  return app;
}
