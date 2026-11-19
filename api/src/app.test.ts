import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';
import { createApp } from './app';
import { createDb } from './shared/db';

// The app's database is in-memory here (see vitest.config.ts)
const app = createApp();

describe('app', () => {
  it('GET /api/v1/health returns 200', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, name: 'ehealth-api', env: 'test', db: 'ok' });
  });

  it('GET /api/v1/health returns 503 when the database fails', async () => {
    const closed = createDb(':memory:');
    closed.$client.close();
    const errorLog = vi.spyOn(console, 'error').mockImplementation(() => {});
    const res = await request(createApp(() => closed)).get('/api/v1/health');
    errorLog.mockRestore();
    expect(res.status).toBe(503);
    expect(res.body).toEqual({
      error: { code: 'db_unavailable', messageKey: 'errors.db_unavailable' },
    });
  });

  it('GET /api/v1/reports/ping returns 200', async () => {
    const res = await request(app).get('/api/v1/reports/ping');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ module: 'reports', ok: true });
  });

  it('unknown route returns 404 in the ApiError shape', async () => {
    const res = await request(app).get('/api/v1/nope');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'not_found', messageKey: 'errors.not_found' } });
  });
});
