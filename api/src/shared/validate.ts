import type { RequestHandler } from 'express';
import type { z } from 'zod';
import { badRequest } from './errors';

type Schemas = { body?: z.ZodType; query?: z.ZodType; params?: z.ZodType };

export function validate(schemas: Schemas): RequestHandler {
  return (req, _res, next) => {
    for (const part of ['body', 'query', 'params'] as const) {
      const schema = schemas[part];
      if (!schema) continue;
      const result = schema.safeParse(req[part]);
      if (!result.success) return next(badRequest('validation_failed', 'errors.validation_failed'));
      // Express 5 makes req.query a getter, so redefine instead of assigning
      Object.defineProperty(req, part, {
        value: result.data,
        writable: true,
        enumerable: true,
        configurable: true,
      });
    }
    next();
  };
}
