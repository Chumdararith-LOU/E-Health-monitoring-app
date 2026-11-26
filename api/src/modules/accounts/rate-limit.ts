// Tiny in-memory rate limiter (per IP) for the auth routes. One instance per route, so each
// route counts on its own. Fine for a single-process API; counts reset on restart.

import type { RequestHandler } from 'express';
import { AppError } from '../../shared/errors';

type Hits = Map<string, { count: number; resetAt: number }>;

const limiters = new Set<Hits>();

export function rateLimit(options: { windowMs: number; max: number }): RequestHandler {
  const hits: Hits = new Map();
  limiters.add(hits);
  return (req, _res, next) => {
    const now = Date.now();
    const key = req.ip ?? 'unknown';
    let entry = hits.get(key);
    if (!entry || entry.resetAt <= now) {
      // clear out expired entries now and then so the map cannot grow forever
      if (hits.size > 10_000) {
        for (const [k, v] of hits) if (v.resetAt <= now) hits.delete(k);
      }
      entry = { count: 0, resetAt: now + options.windowMs };
      hits.set(key, entry);
    }
    entry.count += 1;
    if (entry.count > options.max) {
      return next(new AppError(429, 'too_many_requests', 'errors.too_many_requests'));
    }
    next();
  };
}

// For tests.
export function resetRateLimits(): void {
  for (const hits of limiters) hits.clear();
}
